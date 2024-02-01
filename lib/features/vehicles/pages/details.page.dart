import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:vehiloc/core/model/response_daily_vehicle.dart';
import 'package:vehiloc/core/utils/conts.dart';
import 'package:vehiloc/features/vehicles/api/api_service.dart';

class DetailsPageView extends StatefulWidget {
  final int vehicleId;
  final double? vehicleLat;
  final double? vehicleLon;

  DetailsPageView({
    required this.vehicleId,
    required this.vehicleLat,
    required this.vehicleLon,
  });

  @override
  _DetailsPageViewState createState() => _DetailsPageViewState();
}

class _DetailsPageViewState extends State<DetailsPageView> {
  final ApiService apiService = ApiService();

  late double _initialLat;
  late double _initialLon;

  late DateTime _selectedDate;
  double _sliderValue = 100.0;

  late BitmapDescriptor _greenMarkerIcon;
  late BitmapDescriptor _redMarkerIcon;
  bool _isMarkerIconsSet = false;

  List<Daily> dailyData = [];
  late GoogleMapController _mapController; 

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    setMarkerIcons();
    _initialLat = widget.vehicleLat ?? 0.0;
    _initialLon = widget.vehicleLon ?? 0.0;
    fetchData();
  }

  void fetchData() async {
    final int vehicleId = widget.vehicleId;
    final int startEpoch = 1706745600;

    try {
      final List<Daily> data = await apiService.fetchDailyHistory(
        vehicleId,
        startEpoch,
      );

      setState(() {
        dailyData = data;
      });
    } catch (e) {
      print("error : $e");
    }
  }

  void setMarkerIcons() async {
    final Uint8List greenMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_green.png', 40);
    final Uint8List redMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_red.png', 40);

    setState(() {
      _greenMarkerIcon = BitmapDescriptor.fromBytes(greenMarkerIconData);
      _redMarkerIcon = BitmapDescriptor.fromBytes(redMarkerIconData);
      _isMarkerIconsSet = true;
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Set<Polyline> _createPolylines() {
    if (dailyData.isEmpty) {
      return Set();
    }

    final List<LatLng> polylineCoordinates = dailyData
        .map((daily) => LatLng(daily.latitude!, daily.longitude!))
        .toList();

    final PolylineId polylineId = PolylineId('${widget.vehicleId}');
    final Polyline polyline = Polyline(
      polylineId: polylineId,
      color: Colors.red,
      points: polylineCoordinates,
      width: 1,
    );

    return Set.of([polyline]);
  }

  Set<Marker> _createMarkers(double sliderValue) {
    if (dailyData.isEmpty) {
      return Set();
    }

    int index = (sliderValue * dailyData.length / 100).round();
    if (index >= dailyData.length) index = dailyData.length - 1;

    final Daily currentDaily = dailyData[index];

    final Set<Marker> markers = {
      Marker(
        markerId: MarkerId("${widget.vehicleId}"),
        position: LatLng(currentDaily.latitude!, currentDaily.longitude!),
        rotation: currentDaily.bearing?.toDouble() ?? 0.0,
        icon: currentDaily.speed == 0 ? _redMarkerIcon : _greenMarkerIcon,
      ),
    };

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Kendaraan',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: GlobalColor.textColor,
            ),
          ),
        ),
        backgroundColor: GlobalColor.mainColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate =
                            _selectedDate.subtract(Duration(days: 1));
                      });
                    },
                    icon: Icon(Icons.arrow_back),
                  ),
                  TextButton(
                    onPressed: () {
                      _selectDate(context);
                    },
                    child: Text(
                      '${_selectedDate.day} ${DateFormat.MMMM().format(_selectedDate)}, ${_selectedDate.year}',
                      style: GoogleFonts.poppins(fontSize: 16), // Apply Work Sans font here
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(Duration(days: 1));
                      });
                    },
                    icon: Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(Icons.speed),
                    Text('Kecepatan', style: GoogleFonts.poppins()), // Apply Work Sans font here
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.directions),
                    Text('Jarak', style: GoogleFonts.poppins()), // Apply Work Sans font here
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.directions),
                    Text('Jarak', style: GoogleFonts.poppins()), // Apply Work Sans font here
                  ],
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Builder(
                builder: (context) {
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_initialLat, _initialLon),
                      zoom: 11,
                    ),
                    markers: _createMarkers(_sliderValue),
                    polylines: _createPolylines(),
                    onMapCreated: (controller) {
                      setState(() {
                        _mapController = controller;
                      });
                    },
                  );
                },
              ),
            ),
            SizedBox(
              height: 100,
              child: Slider(
                value: _sliderValue,
                min: 0,
                max: 100,
                onChanged: (newValue) {
                  setState(() {
                    _sliderValue = newValue;
                    _updateCameraPosition(newValue);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCameraPosition(double sliderValue) {
    if (dailyData.isEmpty || _mapController == null) {
      return;
    }

    int index = (sliderValue * dailyData.length / 100).round();
    if (index >= dailyData.length) index = dailyData.length - 1;

    final Daily currentDaily = dailyData[index];
    _mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(currentDaily.latitude!, currentDaily.longitude!),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }
}

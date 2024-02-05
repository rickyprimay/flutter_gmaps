import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:vehiloc/core/model/test.dart';
import 'package:vehiloc/core/utils/conts.dart';
import 'package:vehiloc/features/vehicles/api/api_service.dart';
import 'package:fl_chart/fl_chart.dart';

class DetailsPageView extends StatefulWidget {
  final int vehicleId;
  final double? vehicleLat;
  final double? vehicleLon;
  final String? vehicleName;
  final int gpsdt;

  const DetailsPageView({
    super.key,
    required this.vehicleId,
    required this.vehicleLat,
    required this.vehicleLon,
    required this.vehicleName,
    required this.gpsdt,
  });

  @override
  _DetailsPageViewState createState() => _DetailsPageViewState();
}

class _DetailsPageViewState extends State<DetailsPageView> {
  final ApiService apiService = ApiService();

  late LatLng _initialCameraPosition;

  late DateTime _selectedDate;
  double _sliderValue = 0.0;

  late BitmapDescriptor _greenMarkerIcon;
  late BitmapDescriptor _redMarkerIcon;
  bool _isMarkerIconsSet = false;
  bool _isButtonClicked = false;

  List<Data> allData = [];
  List<DataItem> dailyData = [];
  List<InputLogsItem> inputData = [];
  List<JdetailsItem> detailsItem = [];

  late GoogleMapController _mapController;

  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialCameraPosition =
        LatLng(widget.vehicleLat ?? 0.0, widget.vehicleLon ?? 0.0);

    DateTime gpsdtUtc = DateTime.fromMillisecondsSinceEpoch(
      widget.gpsdt * 1000,
      isUtc: true,
    );
    DateTime gpsdtWIB = gpsdtUtc.add(Duration(hours: 7));
    _selectedDate = DateTime(gpsdtWIB.year, gpsdtWIB.month, gpsdtWIB.day);

    setMarkerIcons();
    fetchAllData();
  }

  void fetchAllData() async {
    final int vehicleId = widget.vehicleId;
    final int startEpoch = widget.gpsdt;

    try {
      final Data dataAll =
          await apiService.fetchDataFromApi(vehicleId, startEpoch);

      setState(() {
        allData = [dataAll];
        dailyData = allData.isNotEmpty ? allData[0].data : [];
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
        .map((daily) => LatLng(daily.latitude, daily.longitude))
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

    final DataItem currentDaily = dailyData[index];

    final Set<Marker> markers = {
      Marker(
          markerId: MarkerId("${widget.vehicleId}"),
          position: LatLng(currentDaily.latitude, currentDaily.longitude),
          rotation: currentDaily.bearing.toDouble(),
          icon: currentDaily.speed == 0 ? _redMarkerIcon : _greenMarkerIcon,
          infoWindow: InfoWindow(
            title: "${widget.vehicleName}",
          ))
    };

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    JdetailsItem? jDetails;

    if (allData.isNotEmpty && allData[0].jdetails.length > 1) {
      jDetails = allData[0].jdetails[1];
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.vehicleName}",
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
                        _updateStartEpoch();
                      });
                    },
                    icon: Icon(Icons.arrow_back),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _isButtonClicked
                          ? Colors.blue[800]?.withOpacity(0.8)
                          : Colors.blue[400]?.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _isButtonClicked = !_isButtonClicked;
                        });
                        _selectDate(context);
                      },
                      child: Text(
                        '${_selectedDate.day} ${DateFormat.MMMM().format(_selectedDate)}, ${_selectedDate.year}',
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(Duration(days: 1));
                        _updateStartEpoch();
                      });
                    },
                    icon: Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.black, width: 1.0),
                    ),
                    child: Text('Map'),
                  ),
                ),
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.black, width: 1.0),
                    ),
                    child: Text('Narasi'),
                  ),
                ),
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 2;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.black, width: 1.0),
                    ),
                    child: Text('Event'),
                  ),
                ),
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 3;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.black, width: 1.0),
                    ),
                    child: Text('Grafik'),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.52,
              child: Builder(
                builder: (context) {
                  return _selectedTabIndex == 0
                      ? _buildMapWidget()
                      : _selectedTabIndex == 1
                          ? _buildNarasiWidget()
                          : _selectedTabIndex == 2
                              ? _buildEventWidget()
                              : _buildChartWidget();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWidget() {
    return Column(
      children: [
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialCameraPosition,
              zoom: 9,
            ),
            markers: _createMarkers(_sliderValue),
            polylines: _createPolylines(),
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
            },
          ),
        ),
        SizedBox(
          height: 100,
          child: Container(
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
              activeColor: Colors.black,
              inactiveColor: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarasiWidget() {
    return Column(
      children: [
        Text('Narasi'),
      ],
    );
  }

  Widget _buildEventWidget() {
    return Column(
      children: [
        Text('Event'),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Panggil fungsi fetchAllData saat tombol ditekan
            fetchAllData();
          },
          child: Text('Test Response'),
        ),
      ],
    );
  }

  Widget _buildChartWidget() {
    // Generate dummy data for demonstration
    List<int> dummySpeedData = [43, 72, 65, 88, 50, 90, 75, 40, 60, 85];
    List<String> hours = [
      '01:00',
      '02:00',
      '03:00',
      '04:00',
      '05:00',
      '06:00',
      '07:00',
      '08:00',
      '09:00',
      '10:00'
    ]; // Add more hours as needed

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: SideTitles(showTitles: true, interval: 20),
            bottomTitles: SideTitles(
              showTitles: true,
              getTitles: (value) {
                int index = value.toInt();
                if (index >= 0 && index < hours.length) {
                  return hours[index];
                }
                return '';
              },
              margin: 8,
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: dummySpeedData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.toDouble());
              }).toList(),
              isCurved: true,
              colors: [Colors.blue],
              barWidth: 4,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCameraPosition(double sliderValue) {
    if (dailyData.isEmpty) {
      return;
    }

    int index = (sliderValue * dailyData.length / 100).round();
    if (index >= dailyData.length) index = dailyData.length - 1;

    final DataItem currentDaily = dailyData[index];
    _mapController.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(currentDaily.latitude, currentDaily.longitude),
      ),
    );
  }

  void _updateStartEpoch() async {
    final int vehicleId = widget.vehicleId;
    final DateTime selectedDateUtc = _selectedDate.toUtc();
    final int startEpoch = selectedDateUtc.millisecondsSinceEpoch ~/ 1000;

    try {
      final Data dataAll =
          await apiService.fetchDataFromApi(vehicleId, startEpoch);

      setState(() {
        allData = [dataAll];
        dailyData = allData.isNotEmpty ? allData[0].data : [];
      });
    } catch (e) {
      print("error : $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      DateTime gpsdtUtc = DateTime.fromMillisecondsSinceEpoch(
        widget.gpsdt * 1000,
        isUtc: true,
      );
      DateTime gpsdtWIB = gpsdtUtc.add(Duration(hours: 7));
      DateTime pickedWIB = picked.add(Duration(hours: 7));
      if (pickedWIB !=
          DateTime(pickedWIB.year, pickedWIB.month, pickedWIB.day)) {
        setState(() {
          _selectedDate = picked;
        });
        _updateStartEpoch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Anda tidak dapat memilih tanggal yang cocok dengan tanggal data."),
        ));
      }
    }
  }
}

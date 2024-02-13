import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:VehiLoc/core/model/response_daily.dart';
import 'package:VehiLoc/core/utils/conts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:VehiLoc/features/vehicles/api/api_service.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class DetailsPageView extends StatefulWidget {
  final int vehicleId;
  final double? vehicleLat;
  final double? vehicleLon;
  final String? vehicleName;
  int gpsdt;

  DetailsPageView({
    Key? key,
    required this.vehicleId,
    required this.vehicleLat,
    required this.vehicleLon,
    required this.vehicleName,
    required this.gpsdt,
  }) : super(key: key);

  @override
  _DetailsPageViewState createState() => _DetailsPageViewState();
}

class _DetailsPageViewState extends State<DetailsPageView> {
  final ApiService apiService = ApiService();

  List<Marker> stopMarkers = [];

  late LatLng _initialCameraPosition;

  final _cartesianChartKey = GlobalKey<SfCartesianChartState>();

  late DateTime _selectedDate;
  double _sliderValue = 0.0;

  late BitmapDescriptor _greenMarkerIcon;
  late BitmapDescriptor _redMarkerIcon;
  late BitmapDescriptor _greyMarkerIcon;

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
          await apiService.fetchDailyHistory(vehicleId, startEpoch);

      setState(() {
        allData = [dataAll];
        dailyData = allData.isNotEmpty ? allData[0].data : [];
        inputData = allData.isNotEmpty ? dataAll.inputlogs : [];
        detailsItem = allData.isNotEmpty ? dataAll.jdetails : [];
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
    final Uint8List greyMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_gray.png', 40);

    _greenMarkerIcon = BitmapDescriptor.fromBytes(greenMarkerIconData);
    _redMarkerIcon = BitmapDescriptor.fromBytes(redMarkerIconData);
    _greyMarkerIcon = BitmapDescriptor.fromBytes(greyMarkerIconData);
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
      width: 2,
    );

    return Set.of([polyline]);
  }

  Set<Marker> _createMarkers(double sliderValue) {
    final Set<Marker> markers = {};

    if (dailyData.isNotEmpty) {
      int index = (sliderValue * dailyData.length / 100).round();
      if (index >= dailyData.length) index = dailyData.length - 1;

      final DataItem currentDaily = dailyData[index];

      markers.add(
        Marker(
          markerId: MarkerId("${widget.vehicleId}"),
          position: LatLng(currentDaily.latitude, currentDaily.longitude),
          rotation: currentDaily.bearing.toDouble(),
          icon: currentDaily.speed == 0
              ? _greyMarkerIcon
              : currentDaily.speed <= 60
                  ? _greenMarkerIcon
                  : _redMarkerIcon,
          infoWindow: InfoWindow(
            title: "${widget.vehicleName}",
          ),
        ),
      );
    }

    List<JdetailsItem> stopDetails =
        detailsItem.where((detail) => detail.type == 1).toList();

    final List<Marker> stopMarkers = stopDetails.map((detail) {
      return Marker(
        markerId: MarkerId("${detail.startdt}-${detail.enddt}"),
        position: LatLng(detail.lat, detail.lon),
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: "Berhenti",
          snippet:
              "Jam: ${DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(detail.startdt * 1000))}",
        ),
      );
    }).toList();

    markers.addAll(stopMarkers);

    return markers;
  }

  String _getTimeForSliderValue(double sliderValue) {
    if (dailyData.isEmpty) {
      return '';
    }

    int index = (sliderValue * dailyData.length / 100).round();
    if (index >= dailyData.length) index = dailyData.length - 1;

    final DataItem currentDaily = dailyData[index];
    // Ubah format waktu sesuai kebutuhan
    return DateFormat.Hm()
        .format(DateTime.fromMillisecondsSinceEpoch(currentDaily.gpsdt * 1000));
  }

  String _getSpeedForSliderValue(double sliderValue) {
    if (dailyData.isEmpty) {
      return '';
    }

    int index = (sliderValue * dailyData.length / 100).round();
    if (index >= dailyData.length) index = dailyData.length - 1;

    final DataItem currentDaily = dailyData[index];
    return '${currentDaily.speed}';
  }

  double _getTemperatureForSliderValue(double sliderValue) {
    if (dailyData.isEmpty) {
      return 0.0;
    }

    int index = (sliderValue * dailyData.length / 100).round();
    if (index >= dailyData.length) index = dailyData.length - 1;

    final DataItem currentDaily = dailyData[index];
    return currentDaily.temp.toDouble() / 10;
  }

  bool _isForwardButtonEnabled() {
    DateTime maxDate =
        DateTime.fromMillisecondsSinceEpoch(widget.gpsdt * 1000, isUtc: true);
    DateTime selectedDateUtc = DateTime.utc(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selectedDateUtc.isBefore(maxDate);
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: _isForwardButtonEnabled()
                        ? () {
                            setState(() {
                              _selectedDate =
                                  _selectedDate.add(Duration(days: 1));
                              _updateStartEpoch();
                            });
                          }
                        : null,
                    icon: Icon(Icons.arrow_forward),
                  )
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
              height: MediaQuery.of(context).size.height * 0.75,
              child: Builder(
                builder: (context) {
                  return _selectedTabIndex == 0
                      ? _buildMapWidget()
                      : _selectedTabIndex == 1
                          ? _buildNarationWidget()
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
    return dailyData.isEmpty
        ? Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[300],
            ),
          )
        : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.access_time,
                            size: 30, color: Colors.black),
                        onPressed: () {},
                      ),
                      Text(
                        '${_getTimeForSliderValue(_sliderValue)}',
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.speed, size: 30, color: Colors.black),
                        onPressed: () {},
                      ),
                      Text(
                        '${_getSpeedForSliderValue(_sliderValue)} KM/H',
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.thermostat,
                            size: 30, color: Colors.black),
                        onPressed: () {},
                      ),
                      Text(
                        '${_getTemperatureForSliderValue(_sliderValue)}°',
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialCameraPosition,
                    zoom: 10,
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
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20),
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

  Widget _buildNarationWidget() {
    return FutureBuilder<List<JdetailsItem>>(
      future: fetchNarationData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Data tidak ada'));
        } else {
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text('Data Narasi tidak ada'));
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: DataTable(
                    columnSpacing: 20,
                    headingTextStyle: TextStyle(fontWeight: FontWeight.bold),
                    columns: const [
                      DataColumn(
                        label: Text('Waktu',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins')),
                      ),
                      DataColumn(
                        label: Text('Narasi',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins')),
                      ),
                    ],
                    rows: snapshot.data!.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(
                          '${_formatTime(item.startdt)} - ${_formatTime(item.enddt)}',
                          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                        )),
                        DataCell(Text(
                          '${formatNaration(item)}',
                          style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }

  String _formatTime(int timestamp) {
    return DateFormat.Hm()
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
  }

  String formatNaration(JdetailsItem item) {
    if (item.type == 1) {
      String duration = _formatDuration(item.enddt - item.startdt);
      return 'Stopped $duration';
    } else if (item.type == 2) {
      double distanceKm = item.distance / 1000;
      return 'Moved ${distanceKm.toStringAsFixed(2)} km for ${_formatDuration(item.enddt - item.startdt)}';
    } else {
      return 'Unknown event';
    }
  }

  String _formatDuration(int durationSeconds) {
    int hours = durationSeconds ~/ 3600;
    int minutes = (durationSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours hr ${minutes} mins';
    } else {
      return '${minutes} mins';
    }
  }

  Widget _buildEventWidget() {
    return FutureBuilder<List<InputLogsItem>>(
      future: fetchEventData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Data tidak ada'));
        } else {
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text('Data Event tidak ada'));
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: DataTable(
                    columnSpacing: 20,
                    headingTextStyle: TextStyle(fontWeight: FontWeight.bold),
                    columns: const [
                      DataColumn(
                        label: Text('Waktu',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins')),
                      ),
                      DataColumn(
                        label: Text('Event',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins')),
                      ),
                    ],
                    rows: snapshot.data!.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(
                          DateFormat.Hm().format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  item.dt * 1000)),
                          style: const TextStyle(
                              fontSize: 18, fontFamily: 'Poppins'),
                        )),
                        DataCell(Text(
                          '${item.sensorName} was ${item.newStateDesc}',
                          style: const TextStyle(
                              fontSize: 18, fontFamily: 'Poppins'),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildChartWidget() {
    return FutureBuilder<List<DataItem>>(
      future: fetchDataItem(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Data tidak ada',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          );
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'Data Suhu tidak ada',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          );
        } else {
          List<DataItem> chartData = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: 2000,
                    child: SfCartesianChart(
                      key: _cartesianChartKey,
                      title: ChartTitle(
                        text:
                            'Grafik Suhu ${_selectedDate.day} ${DateFormat.MMMM().format(_selectedDate)}, ${_selectedDate.year}',
                        textStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <LineSeries<DataItem, DateTime>>[
                        LineSeries<DataItem, DateTime>(
                          dataSource: chartData,
                          xValueMapper: (DataItem data, _) =>
                              DateTime.fromMillisecondsSinceEpoch(
                                  data.gpsdt * 1000),
                          yValueMapper: (DataItem data, _) => data.temp / 10,
                          name: 'Suhu',
                        )
                      ],
                      primaryXAxis: DateTimeAxis(
                        title: AxisTitle(
                          text: 'Waktu',
                          textStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        dateFormat: DateFormat.Hm(),
                      ),
                      primaryYAxis: NumericAxis(
                        title: AxisTitle(
                          text: 'Suhu',
                          textStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        minimum: 18,
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  _renderChartAsImage(context);
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.grey),
                ),
                child: const Text(
                  'Export as image',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          );
        }
      },
    );
  }

  Future<void> _renderChartAsImage(BuildContext context) async {
    final ui.Image? data =
        await _cartesianChartKey.currentState!.toImage(pixelRatio: 3.0);
    final ByteData? bytes =
        await data?.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imageBytes =
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);

    // Simpan gambar ke galeri
    final result = await ImageGallerySaver.saveImage(imageBytes);

    // Tampilkan pesan berdasarkan hasil simpan
    if (result['isSuccess']) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Image saved'),
            content: Text('The image has been saved to your gallery.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Failed to save image'),
            content: Text('Failed to save the image to your gallery.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
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
          await apiService.fetchDailyHistory(vehicleId, startEpoch);

      setState(() {
        allData = [dataAll];
        dailyData = allData.isNotEmpty ? allData[0].data : [];
        inputData = allData.isNotEmpty ? dataAll.inputlogs : [];

        if (_selectedTabIndex == 0 &&
            dailyData.isNotEmpty &&
            _mapController != null) {
          final DataItem currentDaily = dailyData.first;
          _initialCameraPosition =
              LatLng(currentDaily.latitude, currentDaily.longitude);

          _mapController.animateCamera(
            CameraUpdate.newLatLng(_initialCameraPosition),
          );
        }

        // Update stopMarkers
        detailsItem = allData.isNotEmpty ? dataAll.jdetails : [];
        final List<Marker> updatedStopMarkers =
            detailsItem.where((detail) => detail.type == 1).map((detail) {
          return Marker(
            markerId: MarkerId("${detail.startdt}-${detail.enddt}"),
            position: LatLng(detail.lat, detail.lon),
            icon: BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(
              title: "Berhenti",
              snippet:
                  "Jam: ${DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(detail.startdt * 1000))}",
            ),
          );
        }).toList();

        // Replace existing stopMarkers with updatedStopMarkers
        stopMarkers.clear();
        stopMarkers.addAll(updatedStopMarkers);
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
      selectableDayPredicate: (DateTime date) {
        DateTime lastSelectableDate = DateTime.fromMillisecondsSinceEpoch(
          widget.gpsdt * 1000,
          isUtc: true,
        ).add(Duration(days: 1));
        return date.isBefore(lastSelectableDate);
      },
    );
    if (picked != null && picked != _selectedDate) {
      DateTime gpsdtUtc = DateTime.fromMillisecondsSinceEpoch(
        widget.gpsdt * 1000,
        isUtc: true,
      );
      DateTime gpsdtWIB = gpsdtUtc.add(const Duration(hours: 7));
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

  Future<List<InputLogsItem>> fetchEventData() async {
    final int vehicleId = widget.vehicleId;
    final int startEpoch = widget.gpsdt;

    try {
      final Data dataAll =
          await apiService.fetchDailyHistory(vehicleId, startEpoch);

      return dataAll.inputlogs;
    } catch (e) {
      print("error : $e");
      throw e;
    }
  }

  Future<List<JdetailsItem>> fetchNarationData() async {
    final int vehicleId = widget.vehicleId;
    final int startEpoch = widget.gpsdt;

    try {
      final Data dataAll =
          await apiService.fetchDailyHistory(vehicleId, startEpoch);

      return dataAll.jdetails;
    } catch (e) {
      print("error : $e");
      throw e;
    }
  }

  Future<List<DataItem>> fetchDataItem() async {
    final int vehicleId = widget.vehicleId;
    final int startEpoch = widget.gpsdt;

    try {
      final Data dataAll =
          await apiService.fetchDailyHistory(vehicleId, startEpoch);

      return dataAll.data;
    } catch (e) {
      print("error : $e");
      throw e;
    }
  }
}

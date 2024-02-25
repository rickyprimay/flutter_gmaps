import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:VehiLoc/core/model/response_daily.dart';
import 'package:VehiLoc/core/utils/colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:VehiLoc/core/Api/api_service.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:VehiLoc/features/vehicles/widget/custom_slider.dart';
import 'package:VehiLoc/features/vehicles/widget/naration_widget.dart';
import 'package:VehiLoc/features/vehicles/widget/event_widget.dart';
import 'package:logger/logger.dart';

class DetailsPageView extends StatefulWidget {
  final int vehicleId;
  final double? vehicleLat;
  final double? vehicleLon;
  final String? vehicleName;
  final int? type;
  late int gpsdt;
  late int initialGpsdt;
  late List<DataItem> dataItems;

  DetailsPageView({
    Key? key,
    required this.vehicleId,
    required this.vehicleLat,
    required this.vehicleLon,
    required this.vehicleName,
    required this.gpsdt,
    required this.type,
  }) : super(key: key) {
    initialGpsdt = gpsdt;
    dataItems = [];
  }

  @override
  _DetailsPageViewState createState() => _DetailsPageViewState();
}

class _DetailsPageViewState extends State<DetailsPageView> {
  final Logger logger = Logger();
  final ApiService apiService = ApiService();

  List<Marker> stopMarkers = [];

  late LatLng _initialCameraPosition;

  final _cartesianChartKey = GlobalKey<SfCartesianChartState>();

  late DateTime _selectedDate;
  double _sliderValue = 100.0;

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

  bool exportingImage = false;

  bool _isLoading = false;

  bool _isSpeedChartVisible = true;
  bool _isTemperatureChartVisible = true;

  @override
  void initState() {
    super.initState();
    _initialCameraPosition =
        LatLng(widget.vehicleLat ?? 0.0, widget.vehicleLon ?? 0.0);

    DateTime gpsdtUtc = DateTime.fromMillisecondsSinceEpoch(
      widget.gpsdt * 1000,
      isUtc: true,
    );
    DateTime gpsdtWIB = gpsdtUtc.add(const Duration(hours: 7));
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
      logger.e("error : $e");
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

    final List<Marker> stopMarkers = stopDetails.asMap().entries.map((entry) {
      final int index = entry.key;
      final JdetailsItem detail = entry.value;
      return Marker(
        markerId: MarkerId("${detail.startdt}-${detail.enddt}"),
        position: LatLng(detail.lat, detail.lon),
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: "Stop ${index + 1}",
          snippet:
              "Jam : ${DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(detail.startdt * 1000))} - ${DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(detail.enddt * 1000))}",
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
    DateTime maxDate = DateTime.fromMillisecondsSinceEpoch(
        widget.initialGpsdt * 1000,
        isUtc: true);
    DateTime selectedDateUtc = DateTime.utc(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selectedDateUtc.isBefore(maxDate);
  }

  LatLng _calculatePolylineCenter() {
    if (dailyData.isEmpty) {
      return _initialCameraPosition;
    }

    final List<LatLng> polylineCoordinates = dailyData
        .map((daily) => LatLng(daily.latitude, daily.longitude))
        .toList();

    double sumLat = 0.0;
    double sumLng = 0.0;

    for (LatLng coordinate in polylineCoordinates) {
      sumLat += coordinate.latitude;
      sumLng += coordinate.longitude;
    }

    double averageLat = sumLat / polylineCoordinates.length;
    double averageLng = sumLng / polylineCoordinates.length;

    return LatLng(averageLat, averageLng);
  }

  LatLngBounds _calculatePolylineBounds() {
    if (dailyData.isEmpty) {
      return LatLngBounds(
        southwest: _initialCameraPosition,
        northeast: _initialCameraPosition,
      );
    }

    final List<LatLng> polylineCoordinates = dailyData
        .map((daily) => LatLng(daily.latitude, daily.longitude))
        .toList();

    double minLat = polylineCoordinates[0].latitude;
    double maxLat = polylineCoordinates[0].latitude;
    double minLng = polylineCoordinates[0].longitude;
    double maxLng = polylineCoordinates[0].longitude;

    for (LatLng coordinate in polylineCoordinates) {
      if (coordinate.latitude < minLat) minLat = coordinate.latitude;
      if (coordinate.latitude > maxLat) maxLat = coordinate.latitude;
      if (coordinate.longitude < minLng) minLng = coordinate.longitude;
      if (coordinate.longitude > maxLng) maxLng = coordinate.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  double _calculateZoomLevel(LatLngBounds bounds) {
    const double padding = 50.0;
    const double desiredWidth = 400.0;

    double angle = bounds.northeast.longitude - bounds.southwest.longitude;
    if (angle < 0) {
      angle += 360;
    }

    double zoom = _getBoundsZoomLevel(bounds, padding, desiredWidth);
    return zoom;
  }

  double _getBoundsZoomLevel(
      LatLngBounds bounds, double padding, double width) {
    double globeWidth = 256;
    double west = bounds.southwest.longitude;
    double east = bounds.northeast.longitude;
    double angle = east - west;
    if (angle < 0) {
      angle += 360;
    }

    double zoom = ((width - padding) * 360) / (angle * globeWidth);
    return zoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
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
                  Expanded(
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDate =
                              _selectedDate.subtract(const Duration(days: 1));
                          _updateStartEpoch();
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
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
                        '${_selectedDate.day} ${DateFormat.MMM().format(_selectedDate)}, ${_selectedDate.year}',
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: GlobalColor.textColor),
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      onPressed: _isForwardButtonEnabled()
                          ? () {
                              setState(() {
                                _selectedDate =
                                    _selectedDate.add(const Duration(days: 1));
                                _updateStartEpoch();
                              });
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  )
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: _selectedTabIndex == 0 ? 2 : 1,
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Colors.black, width: 0.5),
                    ),
                    color: _selectedTabIndex == 0 ? Colors.grey[400] : null,
                    child: Text(
                      'Map',
                      style: GoogleFonts.poppins(
                        fontWeight: _selectedTabIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: _selectedTabIndex == 1 ? 2 : 1,
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Colors.black, width: 0.5),
                    ),
                    color: _selectedTabIndex == 1 ? Colors.grey[400] : null,
                    child: Text('Narasi',
                        style: GoogleFonts.poppins(
                          fontWeight: _selectedTabIndex == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                  ),
                ),
                Expanded(
                  flex: _selectedTabIndex == 2 ? 2 : 1,
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 2;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Colors.black, width: 0.5),
                    ),
                    color: _selectedTabIndex == 2 ? Colors.grey[400] : null,
                    child: Text('Event',
                        style: GoogleFonts.poppins(
                          fontWeight: _selectedTabIndex == 2
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                  ),
                ),
                Expanded(
                  flex: _selectedTabIndex == 3 ? 2 : 1,
                  child: MaterialButton(
                    onPressed: () {
                      setState(() {
                        _selectedTabIndex = 3;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Colors.black, width: 0.5),
                    ),
                    color: _selectedTabIndex == 3 ? Colors.grey[400] : null,
                    child: Text('Grafik',
                        style: GoogleFonts.poppins(
                          fontWeight: _selectedTabIndex == 3
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.71,
              child: Builder(
                builder: (context) {
                  return _selectedTabIndex == 0
                      ? _buildMapWidget()
                      : _selectedTabIndex == 1
                          ? NarationWidget(
                              narationData: detailsItem,
                              fetchNarationData: () => fetchNarationData(),
                            )
                          : _selectedTabIndex == 2
                              ? EventWidget(
                                  eventData: inputData,
                                  fetchEventData: () => fetchEventData(),
                                )
                              : _buildChartWidget();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDialog() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildMapWidget() {
    return _isLoading
        ? _buildLoadingDialog()
        : dailyData.isEmpty
            ? Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey[300]!, Colors.grey[100]!],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Data tidak ada',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
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
                            icon: const Icon(Icons.access_time,
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
                            icon: const Icon(Icons.speed,
                                size: 30, color: Colors.black),
                            onPressed: () {},
                          ),
                          Text(
                            '${_getSpeedForSliderValue(_sliderValue)} kmh',
                            style: GoogleFonts.poppins(),
                          ),
                        ],
                      ),
                      if (widget.type == 4)
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.thermostat,
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
                        target: _calculatePolylineCenter(),
                        zoom: 12,
                      ),
                      markers: _createMarkers(_sliderValue),
                      polylines: _createPolylines(),
                      onMapCreated: (controller) {
                        setState(() {
                          _mapController = controller;
                        });

                        LatLngBounds bounds = _calculatePolylineBounds();
                        Timer(const Duration(milliseconds: 2000), () {
                          _mapController.animateCamera(
                            CameraUpdate.newLatLngBounds(bounds, 50),
                          );
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SizedBox(
                      height: 70,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.topRight,
                            colors: [
                              for (var dataItem in dailyData)
                                dataItem.colorBox == 'white'
                                    ? Colors.grey[300]!
                                    : dataItem.colorBox == 'green'
                                        ? Colors.green
                                        : dataItem.colorBox == 'yellow'
                                            ? Colors.yellow
                                            : Colors.red,
                            ],
                          ),
                        ),
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 8,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 20),
                            valueIndicatorShape:
                                const PaddleSliderValueIndicatorShape(),
                            valueIndicatorTextStyle: const TextStyle(
                              color: Colors.black,
                            ),
                            trackShape: CustomTrackShape(),
                          ),
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
                    ),
                  )
                ],
              );
  }

  Widget _buildChartWidget() {
    return FutureBuilder<List<DataItem>>(
      future: fetchDataItem(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Data tidak ada',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          );
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'Data Suhu tidak ada',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          );
        } else {
          List<DataItem> chartData = snapshot.data!;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isSpeedChartVisible,
                    onChanged: (value) {
                      setState(() {
                        _isSpeedChartVisible = value!;
                      });
                    },
                  ),
                  Text('Show Speed Chart'),
                  if (widget.type == 4)
                    Checkbox(
                      value: _isTemperatureChartVisible,
                      onChanged: (value) {
                        setState(() {
                          _isTemperatureChartVisible = value!;
                        });
                      },
                    ),
                  if (widget.type == 4) Text('Show Temp Chart'),
                ],
              ),
              if (_isSpeedChartVisible ||
                  (_isTemperatureChartVisible && widget.type == 4)) ...[
                Expanded(
                  child: SingleChildScrollView(
                    // scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1200,
                      height: 600,
                      child: SfCartesianChart(
                        key: _cartesianChartKey,
                        title: ChartTitle(
                          text:
                              '${_isTemperatureChartVisible && widget.type == 4 ? 'Grafik Suhu' : ''}'
                              '${_isTemperatureChartVisible && _isSpeedChartVisible ? ' dan ' : ''}'
                              '${_isSpeedChartVisible ? 'Grafik Kecepatan' : ''}'
                              ' \n ${widget.vehicleName} \n ${_selectedDate.day} ${DateFormat.MMM().format(_selectedDate)}, ${_selectedDate.year}',
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        tooltipBehavior: TooltipBehavior(enable: true),
                        series: <LineSeries<DataItem, DateTime>>[
                          if (_isSpeedChartVisible)
                            LineSeries<DataItem, DateTime>(
                              dataSource: chartData,
                              xValueMapper: (DataItem data, _) =>
                                  DateTime.fromMillisecondsSinceEpoch(
                                      data.gpsdt * 1000),
                              yValueMapper: (DataItem data, _) =>
                                  data.speed.toDouble(),
                              name: 'Kecepatan',
                              color: Colors.orange[300],
                              yAxisName: 'Kecepatan',
                              width: 1,
                              legendItemText: 'Speed (kmh)',
                            ),
                          if (_isTemperatureChartVisible && widget.type == 4)
                            LineSeries<DataItem, DateTime>(
                              dataSource: chartData,
                              xValueMapper: (DataItem data, _) =>
                                  DateTime.fromMillisecondsSinceEpoch(
                                      data.gpsdt * 1000),
                              yValueMapper: (DataItem data, _) =>
                                  data.temp / 10,
                              name: 'Suhu',
                              color: Colors.blue[700],
                              yAxisName: 'Suhu',
                              width: 1,
                              legendIconType: LegendIconType.horizontalLine,
                              legendItemText: 'Temp (°C)',
                            ),
                        ],
                        primaryXAxis: DateTimeAxis(
                          title: const AxisTitle(
                            text: 'Waktu',
                            textStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          dateFormat: DateFormat.Hm(),
                        ),
                        primaryYAxis: const NumericAxis(
                          opposedPosition: true,
                          name: 'Kecepatan',
                          title: AxisTitle(
                            textStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          minimum: 0,
                          interval: 20,
                        ),
                        axes: const <ChartAxis>[
                          NumericAxis(
                            name: 'Suhu',
                            opposedPosition: false,
                            title: AxisTitle(
                              textStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            minimum: 0,
                            interval: 10,
                          ),
                        ],
                        legend: const Legend(
                          isVisible: true,
                          textStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              ElevatedButton(
                onPressed: () {
                  _renderChartAsImage(context);
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.grey),
                ),
                child: Text(
                  'Export as image',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GlobalColor.textColor,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Future<void> _renderChartAsImage(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Processing'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Mohon tunggu...'),
            ],
          ),
        );
      },
    );

    final ui.Image? data =
        await _cartesianChartKey.currentState!.toImage(pixelRatio: 3.0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder,
        Rect.fromPoints(const Offset(0.0, 0.0), const Offset(1220.0, 1720.0)));
    canvas.drawColor(GlobalColor.textColor, BlendMode.dstOver);
    canvas.drawImage(data!, Offset.zero, Paint());
    final ui.Image finalImage =
        await recorder.endRecording().toImage(1220, 1720);

    final ByteData? bytes =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imageBytes =
        bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);

    final result = await ImageGallerySaver.saveImage(imageBytes);

    Navigator.of(context).pop();

    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: result['isSuccess']
              ? const Text('Foto Tersimpan')
              : const Text('Gagal untuk menyimpan foto'),
          content: result['isSuccess']
              ? const Text('Foto telah tersimpan di galeri anda.')
              : const Text('Gagal untuk menyimpan foto ke galeri anda'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
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
      setState(() {
        widget.gpsdt = startEpoch;
        _isLoading = true;
      });

      final Data dataAll =
          await apiService.fetchDailyHistory(vehicleId, startEpoch);

      setState(() {
        allData = [dataAll];
        dailyData = allData.isNotEmpty ? allData[0].data : [];
        inputData = allData.isNotEmpty ? dataAll.inputlogs : [];

        if (_selectedTabIndex == 0 && dailyData.isNotEmpty) {
          final DataItem currentDaily = dailyData.first;
          _initialCameraPosition =
              LatLng(currentDaily.latitude, currentDaily.longitude);

          // _mapController.animateCamera(
          //   CameraUpdate.newLatLng(_initialCameraPosition),
          // );
        }

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

        stopMarkers.clear();
        stopMarkers.addAll(updatedStopMarkers);
      });
    } catch (e) {
      logger.e("error : $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
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
          widget.initialGpsdt * 1000,
          isUtc: true,
        ).add(const Duration(days: 1));
        return date.isBefore(lastSelectableDate);
      },
    );
    if (picked != null && picked != _selectedDate) {
      DateTime gpsdtUtc = DateTime.fromMillisecondsSinceEpoch(
        widget.initialGpsdt * 1000,
        isUtc: true,
      );
      DateTime gpsdtWIB = gpsdtUtc.add(const Duration(hours: 7));
      DateTime pickedWIB = picked.add(const Duration(hours: 7));
      if (pickedWIB !=
          DateTime(pickedWIB.year, pickedWIB.month, pickedWIB.day)) {
        setState(() {
          _selectedDate = picked;
        });
        _updateStartEpoch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
      logger.e("error : $e");
      rethrow;
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
      logger.e("error : $e");
      rethrow;
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
      logger.e("error : $e");
      rethrow;
    }
  }
}

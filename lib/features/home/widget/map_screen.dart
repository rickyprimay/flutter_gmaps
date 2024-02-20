import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:VehiLoc/core/model/response_vehicles.dart';
import 'package:VehiLoc/core/utils/colors.dart';
import 'package:VehiLoc/core/Api/api_provider.dart';
import 'dart:math';

class MapScreen extends StatefulWidget {
  final double? lat;
  final double? lon;

  MapScreen({this.lat, this.lon});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late BitmapDescriptor greenMarkerIcon;
  late BitmapDescriptor redMarkerIcon;
  late BitmapDescriptor greyMarkerIcon;
  late Future<List<Vehicle>> _fetchData = Future.value([]);

  @override
  void initState() {
    super.initState();
    setMarkerIcons();
    _fetchData = fetchData();
  }

  Future<List<Vehicle>> fetchData() async {
    return ApiProvider().getApiResponse();
  }

  void setMarkerIcons() async {
    final Uint8List greenMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_green.png', 40);
    final Uint8List redMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_red.png', 40);
    final Uint8List greyMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_gray.png', 40);

    greenMarkerIcon = BitmapDescriptor.fromBytes(greenMarkerIconData);
    redMarkerIcon = BitmapDescriptor.fromBytes(redMarkerIconData);
    greyMarkerIcon = BitmapDescriptor.fromBytes(greyMarkerIconData);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Map',
          style: GoogleFonts.poppins(
            color: GlobalColor.textColor,
          ),
        ),
        backgroundColor: GlobalColor.mainColor,
      ),
      body: FutureBuilder<List<Vehicle>>(
        future: _fetchData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          } else {
            List<Vehicle> vehicles = snapshot.data!;
            LatLngBounds bounds = _getBounds(vehicles);
            LatLng center = LatLng(
                (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
                (bounds.southwest.longitude + bounds.northeast.longitude) / 2);

            double zoomLevel = _calculateZoomLevel(bounds);

            double widthZoom = _calculateZoomLevel(LatLngBounds(
              southwest:
                  LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
              northeast:
                  LatLng(bounds.southwest.latitude, bounds.northeast.longitude),
            ));
            double heightZoom = _calculateZoomLevel(LatLngBounds(
              southwest:
                  LatLng(bounds.southwest.latitude, bounds.southwest.longitude),
              northeast:
                  LatLng(bounds.northeast.latitude, bounds.southwest.longitude),
            ));

            zoomLevel = max(zoomLevel, max(widthZoom, heightZoom));

            return GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: widget.lat != null && widget.lon != null
                    ? LatLng(widget.lat!, widget.lon!)
                    : center,
                zoom: widget.lat != null && widget.lon != null ? 16 : zoomLevel,
              ),
              markers: Set<Marker>.from(
                vehicles.map((vehicle) {
                  BitmapDescriptor markerIcon;
                  DateTime? gpsdtWIB;

                  if (vehicle.speed == 0) {
                    markerIcon = redMarkerIcon;
                  } else if (vehicle.speed! > 0 && vehicle.speed! < 60) {
                    markerIcon = greenMarkerIcon;
                  } else {
                    markerIcon = redMarkerIcon;
                  }

                  if (vehicle.gpsdt != null) {
                    DateTime gpsdtUtc = DateTime.fromMillisecondsSinceEpoch(
                        vehicle.gpsdt! * 1000,
                        isUtc: true);
                    gpsdtWIB = gpsdtUtc.add(const Duration(hours: 7));
                    DateTime now = DateTime.now();
                    int differenceInDays = now.difference(gpsdtWIB).inDays;

                    if (differenceInDays > 7) {
                      markerIcon = greyMarkerIcon;
                    }
                  }

                  return Marker(
                    markerId: MarkerId('${vehicle.vehicleId}'),
                    position: LatLng(vehicle.lat!, vehicle.lon!),
                    icon: markerIcon,
                    infoWindow: InfoWindow(
                      title: ("${vehicle.name}"),
                      snippet:
                          ("${vehicle.plateNo} || ${vehicle.speed}KM/H || ${_formatDateTime(gpsdtWIB!)} "),
                    ),
                    rotation: vehicle.bearing?.toDouble() ?? 0.0,
                  );
                }),
              ),
              myLocationEnabled: true,
              compassEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                if (!(widget.lat != null && widget.lon != null)) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    controller.animateCamera(
                      CameraUpdate.newLatLngBounds(bounds, 20),
                    );
                  });
                }
              },
            );
          }
        },
      ),
    );
  }

  LatLngBounds _getBounds(List<Vehicle> vehicles) {
    List<LatLng> positions =
        vehicles.map((vehicle) => LatLng(vehicle.lat!, vehicle.lon!)).toList();
    double minLat = positions.map((pos) => pos.latitude).reduce(min);
    double minLon = positions.map((pos) => pos.longitude).reduce(min);
    double maxLat = positions.map((pos) => pos.latitude).reduce(max);
    double maxLon = positions.map((pos) => pos.longitude).reduce(max);

    return LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
  }

  double _calculateZoomLevel(LatLngBounds bounds) {
    const double padding = 50.0;
    double zoomWidth = _getZoomWidth(
        bounds.southwest.longitude, bounds.northeast.longitude, padding);
    double zoomHeight = _getZoomHeight(
        bounds.southwest.latitude, bounds.northeast.latitude, padding);
    double zoom = min(zoomWidth, zoomHeight);
    return zoom;
  }

  double _getZoomWidth(double minLon, double maxLon, double padding) {
    double angle = maxLon - minLon;
    double zoom = log(360.0 / angle) / ln2;
    return zoom - log(padding / 360) / ln2;
  }

  double _getZoomHeight(double minLat, double maxLat, double padding) {
    double angle = maxLat - minLat;
    double zoom = log(180.0 / angle) / ln2;
    return zoom - log(padding / 180) / ln2;
  }
}

String _formatDateTime(DateTime dateTime) {
  final now = DateTime.now();

  if (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day) {
    return DateFormat.Hm().format(dateTime);
  } else if (dateTime.year == now.year) {
    return DateFormat('dd-MMM').format(dateTime);
  } else {
    return DateFormat.y().format(dateTime);
  }
}

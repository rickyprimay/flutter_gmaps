import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:VehiLoc/core/model/response_vehicles.dart';
import 'package:VehiLoc/features/account/account.view.dart';
import 'package:VehiLoc/core/utils/conts.dart';
import 'package:VehiLoc/features/vehicles/api/api_provider.dart';
import 'package:VehiLoc/features/vehicles/vehicles.view.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int currentIndex = 0;

  void _ontItemTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  List<Widget> bodyBottomBar = [
    MapScreen(),
    VehicleView(),
    AccountView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: bodyBottomBar[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        fixedColor: Colors.white,
        showSelectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(
          // Gunakan GoogleFonts.poppins()
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(color: Colors.white),
        showUnselectedLabels: false,
        backgroundColor: GlobalColor.mainColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/map-icon.svg',
              color: Colors.white,
            ),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/car-icon.svg',
              color: Colors.white,
            ),
            label: 'Kendaraan',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset(
              'assets/icons/profile-icon.svg',
              color: Colors.white,
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: currentIndex,
        onTap: _ontItemTap,
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final double? lat;
  final double? lon;

  MapScreen({this.lat, this.lon});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultCenter = const LatLng(-7.00224, 110.44013);
  late LatLng _center;
  late BitmapDescriptor greenMarkerIcon;
  late BitmapDescriptor redMarkerIcon;
  late BitmapDescriptor greyMarkerIcon;

  @override
  void initState() {
    super.initState();
    _center = widget.lat != null && widget.lon != null
        ? LatLng(widget.lat!, widget.lon!)
        : _defaultCenter;
    setMarkerIcons();
  }

  void setMarkerIcons() async {
    final Uint8List greenMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_green.png', 30);
    final Uint8List redMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_red.png', 30);
    final Uint8List greyMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_gray.png', 30);

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
            // Gunakan GoogleFonts.poppins()
            color: GlobalColor.textColor,
          ),
        ),
        backgroundColor: GlobalColor.mainColor,
      ),
      body: FutureBuilder<List<Vehicle>>(
        future: ApiProvider().getApiResponse(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          } else {
            List<Vehicle> vehicles = snapshot.data!;

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: widget.lat != null && widget.lon != null ? 16.0 : 11.0,
              ),
              markers: Set<Marker>.from(
                vehicles.map((vehicle) {
                  BitmapDescriptor markerIcon;
                  if (vehicle.speed == 0) {
                    markerIcon = greyMarkerIcon;
                  } else if (vehicle.speed! > 0 && vehicle.speed! < 60) {
                    markerIcon = greenMarkerIcon;
                  } else {
                    markerIcon = redMarkerIcon;
                  }

                  return Marker(
                    markerId: MarkerId('${vehicle.vehicleId}'),
                    position: LatLng(vehicle.lat!, vehicle.lon!),
                    icon: markerIcon,
                    infoWindow: InfoWindow(
                      title: ("${vehicle.name}"),
                      snippet: ("${vehicle.name}"),
                    ),
                    rotation: vehicle.bearing?.toDouble() ?? 0.0,
                  );
                }),
              ),
            );
          }
        },
      ),
    );
  }
}

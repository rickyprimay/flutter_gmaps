import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart'; // Import google_fonts package
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vehiloc/core/model/response_vehicles.dart';
import 'package:vehiloc/features/account/account.view.dart';
import 'package:vehiloc/core/utils/conts.dart';
import 'package:vehiloc/features/vehicles/api/api_provider.dart';
import 'package:vehiloc/features/vehicles/vehicles.view.dart';

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
        unselectedLabelStyle: GoogleFonts.poppins(
            color: Colors.white), // Gunakan GoogleFonts.poppins()
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
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _center = const LatLng(-7.00224, 110.44013);
  late BitmapDescriptor greenMarkerIcon;
  late BitmapDescriptor redMarkerIcon;

  @override
  void initState() {
    super.initState();
    setMarkerIcons();
  }

  void setMarkerIcons() async {
    final Uint8List greenMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_green.png', 40);
    final Uint8List redMarkerIconData =
        await getBytesFromAsset('assets/icons/arrow_red.png', 40);

    greenMarkerIcon = BitmapDescriptor.fromBytes(greenMarkerIconData);
    redMarkerIcon = BitmapDescriptor.fromBytes(redMarkerIconData);
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
                zoom: 11.0,
              ),
              markers: Set<Marker>.from(
                vehicles.map((vehicle) => Marker(
                      markerId: MarkerId('${vehicle.vehicleId}'),
                      position: LatLng(vehicle.lat!, vehicle.lon!),
                      icon:
                          vehicle.speed == 0 ? redMarkerIcon : greenMarkerIcon,
                      infoWindow: InfoWindow(
                        title: ("${vehicle.name}"),
                        snippet: ("${vehicle.name}"),
                      ),
                      rotation: vehicle.bearing?.toDouble() ?? 0.0,
                    )),
              ),
            );
          }
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomeView(),
  ));
}

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
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
        selectedLabelStyle: GoogleFonts.workSans(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.workSans(color: Colors.white),
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
    greenMarkerIcon = await CustomMarkerGenerator.createCustomMarkerIcon(
      iconPath: 'assets/icons/arrow_green.png',
      label: 'Green Marker',
      fontSize: 16, // Ubah ukuran teks di sini
      iconWidth: 40,
      iconHeight: 40,
      labelWidth: 80,
      labelHeight: 20,
    );

    redMarkerIcon = await CustomMarkerGenerator.createCustomMarkerIcon(
      iconPath: 'assets/icons/arrow_red.png',
      label: 'Red Marker',
      fontSize: 16, // Ubah ukuran teks di sini
      iconWidth: 40,
      iconHeight: 40,
      labelWidth: 80,
      labelHeight: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Map',
          style: TextStyle(
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
                vehicles.map(
                  (vehicle) => Marker(
                    markerId: MarkerId('${vehicle.vehicleId}'),
                    position: LatLng(vehicle.lat!, vehicle.lon!),
                    icon: vehicle.speed == 0 ? redMarkerIcon : greenMarkerIcon,
                    infoWindow: InfoWindow(
                      title: ("${vehicle.name}"),
                      snippet: ("${vehicle.name}"),
                    ),
                    rotation: vehicle.bearing?.toDouble() ?? 0.0,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class CustomMarkerGenerator {
  static Future<BitmapDescriptor> createCustomMarkerIcon({
    required String iconPath,
    required String label,
    required double fontSize,
    required double iconWidth,
    required double iconHeight,
    required double labelWidth,
    required double labelHeight,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final double totalWidth = iconWidth > labelWidth ? iconWidth : labelWidth;
    final double totalHeight = iconHeight + labelHeight;

    // Load icon image
    final ByteData data = await rootBundle.load(iconPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: iconWidth.toInt(),
      targetHeight: iconHeight.toInt(),
    );
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image iconImage = frameInfo.image;
    final Rect iconRect = Offset.zero & Size(iconWidth, iconHeight);
    canvas.drawImage(iconImage, Offset.zero, Paint());

    // Draw label text
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(fontSize: fontSize, color: Colors.black),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(minWidth: 0, maxWidth: totalWidth);
    textPainter.paint(
      canvas,
      Offset((totalWidth - textPainter.width) / 2, iconHeight),
    );

    // Convert canvas to image
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image markerAsImage = await picture.toImage(
      totalWidth.toInt(),
      totalHeight.toInt(),
    );
    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List markerAsBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(markerAsBytes);
  }
}

void main() {
  runApp(MaterialApp(
    home: HomeView(),
  ));
}

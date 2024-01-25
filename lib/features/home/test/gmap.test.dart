import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vehiloc/features/account/account.view.dart';
import 'package:vehiloc/core/utils/conts.dart';
import 'package:vehiloc/features/vehicles/vehicles.view.dart';

class LocationData {
  static List<Location> dataLocation = [
    Location(1, -6.98142, 110.40885, 'Udinus', 'Kampus'),
    Location(2, -7.00224, 110.44013, 'Ibos', 'Kantor'),
  ];
}

class PolygonData {
  static List<LatLng> polygonPoints = [
    LatLng(-6.98085, 110.40271),
    LatLng(-6.98397, 110.40866),
    LatLng(-6.97857, 110.41153),
    LatLng(-6.97832, 110.40717),
  ];
}

class Location {
  final int name;
  final double latitude;
  final double longitude;
  final String title;
  final String snippet;

  Location(this.name, this.latitude, this.longitude, this.title, this.snippet);
}

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
    MapScreen(locations: LocationData.dataLocation),
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
            color: Colors.white, fontWeight: FontWeight.bold),
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
  final List<Location> locations;

  const MapScreen({Key? key, required this.locations}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarker;
  late GoogleMapController mapController;

  final LatLng initialCenter = const LatLng(-7.00224, 110.44013);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Set<Marker> _createMarkers(List<Location> locations) {
  return locations.map((location) {
    return Marker(
      markerId: MarkerId(location.name.toString()),
      position: LatLng(location.latitude, location.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: location.title,
        snippet: location.snippet,
      ),
    );
  }).toSet();
}

  Set<Polygon> _createPolygon(List<LatLng> polygonPoints) {
    return {
      Polygon(
        polygonId: PolygonId("1"),
        points: polygonPoints,
        strokeWidth: 2,
        fillColor: Color(0xFF7D0A0A).withOpacity(0.2),
      ),
    };
  }

  Set<Polyline> _createPolylines(List<Location> locations) {
    List<LatLng> polylinePoints = locations
        .map((location) => LatLng(location.latitude, location.longitude))
        .toList();

    return {
      Polyline(
        polylineId: PolylineId("1"),
        points: polylinePoints,
        color: Colors.blue,
        width: 3,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Map',
            style: TextStyle(
              color: GlobalColor.textColor,
            ),
          ),
          backgroundColor: GlobalColor.mainColor,
        ),
        body: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialCenter,
            zoom: 15.0,
          ),
          onMapCreated: _onMapCreated,
          markers: _createMarkers(widget.locations),
          circles: {
            Circle(
              circleId: CircleId("1"),
              center: LatLng(-7.00224, 110.44013),
              radius: 430,
              strokeWidth: 2,
              fillColor: Color(0xFF7D0A0A).withOpacity(0.2),
            ),
          },
          polygons: _createPolygon(PolygonData.polygonPoints),
          polylines: _createPolylines(widget.locations),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: HomeView(),
  ));
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
                    markerId: MarkerId('${vehicle.name}'),
                    position: LatLng(vehicle.lat!, vehicle.lon!),
                  )),
                ),
              );
            }
          },
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

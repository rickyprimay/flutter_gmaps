import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:VehiLoc/core/model/response_vehicles.dart';
import 'package:VehiLoc/core/utils/colors.dart';
import 'package:VehiLoc/core/utils/vehicle_func.dart';
import 'package:VehiLoc/features/home/widget/map_screen.dart';
import 'package:VehiLoc/core/Api/api_provider.dart';
import 'package:VehiLoc/core/Api/api_service.dart';
import 'package:VehiLoc/features/vehicles/pages/details_page.dart';

class VehicleView extends StatefulWidget {
  const VehicleView({Key? key}) : super(key: key);

  @override
  _VehicleViewState createState() => _VehicleViewState();
}

class _VehicleViewState extends State<VehicleView> {
  final ApiService apiService = ApiService();
  late List<Vehicle> _allVehicles;
  late List<Vehicle> _filteredVehicles;
  late Map<String, List<Vehicle>> _groupedVehicles;
  bool _isLoading = false;
  String? tappedVehicle;
  int? _tappedVehicleIndex;
  final Map<Vehicle, String> _vehicleToAddress = {};

  @override
  void initState() {
    super.initState();
    _filteredVehicles = [];
    _allVehicles = [];
    _groupedVehicles = {};
    _fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void fetchGeocode(Vehicle vehicle) async {
    if (vehicle.lat != null && vehicle.lon != null) {
      final double? lat = vehicle.lat;
      final double? lon = vehicle.lon;
      try {
        final address = await apiService.fetchAddress(lat!, lon!);
        setState(() {
          _vehicleToAddress[vehicle] = address;
        });
      } catch (e) {
        print("error : $e");
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final List<Vehicle> vehicles = await ApiProvider().getApiResponse();
    if (mounted) {
      setState(() {
        _allVehicles = vehicles;
        _filteredVehicles = vehicles;
        _groupVehicles(vehicles);
        _isLoading = false;
      });
    }
  }

  void _groupVehicles(List<Vehicle> vehicles) {
    _groupedVehicles.clear();
    for (Vehicle vehicle in vehicles) {
      if (!_groupedVehicles.containsKey(vehicle.customerName)) {
        _groupedVehicles[vehicle.customerName!] = [];
      }
      _groupedVehicles[vehicle.customerName!]!.add(vehicle);
    }
  }

  void _filterVehicles(String query) {
    setState(() {
      _filteredVehicles = _allVehicles.where((vehicle) {
        final nameLower = vehicle.name?.toLowerCase() ?? '';
        final plateNoLower = vehicle.plateNo?.toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        return nameLower.contains(searchLower) ||
            plateNoLower.contains(searchLower);
      }).toList();
      _groupVehicles(_filteredVehicles);
    });
  }

  void _convertAndNavigateToDetailsPage(Vehicle vehicle) {
    DateTime gpsdtWIB;
    final DateTime now = DateTime.now();
    final DateTime gpsdtUtc = DateTime.fromMillisecondsSinceEpoch(
      vehicle.gpsdt! * 1000,
      isUtc: true,
    );

    if (gpsdtUtc.year == now.year &&
        gpsdtUtc.month == now.month &&
        gpsdtUtc.day == now.day) {
      gpsdtWIB = DateTime(now.year, now.month, now.day, 0, 0, 0);
    } else {
      gpsdtWIB = DateTime(gpsdtUtc.year, gpsdtUtc.month, gpsdtUtc.day, 0, 0, 0);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsPageView(
          vehicleId: vehicle.vehicleId!,
          vehicleLat: vehicle.lat!,
          vehicleLon: vehicle.lon!,
          vehicleName: vehicle.name!,
          gpsdt: gpsdtWIB.millisecondsSinceEpoch ~/ 1000,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: TextField(
            onChanged: _filterVehicles,
            style: TextStyle(color: GlobalColor.textColor),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: GlobalColor.textColor),
              border: InputBorder.none,
            ),
          ),
          backgroundColor: GlobalColor.mainColor,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      child: _isLoading && _allVehicles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _groupedVehicles.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _groupedVehicles.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                String customerName = _groupedVehicles.keys.elementAt(index);
                List<Vehicle> customerVehicles = _groupedVehicles[customerName]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Column(
                      children: customerVehicles.asMap().entries.map((entry) {
                        int vehicleIndex = entry.key;
                        Vehicle vehicle = entry.value;
                        DateTime? gpsdtWIB;
                        if (vehicle.gpsdt != null) {
                          DateTime gpsdtUtc =
                              DateTime.fromMillisecondsSinceEpoch(
                                  vehicle.gpsdt! * 1000, isUtc: true);
                          gpsdtWIB = gpsdtUtc.add(const Duration(hours: 7));
                        }

                        return Slidable(
                          actionPane: const SlidableDrawerActionPane(),
                          actionExtentRatio: 0.3,
                          actions: <Widget>[
                            IconSlideAction(
                              caption: 'Map',
                              color: GlobalColor.mainColor,
                              icon: Icons.map_outlined,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapScreen(
                                      lat: vehicle.lat!,
                                      lon: vehicle.lon!,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          secondaryActions: <Widget>[
                            IconSlideAction(
                              caption: 'Details',
                              color: GlobalColor.mainColor,
                              icon: Icons.book_online,
                              onTap: () {
                                _convertAndNavigateToDetailsPage(vehicle);
                              },
                            ),
                          ],
                          child: Card(
                            clipBehavior: Clip.hardEdge,
                            child: InkWell(
                              splashColor: Colors.grey.withAlpha(30),
                              onTap: () {
                                setState(() {
                                  fetchGeocode(vehicle);
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        title: Text(
                                          vehicle.name ?? '',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(4.0),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(4.0),
                                                child: Text(
                                                  vehicle.plateNo ?? '',
                                                  style: TextStyle(
                                                    color: GlobalColor.textColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (_vehicleToAddress.containsKey(vehicle)) // Tampilkan teks jika ada dalam Map
                                      Text(
                                        _vehicleToAddress[vehicle]!,
                                        style: TextStyle(
                                          color: GlobalColor.buttonColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                          ],
                                        ),
                                        leading: Column(
                                          children: [
                                            SizedBox(
                                              width: 60,
                                              height: vehicle.type == 4 ? 25 : 56,
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: getVehicleColor(
                                                      vehicle.speed ?? 0,
                                                      vehicle.gpsdt ?? 0),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment:MainAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        '${vehicle.speed ?? 0}',
                                                        style: TextStyle(
                                                          color: GlobalColor.textColor,
                                                          fontWeight:FontWeight.bold,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      if (vehicle.type != 4)
                                                        Align(
                                                          alignment:Alignment.center,
                                                          child: Text(
                                                            'KM/H',
                                                            style: TextStyle(
                                                              color: GlobalColor.textColor,
                                                              fontSize: 15,
                                                              fontWeight:FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (vehicle.type == 4)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Container(
                                                  width: 60,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.blue.shade200),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(4.0),
                                                      child: Text(
                                                        vehicle.baseMcc != null ? '${vehicle.baseMcc! / 10}°' : '',
                                                        style: TextStyle(
                                                          color: Colors.blue.shade200,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (gpsdtWIB != null)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0, top: 2),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              formatDateTime(gpsdtWIB),
                                              style: const TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                ...(vehicle.sensors?.take(2).map((sensor) {
                                                      return Padding(
                                                        padding: const EdgeInsets.only(right: 2, bottom: 2),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: getSensorColor(sensor.status),
                                                            borderRadius:BorderRadius.circular(5),
                                                          ),
                                                          child: Text(
                                                            sensor.name ?? '',
                                                            style: TextStyle(
                                                              color: GlobalColor.textColor,
                                                              fontSize: 8,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList() ?? []),
                                              ],
                                            ),
                                            if ((vehicle.sensors?.length ?? 0) > 2)
                                              Row(
                                                children: [
                                                ...(vehicle.sensors?.skip(2).take(2).map((sensor) {
                                                      return Padding(
                                                        padding:const EdgeInsets.only(right: 2, top: 3, bottom: 3),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: getSensorColor(sensor.status),
                                                            borderRadius: BorderRadius.circular(5),
                                                          ),
                                                          child: Text(sensor.name ?? '',
                                                            style: TextStyle(
                                                              color: GlobalColor.textColor,
                                                              fontSize: 8,
                                                              fontWeight:FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList() ?? []),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
    );
  }
}

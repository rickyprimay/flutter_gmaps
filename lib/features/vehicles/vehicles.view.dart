import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:VehiLoc/core/model/response_vehicles.dart';
import 'package:VehiLoc/core/utils/conts.dart';
import 'package:VehiLoc/features/home/home.view.dart';
import 'package:VehiLoc/features/vehicles/api/api_provider.dart';
import 'package:VehiLoc/features/vehicles/pages/details.page.dart';

class VehicleView extends StatefulWidget {
  @override
  _VehicleViewState createState() => _VehicleViewState();
}

class _VehicleViewState extends State<VehicleView> {
  late List<Vehicle> _allVehicles;
  late List<Vehicle> _filteredVehicles;
  late Map<String, List<Vehicle>> _groupedVehicles;
  bool _isLoading = false;

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

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    final List<Vehicle> vehicles = await ApiProvider().getApiResponse();
    setState(() {
      _allVehicles = vehicles;
      _filteredVehicles = vehicles;
      _groupVehicles(vehicles);
      _isLoading = false;
    });
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
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: TextStyle(color: Colors.white),
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
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _groupedVehicles.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _groupedVehicles.length) {
                  return Center(child: CircularProgressIndicator());
                }
                String customerName = _groupedVehicles.keys.elementAt(index);
                List<Vehicle> customerVehicles =
                    _groupedVehicles[customerName]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        customerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Column(
                      children: customerVehicles.map((vehicle) {
                        DateTime? gpsdtWIB;
                        if (vehicle.gpsdt != null) {
                          DateTime gpsdtUtc =
                              DateTime.fromMillisecondsSinceEpoch(
                                  vehicle.gpsdt! * 1000,
                                  isUtc: true);
                          gpsdtWIB = gpsdtUtc.add(Duration(hours: 7));
                        }

                        return Slidable(
                          actionPane: SlidableDrawerActionPane(),
                          actionExtentRatio: 0.3,
                          actions: <Widget>[
                            IconSlideAction(
                              caption: 'Map',
                              color: GlobalColor.mainColor,
                              icon: Icons.map_outlined,
                              onTap: () {
                                Navigator.pushReplacement(
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
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      title: Text(
                                        vehicle.name ?? '',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(2.0),
                                              child: Text(
                                                vehicle.plateNo ?? '',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      leading: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: _getVehicleColor(
                                              vehicle.speed ?? 0),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${vehicle.speed ?? 0}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              'KM/H',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (gpsdtWIB != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 8.0, top: 2),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Last Update : ${_formatDateTime(gpsdtWIB)}',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Row(
                                            children: [
                                              ...(vehicle.sensors
                                                      ?.take(2)
                                                      .map((sensor) {
                                                    return Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 2,
                                                          bottom:
                                                              2), // Menambahkan jarak atas dan bawah
                                                      child: Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              _getSensorColor(
                                                                  sensor
                                                                      .status),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        child: Text(
                                                          sensor.name ?? '',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 8,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }).toList() ??
                                                  []),
                                            ],
                                          ),
                                          if ((vehicle.sensors?.length ?? 0) >
                                              2)
                                            Row(
                                              children: [
                                                ...(vehicle.sensors
                                                        ?.skip(2)
                                                        .take(2)
                                                        .map((sensor) {
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                right: 2,
                                                                top: 3,
                                                                bottom: 3),
                                                        child: Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                _getSensorColor(
                                                                    sensor
                                                                        .status),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                          ),
                                                          child: Text(
                                                            sensor.name ?? '',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 8,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList() ??
                                                    []),
                                              ],
                                            ),
                                          if (vehicle.type == 4)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  right: 2,
                                                  top: 2,
                                                  bottom:
                                                      2), // Menambahkan jarak atas dan bawah
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 4,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.blue.shade200,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .end,
                                                      children: [
                                                        Text(
                                                          '${vehicle.baseMcc != null ? '${vehicle.baseMcc! / 10}°' : ''}',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 8,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10),
                  ],
                );
              },
            ),
    );
  }

  Color _getVehicleColor(int speed) {
    if (speed == 0) {
      return Colors.grey;
    } else if (speed > 0 && speed <= 60) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  Color _getSensorColor(String? status) {
    if (status == 'ON') {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return DateFormat.Hms().format(dateTime);
    } else {
      return DateFormat('yyyy-MM-dd').format(dateTime);
    }
  }
}

void main() {
  runApp(VehicleView());
}

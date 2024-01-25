import 'package:flutter/material.dart';
import 'package:vehiloc/core/utils/conts.dart';
import 'package:vehiloc/features/home/home.view.dart';
import 'package:vehiloc/features/vehicles/api/api_provider.dart';
import 'package:intl/intl.dart'; 
import 'package:vehiloc/core/model/response_vehicles.dart';

class VehicleView extends StatefulWidget {
  @override
  _VehicleViewState createState() => _VehicleViewState();
}

class _VehicleViewState extends State<VehicleView> {
  late List<Vehicle> _allVehicles;
  late List<Vehicle> _filteredVehicles;
  late Map<String, List<Vehicle>> _groupedVehicles;

  @override
  void initState() {
    super.initState();
    _filteredVehicles = [];
    _allVehicles = [];
    _groupedVehicles = {}; // Initialize grouped vehicles map
    _fetchData();
  }

  Future<void> _fetchData() async {
    final List<Vehicle> vehicles = await ApiProvider().getApiResponse();
    setState(() {
      _allVehicles = vehicles;
      _filteredVehicles = vehicles;
      _groupVehicles(vehicles);
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
        final nameLower = vehicle.name!.toLowerCase();
        final plateNoLower = vehicle.plateNo!.toLowerCase();
        final searchLower = query.toLowerCase();
        return nameLower.contains(searchLower) || plateNoLower.contains(searchLower);
      }).toList();
      _groupVehicles(_filteredVehicles); // Regroup filtered vehicles
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _buildBody() {
    if (_filteredVehicles.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      return ListView.builder(
        itemCount: _groupedVehicles.length,
        itemBuilder: (context, index) {
          String customerName = _groupedVehicles.keys.elementAt(index);
          List<Vehicle> customerVehicles = _groupedVehicles[customerName]!;

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
                children: customerVehicles
                    .map((vehicle) {
                  DateTime gpsdtUtc = DateTime.fromMillisecondsSinceEpoch(vehicle.gpsdt! * 1000, isUtc: true);
                  DateTime gpsdtWIB = gpsdtUtc.add(Duration(hours: 7)); 

                  return Card(
                    child: ListTile(
                      title: Text(vehicle.name!),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicle.plateNo!),
                          Text(
                            'Last Updated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(gpsdtWIB)} WIB',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _getVehicleColor(vehicle.speed!),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${vehicle.speed}',
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
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: PopupMenuButton(
                        icon: Icon(Icons.more_vert),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.map_outlined),
                              title: Text('Map'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeView(),
                                  ),
                                );
                              },
                            ),
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.book_online),
                              title: Text('Details'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeView(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Handle onTap event
                      },
                    ),
                  );
                })
                .toList(),
              ),
              SizedBox(height: 10),
            ],
          );
        },
      );
    }
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
}

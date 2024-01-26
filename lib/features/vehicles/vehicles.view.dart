import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:vehiloc/core/model/response_vehicles.dart';
import 'package:vehiloc/core/utils/conts.dart';
import 'package:vehiloc/features/home/home.view.dart';
import 'package:vehiloc/features/vehicles/api/api_provider.dart';
import 'package:vehiloc/features/vehicles/pages/details.page.dart';

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
    _groupedVehicles = {};
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
        final nameLower = vehicle.name?.toLowerCase() ?? '';
        final plateNoLower = vehicle.plateNo?.toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        return nameLower.contains(searchLower) ||
            plateNoLower.contains(searchLower);
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
                children: customerVehicles.map((vehicle) {
                  DateTime? gpsdtWIB;
                  if (vehicle.gpsdt != null) {
                    DateTime gpsdtUtc = DateTime.fromMillisecondsSinceEpoch(
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomeView(),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsPageView(),
                            ),
                          );
                        },
                      ),
                    ],
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Text(
                                  vehicle.name ?? '',
                                  style: TextStyle(fontSize: 12),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    color: _getVehicleColor(vehicle.speed ?? 0),
                                    borderRadius: BorderRadius.circular(5),
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
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  // Handle onTap event
                                },
                              ),
                            ),
                            if (gpsdtWIB != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  '${_formatDateTime(gpsdtWIB)}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
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
  runApp(MaterialApp(
    home: VehicleView(),
  ));
}

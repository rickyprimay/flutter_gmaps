class Vehicle {
  String? customerName;
  String? name;
  String? plateNo;
  int? gpsdt;
  int? speed;
  double? lat;
  double? lon;
  int? vehicleId;
  int? type;
  int? baseMcc;
  int? bearing;



  Vehicle({
    required this.customerName,
    required this.name,
    required this.plateNo,
    required this.gpsdt,
    this.speed = 0,
    required this.lat,
    required this.lon,
    required this.vehicleId,
    this.type,
    this.baseMcc,
    this.bearing
  });

  Vehicle.fromJson(Map<String, dynamic> json){
    customerName = json['customer_name'];
    name = json['name'];
    plateNo = json['plate_no'];
    gpsdt = json['gpsdt'];
    speed = json['speed'];
    lat = json['lat'];
    lon = json['lon'];
    vehicleId = json['vehicle_id'];
    type = json['type'];
    baseMcc = json ['base_mcc'];
    bearing = json['bearing'];
  }
}
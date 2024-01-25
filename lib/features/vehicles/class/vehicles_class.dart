class Vehicle {
  String? customerName;
  String? name;
  String? plateNo;
  int? gpsdt;
  int? speed;

  Vehicle({
    required this.customerName,
    required this.name,
    required this.plateNo,
    required this.gpsdt,
    this.speed = 0,
  });

  Vehicle.fromJson(Map<String, dynamic> json){
    customerName = json['customer_name'];
    name = json['name'];
    plateNo = json['plate_no'];
    gpsdt = json['gpsdt'];
    speed = json['speed'];
  }
}
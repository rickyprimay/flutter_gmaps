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
  List<Sensor>? sensors;

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
    this.bearing,
    this.sensors,
  });

  Vehicle.fromJson(Map<String, dynamic> json) {
    customerName = json['customer_name'];
    name = json['name'];
    plateNo = json['plate_no'];
    gpsdt = json['gpsdt'];
    speed = json['speed'];
    lat = json['lat'];
    lon = json['lon'];
    vehicleId = json['vehicle_id'];
    type = json['type'];
    baseMcc = json['base_mcc'];
    bearing = json['bearing'];
    if (json['sensors'] != null) {
      sensors = <Sensor>[];
      json['sensors'].forEach((v) {
        sensors!.add(new Sensor.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['customer_name'] = this.customerName;
    data['name'] = this.name;
    data['plate_no'] = this.plateNo;
    data['gpsdt'] = this.gpsdt;
    data['speed'] = this.speed;
    data['lat'] = this.lat;
    data['lon'] = this.lon;
    data['vehicle_id'] = this.vehicleId;
    data['type'] = this.type;
    data['base_mcc'] = this.baseMcc;
    data['bearing'] = this.bearing;
    if (this.sensors != null) {
      data['sensors'] = this.sensors!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Sensor {
  String? bgColor;
  String? name;
  String? status;

  Sensor({
    this.bgColor,
    this.name,
    this.status,
  });

  Sensor.fromJson(Map<String, dynamic> json) {
    bgColor = json['bgcolor'];
    name = json['name'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['bgcolor'] = this.bgColor;
    data['name'] = this.name;
    data['status'] = this.status;
    return data;
  }
}

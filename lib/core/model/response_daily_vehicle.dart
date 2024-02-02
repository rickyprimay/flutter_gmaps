class DailyData {
  final List<Daily> dailyList;
  final List<Jdetails> jDetailsList;
  final List<Inputlogs> inputLogsList;

  DailyData({
    required this.dailyList,
    required this.jDetailsList,
    required this.inputLogsList,
  });
}

class Daily {
  int? bearing;
  int? gpsdt;
  int? ioStates;
  double? latitude;
  double? longitude;
  int? speed;
  int? temp;

  Daily({
    required this.bearing,
    required this.gpsdt,
    required this.ioStates,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.temp,
  });

  Daily.fromJson(Map<String, dynamic> json) {
    bearing = json['bearing'];
    gpsdt = json['gpsdt'];
    ioStates = json['io_states'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    speed = json['speed'];
    temp = json['temp'];
  }
}

class Jdetails {
  int? distance;
  int? startdt;
  int? enddt;
  int? type;
  int? gfid;
  double? lat;
  double? lon;

  Jdetails({
    required this.distance,
    required this.startdt,
    required this.type,
    required this.enddt,
    required this.gfid,
    required this.lat,
    required this.lon,
  });

  Jdetails.fromJson(Map<String, dynamic> json) {
    distance = json['distance'];
    enddt = json['enddt'];
    startdt = json['startdt'];
    type = json['type'];
    gfid = json['gfid'];
    lat = json['lat'];
    lon = json['lon'];
  }
}

class Inputlogs {
  int? dt;
  int? inputNo;
  bool? newState;
  String? newStateBgcolor;
  String? newStateDesc;
  String? sensorName;
  int? vehicleId;

  Inputlogs(
      {required this.dt,
      required this.inputNo,
      required this.newState,
      required this.newStateBgcolor,
      required this.newStateDesc,
      required this.sensorName,
      required this.vehicleId});

  Inputlogs.fromJson(Map<String, dynamic> json) {
    dt = json['dt'];
    inputNo = json['input_no'];
    newState = json['new_state'];
    newStateBgcolor = json['new_state_bgcolor']; 
    newStateDesc = json['new_state_desc'];
    sensorName = json['sensor_name'];
    vehicleId = json['vehicle_id'];
  }
}

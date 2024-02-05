class Data {
  final List<DataItem> data;
  final List<InputLogsItem> inputlogs;
  final List<JdetailsItem> jdetails;

  Data({required this.data, required this.inputlogs, required this.jdetails});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      data: List<DataItem>.from(json['data'].map((x) => DataItem.fromJson(x))),
      inputlogs: List<InputLogsItem>.from(
          json['inputlogs'].map((x) => InputLogsItem.fromJson(x))),
      jdetails: List<JdetailsItem>.from(
          json['jdetails'].map((x) => JdetailsItem.fromJson(x))),
    );
  }
}

class DataItem {
  final int bearing;
  final int gpsdt;
  final int ioStates;
  final double latitude;
  final double longitude;
  final int speed;
  final int temp;

  DataItem({
    required this.bearing,
    required this.gpsdt,
    required this.ioStates,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.temp,
  });

  factory DataItem.fromJson(Map<String, dynamic> json) {
    return DataItem(
      bearing: json['bearing'],
      gpsdt: json['gpsdt'],
      ioStates: json['io_states'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      speed: json['speed'],
      temp: json['temp'],
    );
  }
}

class InputLogsItem {
  final int dt;
  final int inputNo;
  final bool newState;
  final String newStateBgcolor;
  final String newStateDesc;
  final String sensorName;
  final int vehicleId;

  InputLogsItem({
    required this.dt,
    required this.inputNo,
    required this.newState,
    required this.newStateBgcolor,
    required this.newStateDesc,
    required this.sensorName,
    required this.vehicleId,
  });

  factory InputLogsItem.fromJson(Map<String, dynamic> json) {
    return InputLogsItem(
      dt: json['dt'],
      inputNo: json['input_no'],
      newState: json['new_state'],
      newStateBgcolor: json['new_state_bgcolor'],
      newStateDesc: json['new_state_desc'],
      sensorName: json['sensor_name'],
      vehicleId: json['vehicle_id'],
    );
  }
}

class JdetailsItem {
  final double distance;
  final int enddt;
  final List<dynamic> geofences;
  final int gfid;
  final double lat;
  final double lon;
  final int startdt;
  final int type;

  JdetailsItem({
    required this.distance,
    required this.enddt,
    required this.geofences,
    required this.gfid,
    required this.lat,
    required this.lon,
    required this.startdt,
    required this.type,
  });

  factory JdetailsItem.fromJson(Map<String, dynamic> json) {
    return JdetailsItem(
      distance: json['distance']?.toDouble(),
      enddt: json['enddt'],
      geofences: json['geofences'],
      gfid: json['gfid'],
      lat: json['lat']?.toDouble(),
      lon: json['lon']?.toDouble(),
      startdt: json['startdt'],
      type: json['type'],
    );
  }
}

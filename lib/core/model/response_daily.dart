// class Daily {
//   List<Data>? data;
//   List<Inputlogs>? inputlogs;
//   List<Jdetails>? jdetails;

//   Daily({this.data, this.inputlogs, this.jdetails});

//   Daily.fromJson(Map<String, dynamic> json) {
//     if (json['data'] != null) {
//       data = <Data>[];
//       json['data'].forEach((v) {
//         data!.add(new Data.fromJson(v));
//       });
//     }
//     if (json['inputlogs'] != null) {
//       inputlogs = <Inputlogs>[];
//       json['inputlogs'].forEach((v) {
//         inputlogs!.add(new Inputlogs.fromJson(v));
//       });
//     }
//     if (json['jdetails'] != null) {
//       jdetails = <Jdetails>[];
//       json['jdetails'].forEach((v) {
//         jdetails!.add(new Jdetails.fromJson(v));
//       });
//     }
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     if (this.data != null) {
//       data['data'] = this.data!.map((v) => v.toJson()).toList();
//     }
//     if (this.inputlogs != null) {
//       data['inputlogs'] = this.inputlogs!.map((v) => v.toJson()).toList();
//     }
//     if (this.jdetails != null) {
//       data['jdetails'] = this.jdetails!.map((v) => v.toJson()).toList();
//     }
//     return data;
//   }
// }

// class Data {
//   int? bearing;
//   int? gpsdt;
//   int? ioStates;
//   double? latitude;
//   double? longitude;
//   int? speed;
//   int? temp;

//   Data(
//       {this.bearing,
//       this.gpsdt,
//       this.ioStates,
//       this.latitude,
//       this.longitude,
//       this.speed,
//       this.temp});

//   Data.fromJson(Map<String, dynamic> json) {
//     bearing = json['bearing'];
//     gpsdt = json['gpsdt'];
//     ioStates = json['io_states'];
//     latitude = json['latitude'];
//     longitude = json['longitude'];
//     speed = json['speed'];
//     temp = json['temp'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['bearing'] = this.bearing;
//     data['gpsdt'] = this.gpsdt;
//     data['io_states'] = this.ioStates;
//     data['latitude'] = this.latitude;
//     data['longitude'] = this.longitude;
//     data['speed'] = this.speed;
//     data['temp'] = this.temp;
//     return data;
//   }
// }

// class Inputlogs {
//   int? dt;
//   int? inputNo;
//   bool? newState;
//   String? newStateBgcolor;
//   String? newStateDesc;
//   String? sensorName;
//   int? vehicleId;

//   Inputlogs(
//       {this.dt,
//       this.inputNo,
//       this.newState,
//       this.newStateBgcolor,
//       this.newStateDesc,
//       this.sensorName,
//       this.vehicleId});

//   Inputlogs.fromJson(Map<String, dynamic> json) {
//     dt = json['dt'];
//     inputNo = json['input_no'];
//     newState = json['new_state'];
//     newStateBgcolor = json['new_state_bgcolor'];
//     newStateDesc = json['new_state_desc'];
//     sensorName = json['sensor_name'];
//     vehicleId = json['vehicle_id'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['dt'] = this.dt;
//     data['input_no'] = this.inputNo;
//     data['new_state'] = this.newState;
//     data['new_state_bgcolor'] = this.newStateBgcolor;
//     data['new_state_desc'] = this.newStateDesc;
//     data['sensor_name'] = this.sensorName;
//     data['vehicle_id'] = this.vehicleId;
//     return data;
//   }
// }

// class Jdetails {
//   int? distance;
//   int? enddt;
//   List<Null>? geofences;
//   int? gfid;
//   double? lat;
//   double? lon;
//   int? startdt;
//   int? type;

//   Jdetails(
//       {this.distance,
//       this.enddt,
//       this.geofences,
//       this.gfid,
//       this.lat,
//       this.lon,
//       this.startdt,
//       this.type});

//   Jdetails.fromJson(Map<String, dynamic> json) {
//     distance = json['distance'];
//     enddt = json['enddt'];
//     gfid = json['gfid'];
//     lat = json['lat'];
//     lon = json['lon'];
//     startdt = json['startdt'];
//     type = json['type'];
//   }

//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['distance'] = this.distance;
//     data['enddt'] = this.enddt;
//     data['gfid'] = this.gfid;
//     data['lat'] = this.lat;
//     data['lon'] = this.lon;
//     data['startdt'] = this.startdt;
//     data['type'] = this.type;
//     return data;
//   }
// }

  class Daily {
    int? bearing;
    int? gpsdt;
    int? ioStates;
    double? latitude;
    double? longitude;
    int? speed;
    int? temp;
    int? distance;

    Daily({
      required this.bearing,
      required this.gpsdt,
      required this.ioStates,
      required this.latitude,
      required this.longitude,
      required this.speed,
      required this.temp,
      required this.distance,
    });

    Daily.fromJson(Map<String, dynamic> json) {
      bearing = json['bearing'];
      gpsdt = json['gpsdt'];
      ioStates = json['io_states'];
      latitude = json['latitude'];
      longitude = json['longitude'];
      speed = json['speed'];
      temp = json['temp'];
      distance = json['distance'];
    }
  }

class Jdetails {
  int? distance;
  int? startdt;
  int? enddt;
  int? type;

  Jdetails({
    required this.distance,
    required this.startdt,
    required this.type
  });

  Jdetails.fromJson(Map<String, dynamic> json){
    distance = json['distance'];
    enddt = json['enddt'];
    startdt = json['startdt'];
    type = json['type'];
  }
}

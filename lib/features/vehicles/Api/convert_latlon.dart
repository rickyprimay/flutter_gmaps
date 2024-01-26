import 'package:google_maps_flutter/google_maps_flutter.dart' as GoogleMaps;
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> _getAddressFromLatLng(double lat, double lng) async {
  final apiKey = 'AIzaSyAHUi2mRexdvoQAJtrYpxb_MfMMKL3sXDE'; 
  final url =
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['status'] == 'OK') {
        final results = decoded['results'] as List<dynamic>;
        if (results.isNotEmpty) {
          final formattedAddress =
              results[0]['formatted_address'] as String;
          return formattedAddress;
        }
      }
    }
    return 'Reverse geocoding failed';
  } catch (e) {
    return 'Error: $e';
  }
}

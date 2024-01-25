import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:vehiloc/core/model/response_vehicles.dart';

class ApiService {
  final String baseUrl = "https://vehiloc.net/rest/";
  final Logger logger = Logger();

  Future<List<Vehicle>> fetchVehicles() async {
    final String apiUrl = "$baseUrl/vehicles";

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      final String username = prefs.getString('username') ?? "";
      final String password = prefs.getString('password') ?? "";

      if (username.isEmpty || password.isEmpty) {
        logger.e("Username or password not found");
        return [];
      }

      final String basicAuth =
          'Basic ' + base64Encode(utf8.encode('$username:$password'));

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        final List<Vehicle> vehicles = jsonResponse
            .map((vehicleJson) => Vehicle.fromJson(vehicleJson))
            .cast<Vehicle>()
            .toList();
        logger.i("API response: $jsonResponse");
        return vehicles;
      } else {
        logger.e("API request failed with status code: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      logger.e("Error during API request: $e");
      return [];
    }
  }
}

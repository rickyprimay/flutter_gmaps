import 'package:flutter/material.dart';
import 'package:vehiloc/core/model/response_vehicles.dart';
import 'package:vehiloc/features/vehicles/api/api_service.dart';

class ApiProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  late Future<List<Vehicle>> _apiResponse;

  Future<List<Vehicle>> getApiResponse() {
    _apiResponse = _apiService.fetchVehicles();
    return _apiResponse;
  }
}

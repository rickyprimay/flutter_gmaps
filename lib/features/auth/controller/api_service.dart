import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const baseUrl = 'https://vehiloc.net';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/rest/token'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login');
    }
  }
} 

import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthController {
  Future loginUser(String username, String password) async {
    final _url = "https://vehiloc.net/rest/token";

    var response = await http.post(Uri.parse(_url), body:{
      "username": username,
      "password": password,
    }); 

    if(response.statusCode == 200){
      var loginArr = json.decode(response.body);
      print(loginArr);
    }
    else {
      print('Login Error');
    }
  }
}
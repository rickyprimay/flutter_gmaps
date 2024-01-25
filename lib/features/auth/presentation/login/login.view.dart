import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehiloc/core/utils/conts.dart';
import 'package:vehiloc/features/auth/presentation/widget/form.login.dart';
import 'package:vehiloc/features/home/home.view.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false; 

  Future<void> _login() async {
    setState(() {
      isLoading = true; 
    });

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    final String basicAuth =
        'Basic ' + base64Encode(utf8.encode('$username:$password'));

    final String apiUrl = 'https://vehiloc.net/rest/token';

    try {
      final http.Response response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': basicAuth},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String token = data['token'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('token', token);

        prefs.setString('username', username);
        prefs.setString('password', password);

        await Future.delayed(Duration(seconds: 2));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeView()),
        );
      } else {
        print('Gagal login. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password atau Email salah. Silakan coba lagi.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      print('Error: $error');
    } finally {
      setState(() {
        isLoading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    'Vehiloc',
                    style: TextStyle(
                      color: GlobalColor.mainColor,
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                Text(
                  'Login ke akun anda',
                  style: TextStyle(
                    color: GlobalColor.mainColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),

                /// username Input
                TextFormLogin(
                  controller: _usernameController,
                  text: 'Username',
                  textInputType: TextInputType.text,
                  obscure: false,
                ),

                const SizedBox(
                  height: 10,
                ),

                /// Password
                TextFormLogin(
                  controller: _passwordController,
                  text: 'Password',
                  textInputType: TextInputType.text,
                  obscure: true,
                ),

                const SizedBox(
                  height: 15,
                ),

                Center(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    style: ButtonStyle(
                      minimumSize:
                          MaterialStateProperty.all(Size(400, 50)),
                      backgroundColor:
                          MaterialStateProperty.all(GlobalColor.mainColor),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      elevation: MaterialStateProperty.all(10),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

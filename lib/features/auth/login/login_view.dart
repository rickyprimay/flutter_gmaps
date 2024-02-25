import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:VehiLoc/core/utils/colors.dart';
import 'package:VehiLoc/features/auth/widget/form_login.dart';
import 'package:VehiLoc/features/map/widget/BottomBar.dart';
import 'package:logger/logger.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _checkTokenAndRedirect();
  }

  Future<void> _checkTokenAndRedirect() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomBar()),
      );
    } else {
      _fetchAndCacheCustomerSalts();
    }
  }

  Future<void> _fetchAndCacheCustomerSalts() async {
    const String apiUrl = 'https://vehiloc.net/rest/customer_salts';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? password = prefs.getString('password');

    if (username != null && password != null) {
      final String basicAuth =
          'Basic ' + base64Encode(utf8.encode('$username:$password'));

      try {
        final http.Response response = await http.get(
          Uri.parse(apiUrl),
          headers: {'Authorization': basicAuth},
        );

        if (response.statusCode == 200) {
          prefs.setString('customerSalts', response.body);
          logger.i('Customer Salts = ${response.body}');
        } else {
          logger.e(
              'Failed to fetch customer salts. Status code: ${response.statusCode}');
        }
      } catch (error) {
        logger.e('Error: $error');
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    final String basicAuth =
        'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    const String apiUrl = 'https://vehiloc.net/rest/token';

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

        _fetchAndCacheCustomerSalts();

        PersistentNavBarNavigator.pushDynamicScreen(
          context,
          screen: MaterialPageRoute(builder: (context) => BottomBar()),
          withNavBar: false,
        );
      } else {
        logger.e('Failed to login. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password atau Email salah. Silakan coba lagi.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      logger.e('Error: $error');
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
                    'VehiLoc',
                    style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
                    color: GlobalColor.mainColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                TextFormLogin(
                  controller: _usernameController,
                  text: 'Username',
                  textInputType: TextInputType.text,
                  obscure: false,
                ),
                const SizedBox(
                  height: 10,
                ),
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
                      minimumSize: MaterialStateProperty.all(Size(
                        MediaQuery.of(context).size.width * 1.0,
                        50,
                      )),
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
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            'Login',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Versi: 0.1.0',
                        style: GoogleFonts.poppins(
                          color: GlobalColor.mainColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'vehiloc.net',
                        style: GoogleFonts.poppins(
                          color: GlobalColor.mainColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

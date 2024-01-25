import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehiloc/features/auth/presentation/login/login.view.dart';
import 'package:vehiloc/features/home/home.view.dart';
import 'package:vehiloc/core/utils/conts.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    Widget nextPage = token != null ? HomeView() : LoginView();

    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => nextPage,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlobalColor.mainColor,
      body: Center(
        child: Image.asset(
          'assets/logo/vehiloc-logo-splash.png',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}

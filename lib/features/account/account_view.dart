import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:VehiLoc/core/utils/colors.dart';
import 'package:VehiLoc/features/account/widget/button_logout.dart';
import 'package:VehiLoc/features/auth/login/login_view.dart';

class AccountView extends StatelessWidget {
  const AccountView({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: GlobalColor.textColor,
          ),
        ),
        backgroundColor: GlobalColor.mainColor,
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: _getUsername(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              String username = snapshot.data ?? '';

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 100.0,
                    color: GlobalColor.mainColor,
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    username,
                    style: GoogleFonts.poppins(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     // Handle change password
                  //   },
                  //   style: ButtonStyle(
                  //     minimumSize: MaterialStateProperty.all(Size(
                  //       MediaQuery.of(context).size.width * 0.3,
                  //       50,
                  //     )),
                  //     backgroundColor:
                  //         MaterialStateProperty.all(GlobalColor.mainColor),
                  //     shape: MaterialStateProperty.all(
                  //       RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //     ),
                  //     elevation: MaterialStateProperty.all(10),
                  //   ),
                  //   child: Text(
                  //     'Ubah Password',
                  //     style: GoogleFonts.poppins(
                  //       textStyle: TextStyle(
                  //         color: GlobalColor.textColor,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 10.0),
                  ButtonLogout(
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      prefs.remove('token');
                      prefs.remove('username');
                      prefs.remove('customerSalts');

                      PersistentNavBarNavigator.pushNewScreen(context,
                          screen: const LoginView(),
                          withNavBar: false,
                          pageTransitionAnimation:
                              PageTransitionAnimation.fade);
                    },
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Future<String> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }
}

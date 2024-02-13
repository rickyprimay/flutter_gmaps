import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import the google_fonts package
import 'package:shared_preferences/shared_preferences.dart';
import 'package:VehiLoc/core/utils/conts.dart';
import 'package:VehiLoc/features/account/widget/button.logout.dart';
import 'package:VehiLoc/features/auth/presentation/login/login.view.dart';

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
            // Use GoogleFonts.poppins for Poppins font
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
                      // Use GoogleFonts.poppins for Poppins font
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  ButtonLogout(
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Konfirmasi Logout'),
                            content: Text('Apakah Anda yakin ingin logout?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  prefs.remove('token');

                                  Navigator.of(context).pop();
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => LoginView(),
                                    ),
                                  );
                                },
                                child: Text('Logout'),
                              ),
                            ],
                          );
                        },
                      );
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

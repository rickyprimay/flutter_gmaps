import 'package:flutter/material.dart';

class ButtonLogout extends StatelessWidget {
  const ButtonLogout({Key? key, required this.onPressed}) : super(key: key);

  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text('Log Out'),
    );
  }
}

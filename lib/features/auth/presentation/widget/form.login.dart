import "package:flutter/material.dart";

class TextFormLogin extends StatelessWidget{
  const TextFormLogin({ Key? key, required this.controller, required this.text, this.textInputType, required this.obscure, this.TextInputType,  }) : super(key: key);
  final TextEditingController controller;
  final String text;
  final TextInputType, textInputType;
  final bool obscure;


  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.only(top: 3, left: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 7,
          )
        ]
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: textInputType,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: text,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(0),
          hintStyle: const TextStyle(
            height: 1,
          ),
        ),
      ),
    );
  }
}
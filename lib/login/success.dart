import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
   return Container(
      color: const Color.fromRGBO(250, 250, 250, 1),
      child: const Center(
        child: Text(
          "Success Screen",
          style: TextStyle(
            fontSize: 24,
            color: Color.fromRGBO(0, 73, 145, 1),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
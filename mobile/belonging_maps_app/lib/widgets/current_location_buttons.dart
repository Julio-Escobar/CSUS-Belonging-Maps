import 'package:flutter/material.dart';

class CurrentLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CurrentLocationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: FloatingActionButton(
        backgroundColor: Color(0xFF2F5F3E),
        onPressed: onPressed,
        child: Icon(Icons.my_location),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const BelongingMapsApp());
}

class BelongingMapsApp extends StatelessWidget {
  const BelongingMapsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Belonging Maps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WelcomeScreen(), 
    );
  }
}
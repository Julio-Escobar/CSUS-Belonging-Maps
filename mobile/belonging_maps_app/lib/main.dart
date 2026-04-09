import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/campus_maps_screen.dart';
import 'screens/community_maps_directory.dart';
import 'screens/map_screen.dart';
import 'screens/demo_home_screen.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue),
      // Change home screen below to test different screens:
      home: const DemoHomeScreen(),  // Demo: Campus & Community Map buttons
      // home: WelcomeScreen(),
      // home: LoginScreen(),
      // home: CampusMapsScreen(),
      // home: CommunityMapsDirectory(),
      // home: MapScreen(),
    );
  }
}

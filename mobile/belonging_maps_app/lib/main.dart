import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/campus_maps_screen.dart';
import 'screens/community_maps_directory.dart';
import 'screens/map_screen.dart';
// import 'screens/test_organization_screen.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //TODO: Implement proper API key usage later
  ArcGISEnvironment.apiKey = '';
  
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
      // Change home screen below to test different screen quick test
      home: const WelcomeScreen(),
      // home: LoginScreen(),
      // home: CampusMapsScreen(),
      // home: CommunityMapsDirectory(),
      // home: MapScreen(),
      // home: TestOrganizationScreen(),
    );
  }
}

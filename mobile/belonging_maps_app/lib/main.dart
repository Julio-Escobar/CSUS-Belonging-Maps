import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/campus_maps_screen.dart';
import 'screens/community_maps_directory.dart';
import 'screens/map_screen.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //TODO: Implement proper API key usage later
  ArcGISEnvironment.apiKey = 'AAPTamDp9qu8ydJ1fbv0x4OoxlQ..8TFGYlnY8K8e7A8wrY1PCRZs8nQlfUFjIQwH_2PqfUuOKumnhlCCDDi8dTIZISzb3q7AzRVGdL74itVMnt9WYo1EhBizY3wkwhni_k_22PquyYlQei4aEeqYdbq7jsXnoaLew-Vh2FSYJJhASiRi8g7Nm9NKCjPg1oiov3ld1YFNFsa8RPbF0eVMxnbFf64OVTWpx2uy_UYlpxO3pZKJpzNlg5cL05HphmK3Cy2uFX_CdpqM1HEbAT1_Cbz29Ps5';
  
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
      //home: MapScreen(),
    );
  }
}

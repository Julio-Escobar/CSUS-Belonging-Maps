import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  
  final apiKey = dotenv.env['ARCGIS_API_KEY'] ?? '';
  ArcGISEnvironment.apiKey = apiKey;
  
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

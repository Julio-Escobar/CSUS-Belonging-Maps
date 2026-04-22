import 'package:belonging_maps_app/screens/campus_maps_screen.dart';
import 'package:belonging_maps_app/screens/community_maps_directory.dart';
import 'package:belonging_maps_app/screens/map_screen.dart';
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
    // detect path for web
    final uri = Uri.base;
    String initial = uri.path;
    if (initial == '/' || initial.isEmpty) {
      // if using hash routing (default for Flutter web) the fragment may hold the route
      if (uri.fragment.isNotEmpty) initial = uri.fragment;
    }
    if (initial.isEmpty) initial = '/';

    return MaterialApp(
      title: 'Belonging Maps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      initialRoute: initial,
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/campus': (context) => const CampusMapsScreen(),
        '/community': (context) => const CommunityMapsDirectory(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}

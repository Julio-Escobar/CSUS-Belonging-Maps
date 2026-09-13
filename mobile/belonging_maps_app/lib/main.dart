import 'package:belonging_maps_app/screens/accessibility_settings_screen.dart';
import 'package:belonging_maps_app/screens/opportunities.dart';
import 'package:belonging_maps_app/screens/campus_maps_screen.dart';
import 'package:belonging_maps_app/screens/community_maps_directory.dart';
import 'package:belonging_maps_app/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/accessibility_settings.dart';
import 'services/accessibility_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/about_us_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final apiKey = dotenv.env['ARCGIS_API_KEY'] ?? '';
  ArcGISEnvironment.apiKey = apiKey;

  final accessibilitySettings = await AccessibilitySettingsController.load();

  runApp(BelongingMapsApp(settings: accessibilitySettings));
}

class BelongingMapsApp extends StatelessWidget {
  final AccessibilitySettingsController settings;

  const BelongingMapsApp({super.key, required this.settings});

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

    return AccessibilitySettingsScope(
      controller: settings,
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) => MaterialApp(
          title: 'Belonging Maps',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(
            colorSafePalette: settings.colorSafePalette,
            highContrast: settings.highContrastFallback,
          ),
          highContrastTheme: AppTheme.light(
            colorSafePalette: settings.colorSafePalette,
            highContrast: true,
          ),
          initialRoute: initial,
          routes: {
            '/': (context) => const WelcomeScreen(),
            '/welcome': (context) => const WelcomeScreen(),
            '/campus': (context) => const CampusMapsScreen(),
            '/community': (context) => const CommunityMapsDirectory(),
            '/map': (context) => const MapScreen(),
            '/opportunities': (context) => const OpportunitiesScreen(),
            '/opportunites': (context) => const OpportunitiesScreen(),
            'opportunites': (context) => const OpportunitiesScreen(),
            '/accessibility-settings': (context) =>
                const AccessibilitySettingsScreen(),
            '/about': (context) => const AboutUsScreen(),
          },
        ),
      ),
    );
  }
}

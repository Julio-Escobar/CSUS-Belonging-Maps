import 'package:flutter/material.dart';

import '../constants/strings.dart';
import '../services/accessibility_theme.dart';
import '../widgets/hamburger_menu.dart';
import 'campus_maps_screen.dart';
import 'community_maps_directory.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: colors.cardBackground,
      foregroundColor: colors.primary,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );

    return HamburgerMenu(
      body: Scaffold(
        backgroundColor: colors.primary,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 200,
                    height: 200,
                    semanticLabel: 'Belonging Maps logo',
                  ),
                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Text(
                      AppStrings.welcomeDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      style: buttonStyle,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CampusMapsScreen(),
                        ),
                      ),
                      child: const Text(
                        'Campus Maps',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      style: buttonStyle,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommunityMapsDirectory(),
                        ),
                      ),
                      child: const Text(
                        'Community Maps',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

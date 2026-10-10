import 'package:flutter/material.dart';

import '../services/accessibility_theme.dart';
import '../widgets/map_selection_card.dart';
import 'somos_campus_map.dart';
import 'ummah_campus_map.dart';
import 'ubuntu_campus_map.dart';
import '../widgets/hamburger_menu.dart';

class CampusMapsScreen extends StatelessWidget {
  const CampusMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    final headingStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: colors.primary,
    );

    return HamburgerMenu(
      title: 'Campus Maps',
      body: Scaffold(
        backgroundColor: colors.pageBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text('Explore Our Campus', style: headingStyle),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a map to get started',
                  style: TextStyle(color: colors.secondaryText),
                ),
                const SizedBox(height: 28),
                MapSelectionCard(
                  label: 'SOMOS Campus Map',
                  subtitle: 'SOMOS Campus',
                  imagePath: 'assets/somosCampusMap.png',
                  logoPath: 'assets/somos_logo_temp.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SomosCampusMap()),
                  ),
                ),
                const SizedBox(height: 16),
                MapSelectionCard(
                  label: 'Ummah Campus Map',
                  subtitle: 'Ummah Campus',
                  imagePath: 'assets/ummahcampusmap.png',
                  logoPath: 'assets/ummah_logo_temp.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UmmahCampusMap()),
                  ),
                ),
                const SizedBox(height: 16),
                MapSelectionCard(
                  label: 'Ubuntu Campus Map',
                  subtitle: 'Ubuntu Campus',
                  imagePath: 'assets/ubuntucampusmap.png',
                  logoPath: 'assets/ubuntu_logo_temp.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UbuntuCampusMap()),
                  ),
                ),
                const SizedBox(height: 36),
                Semantics(
                  header: true,
                  child: Text('Explore Our Campus', style: headingStyle),
                ),
                const SizedBox(height: 20),
                MapSelectionCard(
                  label: 'SOMOS Campus Map',
                  subtitle: 'Mapping Our Campus',
                  imagePath: 'assets/somosCampusMap.png',
                  logoPath: 'assets/somos_logo_temp.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SomosCampusMap()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

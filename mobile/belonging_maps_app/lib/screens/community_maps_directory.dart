import 'package:flutter/material.dart';

import '../services/accessibility_theme.dart';
import '../widgets/map_selection_card.dart';
import 'somos_community_map.dart';
import 'ummah_community_map.dart';
import 'ubuntu_community_map.dart';
import '../widgets/hamburger_menu.dart';

class CommunityMapsDirectory extends StatelessWidget {
  const CommunityMapsDirectory({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    final headingStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: colors.primary,
    );
    final subtitleStyle = TextStyle(color: colors.secondaryText);

    return HamburgerMenu(
      title: 'Community Maps',
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
                  child: Text('Explore Community Maps', style: headingStyle),
                ),
                const SizedBox(height: 6),
                Text('Select a community to get started', style: subtitleStyle),
                const SizedBox(height: 28),
                MapSelectionCard(
                  label: 'SOMOS Community Map',
                  subtitle: 'SOMOS Community',
                  imagePath: 'assets/somoscommunityheader.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SomosCommunityMap()),
                  ),
                ),
                const SizedBox(height: 16),
                MapSelectionCard(
                  label: 'Ummah Community Map',
                  subtitle: 'Ummah Community',
                  imagePath: 'assets/ummahcommunityheader.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UmmahCommunityMap()),
                  ),
                ),
                const SizedBox(height: 16),
                MapSelectionCard(
                  label: 'Ubuntu Community Map',
                  subtitle: 'Ubuntu Community',
                  imagePath: 'assets/ubuntucommunityheader.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UbuntuCommunityMap()),
                  ),
                ),
                const SizedBox(height: 36),
                Semantics(
                  header: true,
                  child: Text(
                    'Explore Community Resource Maps',
                    style: headingStyle,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Select a community to get started', style: subtitleStyle),
                const SizedBox(height: 28),
                MapSelectionCard(
                  label: 'SOMOS Community Resource Map',
                  subtitle: 'SOMOS Community Resources',
                  imagePath: 'assets/somoscommunityheader.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SomosCommunityMap()),
                  ),
                ),
                const SizedBox(height: 16),
                MapSelectionCard(
                  label: 'Ummah Community Resources Map',
                  subtitle: 'Ummah Community Resources',
                  imagePath: 'assets/ummahcommunityheader.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UmmahCommunityMap()),
                  ),
                ),
                const SizedBox(height: 16),
                MapSelectionCard(
                  label: 'Ubuntu Community Resources Map',
                  subtitle: 'Ubuntu Community Resources',
                  imagePath: 'assets/ubuntucommunityheader.png',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UbuntuCommunityMap()),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

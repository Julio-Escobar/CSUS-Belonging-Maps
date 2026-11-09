import 'package:flutter/material.dart';

import '../services/accessibility_theme.dart';
import '../widgets/map_selection_card.dart';
import 'somos_community_map.dart';
import 'ummah_community_map.dart';
import 'ubuntu_community_map.dart';
import '../widgets/website_button.dart';

const String somosCommunityWebsiteUrl = 'https://storymaps.arcgis.com/stories/7d9f80e7c8de48449458800f1a45201c';
const String ummahCommunityWebsiteUrl = 'https://storymaps.arcgis.com/stories/0533e5adea024e10a69568c547544c07';
const String ubuntuCommunityWebsiteUrl = 'https://storymaps.arcgis.com/stories/1f6fb8b706b342c2b3421726f5542add';

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

    return Scaffold(
      backgroundColor: colors.pageBackground,
      appBar: AppBar(
        title: const Text(
          'Community Maps',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
                child: Text('Explore More', style: headingStyle),
              ),
              const SizedBox(height: 32),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: WebsiteCircleButton(
                      label: 'SOMOS',
                      logoPath: 'assets/somoscommunityemblem.png',
                      url: somosCommunityWebsiteUrl,
                      imageScale: 1.25,
                    ),
                  ),
                  Expanded(
                    child: WebsiteCircleButton(
                      label: 'Ummah',
                      logoPath: 'assets/ummahcommunityemblem.png',
                      url: ummahCommunityWebsiteUrl,
                      imageScale: 1.18,
                    ),
                  ),
                  Expanded(
                    child: WebsiteCircleButton(
                      label: 'Ubuntu',
                      logoPath: 'assets/ubuntucommunityemblem.png',
                      url: ubuntuCommunityWebsiteUrl,
                      imageScale: 1.33,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/accessibility_theme.dart';
import '../widgets/map_selection_card.dart';
import 'gender_neutral_bathrooms_map.dart';
import 'lactation_rooms_map.dart';
import 'somos_campus_map.dart';
import 'ummah_campus_map.dart';
import 'ubuntu_campus_map.dart';
import 'in_app_web_screen.dart';

const String interactiveCampusMapUrl =
    'https://map.csus.edu/?id=2324#!ct/103755,103756,103757,106981?s/';

const String somosWebsiteUrl =
    'https://storymaps.arcgis.com/stories/b91a49175ef142478dbc23ab9e4f3dc6';
const String ummahWebsiteUrl =
    'https://storymaps.arcgis.com/stories/e9236e47825c403983a35bb167adfd9d';
const String ubuntuWebsiteUrl =
    'https://storymaps.arcgis.com/stories/7dfddbf89e5b48e5a8a3509b26d25ed2';

class CampusMapsScreen extends StatelessWidget {
  const CampusMapsScreen({super.key});

  Future<void> _openInteractiveCampusMap(BuildContext context) async {
    var launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(interactiveCampusMapUrl),
        mode: LaunchMode.inAppBrowserView,
      );
    } catch (_) {
      launched = false;
    }

    if (!launched && context.mounted) {
      await _showMapErrorDialog(context);
    }
  }

  Future<void> _showMapErrorDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Unable to open the campus map'),
        content: const Text(
          "The interactive campus map couldn't be loaded. "
          'Check your internet connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _openInteractiveCampusMap(context);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    final headingStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: colors.primary,
    );

    return Scaffold(
      backgroundColor: colors.pageBackground,
      appBar: AppBar(
        title: const Text(
          'Campus Maps',
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
                child: Text('Explore Our Campus', style: headingStyle),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a map to get started',
                style: TextStyle(color: colors.secondaryText),
              ),
              const SizedBox(height: 20),
              Semantics(
                hint:
                    'Opens the interactive campus map in a browser in the app',
                child: ElevatedButton(
                  onPressed: () => _openInteractiveCampusMap(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.public),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Interactive Campus Map',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                hint: 'Opens the gender neutral bathrooms map',
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GenderNeutralBathroomsMap(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wc),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Gender Neutral Bathrooms',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                hint: 'Opens the lactation rooms map',
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LactationRoomsMap(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.child_care),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Lactation Rooms',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Divider(
                height: 1,
                thickness: 1,
                color: colors.outline.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 24),
              MapSelectionCard(
                label: 'SOMOS Campus Map',
                subtitle: 'SOMOS Campus',
                imagePath: 'assets/somoscampusmap.png',
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
                child: Text('Explore Storymaps', style: headingStyle),
              ),
              const SizedBox(height: 32),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CampusWebsiteButton(
                      label: 'SOMOS',
                      logoPath: 'assets/somoscampusemblem.png',
                      url: somosWebsiteUrl,
                      imageScale: 1.25,
                    ),
                  ),
                  Expanded(
                    child: _CampusWebsiteButton(
                      label: 'Ummah',
                      logoPath: 'assets/ummahcampusemblem.png',
                      url: ummahWebsiteUrl,
                      imageScale: 1.18,
                    ),
                  ),
                  Expanded(
                    child: _CampusWebsiteButton(
                      label: 'Ubuntu',
                      logoPath: 'assets/ubuntucampusemblem.png',
                      url: ubuntuWebsiteUrl,
                      imageScale: 1.33,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampusWebsiteButton extends StatelessWidget {
  final String label;
  final String logoPath;
  final String url;

  final double imageScale;

  const _CampusWebsiteButton({
    required this.label,
    required this.logoPath,
    required this.url,
    this.imageScale = 1.0,
  });

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppWebScreen(title: label, url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Semantics(
      button: true,
      label: 'Open $label website',
      onTap: () => _open(context),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: colors.cardBackground,
            elevation: 3,
            shape: CircleBorder(
              side: BorderSide(color: colors.primary, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(context),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Transform.scale(
                      scale: imageScale,
                      child: Image.asset(
                        logoPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Icon(Icons.public, color: colors.primary, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/accessibility_settings.dart';
import '../services/accessibility_theme.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AccessibilitySettingsScope.of(context);
    final mediaQuery = MediaQuery.of(context);
    final colors = AccessibilityColors.of(context);

    final detectedFeatures = <String>[
      if (mediaQuery.accessibleNavigation) 'Assistive navigation',
      if (mediaQuery.highContrast) 'Device high contrast',
      if (mediaQuery.boldText) 'Bold text',
      if (mediaQuery.invertColors) 'Inverted colors',
      if (mediaQuery.disableAnimations) 'Reduced motion',
    ];

    return Scaffold(
      backgroundColor: colors.pageBackground,
      appBar: AppBar(title: const Text('Accessibility Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Accessibility',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Belonging Maps follows your device's accessibility settings first. Use these options to adjust the app's colors and contrast for easier reading and navigation.",
            style: TextStyle(color: colors.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.palette_outlined, color: colors.action),
                  title: const Text('Color-safe palette'),
                  subtitle: const Text(
                    'Use labels, icons, and color together so the app never relies on color alone.',
                  ),
                  value: controller.colorSafePalette,
                  onChanged: controller.setColorSafePalette,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Icon(Icons.contrast, color: colors.action),
                  title: const Text('App high-contrast fallback'),
                  subtitle: Text(
                    mediaQuery.highContrast
                        ? "Your device's high-contrast setting is already on."
                        : 'Increase contrast throughout the app when your device does not provide a high-contrast setting.',
                  ),
                  value: controller.highContrastFallback,
                  onChanged: controller.setHighContrastFallback,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.record_voice_over, color: colors.action),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Screen reader support',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Chip(label: Text('Automatic')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belonging Maps works with Android TalkBack and iOS VoiceOver throughout the app. Turn screen readers on in your device\'s Accessibility settings; they are not controlled here.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _screenReaderGuidance(),
                    style: TextStyle(color: colors.secondaryText, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.devices_other, color: colors.action),
              title: const Text('Device accessibility features'),
              subtitle: Text(
                detectedFeatures.isEmpty
                    ? 'No additional device accessibility settings are currently being shared with the app.'
                    : detectedFeatures.join(' • '),
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset app accessibility settings'),
            onPressed: () => controller.reset(),
          ),
        ],
      ),
    );
  }

  String _screenReaderGuidance() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'On Android, go to Settings > Accessibility > TalkBack. Color correction and contrast options are available there too.';
      case TargetPlatform.iOS:
        return 'On iPhone or iPad, go to Settings > Accessibility > VoiceOver. Find Color Filters, Increase Contrast, and Differentiate Without Color under Display & Text Size.';
      default:
        return "Turn on a screen reader and other accessibility features in your device's Accessibility settings.";
    }
  }
}

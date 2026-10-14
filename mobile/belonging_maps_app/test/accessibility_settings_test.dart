import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/screens/accessibility_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads, persists, and resets app accessibility preferences', () async {
    SharedPreferences.setMockInitialValues({
      AccessibilitySettingsController.colorSafePaletteKey: true,
      AccessibilitySettingsController.highContrastFallbackKey: true,
    });

    final preferences = await SharedPreferences.getInstance();
    final controller = AccessibilitySettingsController(preferences);

    expect(controller.colorSafePalette, isTrue);
    expect(controller.highContrastFallback, isTrue);

    await controller.setColorSafePalette(false);
    expect(
      preferences.getBool(AccessibilitySettingsController.colorSafePaletteKey),
      isFalse,
    );

    await controller.reset();
    expect(controller.colorSafePalette, isFalse);
    expect(controller.highContrastFallback, isFalse);
    expect(
      preferences.containsKey(
        AccessibilitySettingsController.colorSafePaletteKey,
      ),
      isFalse,
    );
    expect(
      preferences.containsKey(
        AccessibilitySettingsController.highContrastFallbackKey,
      ),
      isFalse,
    );
  });

  test('device high contrast is additive to the app fallback', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AccessibilitySettingsController(preferences);

    expect(
      controller.effectiveHighContrast(
        const MediaQueryData(highContrast: true),
      ),
      isTrue,
    );

    await controller.setHighContrastFallback(true);
    expect(controller.effectiveHighContrast(const MediaQueryData()), isTrue);
  });

  testWidgets('settings controls update and persist immediately', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AccessibilitySettingsController(preferences);

    await tester.pumpWidget(
      MaterialApp(
        home: AccessibilitySettingsScope(
          controller: controller,
          child: const AccessibilitySettingsScreen(),
        ),
      ),
    );

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pump();

    expect(controller.colorSafePalette, isTrue);
    expect(
      preferences.getBool(AccessibilitySettingsController.colorSafePaletteKey),
      isTrue,
    );
  });
}

import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AccessibilityColors> _pumpWithBrightness(
  WidgetTester tester,
  Brightness brightness,
) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  late AccessibilityColors colors;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(colorSafePalette: false, highContrast: false),
      darkTheme: AppTheme.dark(colorSafePalette: false, highContrast: false),
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          colors = AccessibilityColors.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return colors;
}

void main() {
  testWidgets(
    'uses the dark palette when the device is in dark mode (P1-281)',
    (tester) async {
      final colors = await _pumpWithBrightness(tester, Brightness.dark);
      expect(
        colors.pageBackground,
        AccessibilityColors.normalDark.pageBackground,
      );
    },
  );

  testWidgets('uses the light palette when the device is in light mode', (
    tester,
  ) async {
    final colors = await _pumpWithBrightness(tester, Brightness.light);
    expect(colors.pageBackground, AccessibilityColors.normal.pageBackground);
  });

  test('dark themes report dark brightness', () {
    for (final colorSafe in [false, true]) {
      for (final highContrast in [false, true]) {
        final theme = AppTheme.dark(
          colorSafePalette: colorSafe,
          highContrast: highContrast,
        );
        expect(theme.brightness, Brightness.dark);
      }
    }
  });
}

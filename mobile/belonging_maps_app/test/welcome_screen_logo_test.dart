import 'package:belonging_maps_app/screens/welcome_screen.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _artwork = 'assets/belonging_maps_logo.png';

Future<String> _welcomeLogoAsset(
  WidgetTester tester, {
  required bool colorSafe,
  bool dark = false,
  bool highContrast = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark
          ? AppTheme.dark(
              colorSafePalette: colorSafe,
              highContrast: highContrast,
            )
          : AppTheme.light(
              colorSafePalette: colorSafe,
              highContrast: highContrast,
            ),
      home: const WelcomeScreen(),
    ),
  );
  await tester.pumpAndSettle();

  final image = tester.widget<Image>(find.byType(Image));
  return (image.image as AssetImage).assetName;
}

void main() {
  testWidgets('shows the belonging maps logo', (tester) async {
    expect(await _welcomeLogoAsset(tester, colorSafe: false), _artwork);
  });

  for (final colorSafe in [false, true]) {
    for (final dark in [false, true]) {
      for (final highContrast in [false, true]) {
        testWidgets('shows the belonging maps logo with colorSafe=$colorSafe '
            'dark=$dark highContrast=$highContrast', (tester) async {
          expect(
            await _welcomeLogoAsset(
              tester,
              colorSafe: colorSafe,
              dark: dark,
              highContrast: highContrast,
            ),
            _artwork,
          );
        });
      }
    }
  }

  test('every palette records whether the color safe option is on', () {
    for (final dark in [false, true]) {
      for (final highContrast in [false, true]) {
        for (final colorSafe in [false, true]) {
          final colors = AccessibilityColors.forSettings(
            colorSafePalette: colorSafe,
            highContrast: highContrast,
            dark: dark,
          );
          expect(
            colors.colorSafePalette,
            colorSafe,
            reason:
                'colorSafe=$colorSafe highContrast=$highContrast dark=$dark',
          );
        }
      }
    }
  });
}

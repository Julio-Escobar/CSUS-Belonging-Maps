import 'package:belonging_maps_app/screens/welcome_screen.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _defaultArtwork = 'assets/belonging_maps_no_text.png';
const _goldArtwork = 'assets/belonging_maps_no_text_gold.png';

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
  testWidgets('shows the text-free belonging maps artwork', (tester) async {
    expect(await _welcomeLogoAsset(tester, colorSafe: false), _defaultArtwork);
  });

  testWidgets('the color safe palette swaps in the gold artwork', (
    tester,
  ) async {
    expect(await _welcomeLogoAsset(tester, colorSafe: true), _goldArtwork);
  });

  for (final dark in [false, true]) {
    for (final highContrast in [false, true]) {
      testWidgets(
        'shows the gold artwork with color safe in dark=$dark '
        'highContrast=$highContrast',
        (tester) async {
          expect(
            await _welcomeLogoAsset(
              tester,
              colorSafe: true,
              dark: dark,
              highContrast: highContrast,
            ),
            _goldArtwork,
          );
        },
      );

      testWidgets(
        'keeps the default artwork without color safe in dark=$dark '
        'highContrast=$highContrast',
        (tester) async {
          expect(
            await _welcomeLogoAsset(
              tester,
              colorSafe: false,
              dark: dark,
              highContrast: highContrast,
            ),
            _defaultArtwork,
          );
        },
      );
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

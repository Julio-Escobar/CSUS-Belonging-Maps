import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('opens Surveys from the hamburger menu', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AccessibilitySettingsController(preferences);

    await tester.pumpWidget(
      AccessibilitySettingsScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.light(colorSafePalette: false, highContrast: false),
          home: HamburgerMenu(body: const Scaffold(body: SizedBox.expand())),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Surveys'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Surveys'), findsOneWidget);
  });
}

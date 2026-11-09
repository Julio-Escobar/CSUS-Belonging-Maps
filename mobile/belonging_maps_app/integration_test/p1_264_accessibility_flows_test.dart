import 'package:belonging_maps_app/screens/campus_maps_screen.dart';
import 'package:belonging_maps_app/screens/welcome_screen.dart';
import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/widgets/map_selection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Welcome opens the campus map directory and returns with Back', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final settings = AccessibilitySettingsController(preferences);

    await tester.pumpWidget(
      AccessibilitySettingsScope(
        controller: settings,
        child: MaterialApp(
          theme: AppTheme.light(colorSafePalette: false, highContrast: false),
          home: const WelcomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Belonging Maps logo'), findsOneWidget);
    expect(find.bySemanticsLabel('Campus Maps'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Campus Maps'));
    await tester.pumpAndSettle();
    expect(find.byType(CampusMapsScreen), findsOneWidget);
    expect(find.byType(MapSelectionCard), findsWidgets);
    expect(
      find.bySemanticsLabel('Ummah Campus Map. Ummah Campus'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}

import 'package:belonging_maps_app/screens/surveys_screen.dart';
import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpSurveys(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final controller = AccessibilitySettingsController(preferences);

  await tester.pumpWidget(
    AccessibilitySettingsScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light(colorSafePalette: false, highContrast: false),
        home: const SurveysScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => AuthService.isAdmin = false);

  testWidgets('shows the Feedback and What is Missing survey buttons', (
    tester,
  ) async {
    await _pumpSurveys(tester);

    expect(
      find.widgetWithText(ElevatedButton, 'Feedback Survey'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ElevatedButton, 'What is Missing Survey'),
      findsOneWidget,
    );
  });

  testWidgets('hides the add survey button from non-admins', (tester) async {
    AuthService.isAdmin = false;
    await _pumpSurveys(tester);

    expect(find.byTooltip('Add survey'), findsNothing);
  });

  testWidgets('admin can add a survey from the plus icon popup', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    await _pumpSurveys(tester);

    await tester.tap(find.byTooltip('Add survey'));
    await tester.pumpAndSettle();

    expect(find.text('Add Survey'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Survey Name'),
      'Campus Climate Survey',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Survey Link'),
      'https://example.com/climate',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Add Survey'), findsNothing);
    expect(
      find.widgetWithText(ElevatedButton, 'Campus Climate Survey'),
      findsOneWidget,
    );
  });

  testWidgets('add survey popup rejects a missing name and bad link', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    await _pumpSurveys(tester);

    await tester.tap(find.byTooltip('Add survey'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Survey Link'),
      'not a link',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a survey name'), findsOneWidget);
    expect(
      find.text('Enter a full link starting with https://'),
      findsOneWidget,
    );
    expect(find.text('Add Survey'), findsOneWidget);
  });
}

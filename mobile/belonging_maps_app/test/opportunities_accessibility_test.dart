import 'package:belonging_maps_app/screens/opportunities.dart';
import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpOpportunities(
    WidgetTester tester, {
    bool highContrast = false,
    double textScale = 1.0,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AccessibilitySettingsController(preferences);

    await tester.pumpWidget(
      AccessibilitySettingsScope(
        controller: controller,
        child: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScale),
            highContrast: highContrast,
          ),
          child: MaterialApp(
            theme: AppTheme.light(
              colorSafePalette: false,
              highContrast: highContrast,
            ),
            home: const OpportunitiesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('exposes opportunity cards and admin actions semantically', (
    tester,
  ) async {
    await pumpOpportunities(tester);

    expect(find.bySemanticsLabel(RegExp('SOMOS Scholarships')), findsOneWidget);
    expect(find.byTooltip('Edit SOMOS Scholarships'), findsOneWidget);
    expect(find.byTooltip('Delete SOMOS Scholarships'), findsOneWidget);
    expect(find.byTooltip('Add opportunity'), findsOneWidget);
    expect(find.byTooltip('Accessibility settings'), findsNothing);
  });

  testWidgets('opens the add opportunity dialog from the app bar', (
    tester,
  ) async {
    await pumpOpportunities(tester);

    await tester.tap(find.byTooltip('Add opportunity'));
    await tester.pumpAndSettle();

    expect(find.text('Add Opportunity'), findsOneWidget);
  });

  testWidgets('opens opportunity details through its semantic action', (
    tester,
  ) async {
    await pumpOpportunities(tester);

    await tester.tap(find.bySemanticsLabel(RegExp('SOMOS Scholarships')));
    await tester.pumpAndSettle();

    expect(find.text('SOMOS Scholarships'), findsNWidgets(2));
    final linkSemantics = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Open Chicana Latina',
      skipOffstage: false,
    );
    expect(linkSemantics, findsOneWidget);
    expect(
      tester.widget<Semantics>(linkSemantics).properties.label,
      'Open Chicana Latina',
    );
  });

  testWidgets('retains content at larger text and high contrast settings', (
    tester,
  ) async {
    await pumpOpportunities(tester, highContrast: true, textScale: 1.8);

    expect(find.text('SOMOS Scholarships'), findsOneWidget);
    expect(find.text('Ummah Scholarships'), findsOneWidget);
    expect(find.text('Ubuntu Scholarships'), findsOneWidget);
  });
}

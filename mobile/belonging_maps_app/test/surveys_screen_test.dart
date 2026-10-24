import 'dart:convert';

import 'package:belonging_maps_app/screens/surveys_screen.dart';
import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/semantics_finders.dart';

Future<void> _pumpSurveys(WidgetTester tester, {http.Client? client}) async {
  dotenv.loadFromString(envString: 'API_BASE_URL=http://example.test:5162');
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final controller = AccessibilitySettingsController(preferences);

  await tester.pumpWidget(
    AccessibilitySettingsScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light(colorSafePalette: false, highContrast: false),
        home: SurveysScreen(client: client ?? _surveysClient()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

http.Client _surveysClient({int getStatus = 200}) {
  const surveys = [
    {
      'id': 1,
      'title': 'Feedback Survey',
      'description': 'Tell us how the Belonging Maps app is working for you.',
      'link': 'https://example.com/feedback',
    },
    {
      'id': 2,
      'title': 'What is Missing Survey',
      'description':
          'Let us know about places, organizations, or resources we should add.',
      'link': 'https://example.com/missing',
    },
  ];

  return MockClient((request) async {
    if (request.method == 'GET') {
      return http.Response(jsonEncode(surveys), getStatus);
    }
    if (request.method == 'DELETE') return http.Response('', 200);

    final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
    body['id'] = request.method == 'POST'
        ? 99
        : int.parse(request.url.pathSegments.last);
    return http.Response(jsonEncode(body), 200);
  });
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
    final semantics = tester.ensureSemantics();
    AuthService.isAdmin = true;
    await _pumpSurveys(tester);

    tester.semantics.tap(semanticTapByTooltip('Add survey'));
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
    semantics.dispose();
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

  testWidgets('hides edit and delete from non-admins', (tester) async {
    AuthService.isAdmin = false;
    await _pumpSurveys(tester);

    expect(find.byTooltip('Edit Feedback Survey'), findsNothing);
    expect(find.byTooltip('Delete Feedback Survey'), findsNothing);
  });

  testWidgets('admin can edit a survey', (tester) async {
    final semantics = tester.ensureSemantics();
    AuthService.isAdmin = true;
    await _pumpSurveys(tester);

    tester.semantics.tap(semanticTapByTooltip('Edit Feedback Survey'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Survey'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Survey Name'),
      'App Feedback',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'App Feedback'), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, 'Feedback Survey'),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('admin can delete a survey after confirming', (tester) async {
    final semantics = tester.ensureSemantics();
    AuthService.isAdmin = true;
    await _pumpSurveys(tester);

    tester.semantics.tap(semanticTapByTooltip('Delete Feedback Survey'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(ElevatedButton, 'Feedback Survey'),
      findsNothing,
    );
    expect(
      find.widgetWithText(ElevatedButton, 'What is Missing Survey'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('shows an error when surveys cannot be loaded', (tester) async {
    await _pumpSurveys(tester, client: _surveysClient(getStatus: 500));

    expect(
      find.text('Could not load surveys. Please try again.'),
      findsOneWidget,
    );
  });
}

import 'dart:convert';

import 'package:belonging_maps_app/screens/organization_resources_screen.dart';
import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpOrganizationResources(
  WidgetTester tester, {
  required http.Client client,
}) async {
  dotenv.loadFromString(envString: 'API_BASE_URL=http://example.test:5162');
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final controller = AccessibilitySettingsController(preferences);

  await tester.pumpWidget(
    AccessibilitySettingsScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light(colorSafePalette: false, highContrast: false),
        home: OrganizationResourcesScreen(key: UniqueKey(), client: client),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

http.Client _resourceClient(
  List<Map<String, dynamic>> resources,
  List<String> methods, {
  int getStatus = 200,
  int writeStatus = 200,
}) {
  var nextId =
      resources
          .map((resource) => resource['id'] as int)
          .fold(0, (highest, id) => id > highest ? id : highest) +
      1;

  return MockClient((request) async {
    methods.add(request.method);

    if (request.method == 'GET') {
      return http.Response(jsonEncode(resources), getStatus);
    }
    if (writeStatus != 200) return http.Response('', writeStatus);
    if (request.method == 'POST') {
      final resource = Map<String, dynamic>.from(
        jsonDecode(request.body) as Map,
      )..['id'] = nextId++;
      resources.add(resource);
      return http.Response(jsonEncode(resource), 200);
    }
    if (request.method == 'PUT') {
      final id = int.parse(request.url.pathSegments.last);
      final index = resources.indexWhere((resource) => resource['id'] == id);
      final resource = Map<String, dynamic>.from(
        jsonDecode(request.body) as Map,
      )..['id'] = id;
      resources[index] = resource;
      return http.Response(jsonEncode(resource), 200);
    }
    if (request.method == 'DELETE') {
      final id = int.parse(request.url.pathSegments.last);
      resources.removeWhere((resource) => resource['id'] == id);
      return http.Response('', 200);
    }

    return http.Response('', 405);
  });
}

void main() {
  tearDown(() => AuthService.isAdmin = false);

  testWidgets('admin CRUD persists and appears after a fresh load', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    final methods = <String>[];
    final resources = <Map<String, dynamic>>[
      {
        'id': 1,
        'title': 'SOMOS Student Organization',
        'category': 'SOMOS',
        'description': 'Resources for SOMOS community members.',
        'iconKey': 'groups',
        'orgKey': 'somos',
      },
    ];
    final client = _resourceClient(resources, methods);

    await _pumpOrganizationResources(tester, client: client);
    expect(find.text('SOMOS Student Organization'), findsOneWidget);
    expect(methods, ['GET']);

    await tester.tap(find.byTooltip('Add resource'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Ubuntu Resource',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Category'),
      'Ubuntu',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Initial description',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Ubuntu Resource'), findsOneWidget);
    expect(methods, ['GET', 'POST']);

    await tester.tap(find.byTooltip('Edit Ubuntu Resource'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Ubuntu Updated Resource',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Update'));
    await tester.pumpAndSettle();

    expect(find.text('Ubuntu Updated Resource'), findsOneWidget);
    expect(methods, ['GET', 'POST', 'PUT']);

    await tester.tap(find.byTooltip('Delete Ubuntu Updated Resource'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Ubuntu Updated Resource'), findsNothing);
    expect(methods, ['GET', 'POST', 'PUT', 'DELETE']);

    await _pumpOrganizationResources(tester, client: client);
    expect(find.text('SOMOS Student Organization'), findsOneWidget);
    expect(find.text('Ubuntu Updated Resource'), findsNothing);
    expect(methods, ['GET', 'POST', 'PUT', 'DELETE', 'GET']);
  });

  testWidgets('shows an error when resource requests fail', (tester) async {
    final methods = <String>[];
    final client = _resourceClient([], methods, getStatus: 500);

    await _pumpOrganizationResources(tester, client: client);
    expect(
      find.text('Could not load organization resources. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an error when adding a resource fails', (tester) async {
    AuthService.isAdmin = true;
    final methods = <String>[];
    final client = _resourceClient([], methods, writeStatus: 500);

    await _pumpOrganizationResources(tester, client: client);
    await tester.tap(find.byTooltip('Add resource'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Failed Resource',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Category'),
      'SOMOS',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Not saved',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not add the organization resource. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Failed Resource'), findsNothing);
  });
}

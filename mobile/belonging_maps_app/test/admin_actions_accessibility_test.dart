import 'dart:convert';

import 'package:belonging_maps_app/screens/community_resources_screen.dart';
import 'package:belonging_maps_app/screens/login_screen.dart';
import 'package:belonging_maps_app/screens/organization_resources_screen.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'helpers/fake_community_resources_api.dart';
import 'helpers/semantics_finders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Client _organizationResourcesClient() {
  final resources = <Map<String, dynamic>>[
    {
      'id': 1,
      'title': 'SOMOS Student Organization',
      'category': 'SOMOS',
      'description': 'Student support and community events.',
      'iconKey': 'groups',
      'orgKey': 'somos',
    },
  ];

  return MockClient((request) async {
    if (request.method == 'GET') {
      return http.Response(jsonEncode(resources), 200);
    }

    final id = int.tryParse(request.url.pathSegments.last);
    final index = resources.indexWhere((resource) => resource['id'] == id);
    if (index == -1) return http.Response('', 404);

    if (request.method == 'PUT') {
      final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
      body['id'] = id;
      resources[index] = body;
      return http.Response(jsonEncode(body), 200);
    }
    if (request.method == 'DELETE') {
      resources.removeAt(index);
      return http.Response('', 200);
    }
    return http.Response('', 405);
  });
}

void main() {
  setUp(() {
    useFakeCommunityResourcesApi();
    dotenv.loadFromString(envString: 'API_BASE_URL=http://fake-api');
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => AuthService.isAdmin = false);

  testWidgets(
    'community resource view, edit, and delete are separate actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      AuthService.isAdmin = true;
      await tester.pumpWidget(
        const MaterialApp(home: CommunityResourcesScreen()),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('View information for Food Pantry')),
        findsOneWidget,
      );
      expect(find.byTooltip('Edit Food Pantry'), findsOneWidget);
      expect(find.byTooltip('Delete Food Pantry'), findsOneWidget);
      tester.semantics.tap(
        semanticTapByLabel(RegExp('^View information for Food Pantry')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Resource information'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('named resource edit and delete actions open their own flows', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    AuthService.isAdmin = true;

    await tester.pumpWidget(
      const MaterialApp(home: CommunityResourcesScreen()),
    );
    await tester.pumpAndSettle();
    tester.semantics.tap(semanticTapByTooltip('Edit Food Pantry'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Resource'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    tester.semantics.tap(semanticTapByTooltip('Delete Food Pantry'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Resource'), findsOneWidget);
    tester.semantics.tap(semanticTapByLabel('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Food Pantry'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationResourcesScreen(
          client: _organizationResourcesClient(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.semantics.tap(
      semanticTapByTooltip('Edit SOMOS Student Organization'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit Resource'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    tester.semantics.tap(
      semanticTapByTooltip('Delete SOMOS Student Organization'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete Resource'), findsOneWidget);
    tester.semantics.tap(semanticTapByLabel('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('SOMOS Student Organization'), findsNothing);
    semantics.dispose();
  });

  testWidgets('organization resource actions are named for the item', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    AuthService.isAdmin = true;
    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationResourcesScreen(
          client: _organizationResourcesClient(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        RegExp('View information for SOMOS Student Organization'),
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Edit SOMOS Student Organization'), findsOneWidget);
    expect(find.byTooltip('Delete SOMOS Student Organization'), findsOneWidget);
    tester.semantics.tap(
      semanticTapByTooltip('Edit SOMOS Student Organization'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Edit Resource'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('non-admin users cannot reach resource admin actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CommunityResourcesScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip(RegExp(r'^Edit ')), findsNothing);
    expect(find.byTooltip(RegExp(r'^Delete ')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationResourcesScreen(
          client: _organizationResourcesClient(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip(RegExp(r'^Edit ')), findsNothing);
    expect(find.byTooltip(RegExp(r'^Delete ')), findsNothing);
  });

  testWidgets('unfinished map-editing menu entries have no action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    AuthService.isAdmin = true;
    await tester.pumpWidget(
      const MaterialApp(home: HamburgerMenu(body: SizedBox.expand())),
    );
    tester.semantics.tap(semanticTapByTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    for (final title in ['Edit Maps', 'Add Location', 'Delete Entries']) {
      final tile = tester.widget<ListTile>(
        find.ancestor(of: find.text(title), matching: find.byType(ListTile)),
      );
      expect(tile.enabled, isFalse);
      expect(tile.onTap, isNull);
    }
    expect(find.text('Logout'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the named login action submits the entered credentials', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:5162');
    Map<String, dynamic>? sentBody;
    final client = MockClient((request) async {
      sentBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('', 401);
    });
    await tester.pumpWidget(MaterialApp(home: LoginScreen(client: client)));
    expect(find.bySemanticsLabel(RegExp('Username')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Password')), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'student');
    await tester.enterText(find.byType(TextField).at(1), 'secret');

    tester.semantics.tap(semanticTapByLabel('Login'));
    await tester.pumpAndSettle();
    expect(sentBody?['username'], 'student');
    expect(sentBody?['password'], 'secret');
    expect(find.text('Invalid credentials'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('logout action clears admin access', (tester) async {
    final semantics = tester.ensureSemantics();
    AuthService.isAdmin = true;
    await tester.pumpWidget(
      const MaterialApp(home: HamburgerMenu(body: SizedBox.expand())),
    );
    tester.semantics.tap(semanticTapByTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    tester.semantics.tap(semanticTapByLabel('Logout'));
    await tester.pumpAndSettle();
    expect(AuthService.isAdmin, isFalse);
    expect(find.text('Campus Maps'), findsWidgets);
    semantics.dispose();
  });
}

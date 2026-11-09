import 'dart:convert';

import 'package:belonging_maps_app/screens/opportunities.dart';
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

http.Client _opportunitiesClient({int getStatus = 200}) {
  const resources = [
    {
      'id': 1,
      'title': 'SOMOS Scholarships',
      'category': 'SOMOS',
      'description':
          'List of scholarships and opportunities for SOMOS, Ummah, and Ubuntu students.',
      'iconKey': 'book',
      'links': [
        {'name': 'Chicana Latina', 'url': 'https://example.com/chicana'},
      ],
    },
    {
      'id': 2,
      'title': 'Ummah Scholarships',
      'category': 'Ummah',
      'description':
          'List of scholarships and opportunities for Ummah students.',
      'iconKey': 'book',
      'links': [],
    },
    {
      'id': 3,
      'title': 'Ubuntu Scholarships',
      'category': 'Ubuntu',
      'description':
          'List of scholarships and opportunities for Ubuntu students.',
      'iconKey': 'book',
      'links': [],
    },
  ];

  return MockClient((request) async {
    if (request.method == 'GET') {
      return http.Response(jsonEncode(resources), getStatus);
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
  Future<void> pumpOpportunities(
    WidgetTester tester, {
    http.Client? client,
    bool highContrast = false,
    double textScale = 1.0,
  }) async {
    AuthService.isAdmin = true;
    addTearDown(() => AuthService.isAdmin = false);
    dotenv.loadFromString(envString: 'API_BASE_URL=http://example.test:5162');
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final controller = AccessibilitySettingsController(preferences);

    await tester.pumpWidget(
      AccessibilitySettingsScope(
        controller: controller,
        child: MediaQuery(
          data: MediaQueryData.fromView(tester.view).copyWith(
            textScaler: TextScaler.linear(textScale),
            highContrast: highContrast,
          ),
          child: MaterialApp(
            theme: AppTheme.light(
              colorSafePalette: false,
              highContrast: highContrast,
            ),
            home: OpportunitiesScreen(client: client ?? _opportunitiesClient()),
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
    expect(find.byTooltip('View opportunity details'), findsNWidgets(3));
    expect(find.byTooltip('Accessibility settings'), findsNothing);
  });

  testWidgets('opens the add opportunity dialog from the app bar', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpOpportunities(tester);

    tester.semantics.tap(semanticTapByTooltip('Add opportunity'));
    await tester.pumpAndSettle();

    expect(find.text('Add Opportunity'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('opens opportunity details through its semantic action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpOpportunities(tester);

    tester.semantics.tap(semanticTapByLabel(RegExp('^SOMOS Scholarships')));
    await tester.pumpAndSettle();

    expect(find.text('SOMOS Scholarships'), findsNWidgets(2));
    expect(
      find.text(
        'List of scholarships and opportunities for SOMOS, Ummah, and Ubuntu students.',
      ),
      findsNWidgets(2),
    );
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
    semantics.dispose();
  });

  testWidgets('shows a matching suggestion and opens its opportunity', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpOpportunities(tester);

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, '  chicana latina  ');
    await tester.pumpAndSettle();

    expect(find.text('1 opportunity found'), findsOneWidget);
    expect(find.text('SOMOS Scholarships'), findsNWidgets(2));
    expect(find.text('Ummah Scholarships'), findsNothing);
    expect(find.text('Ubuntu Scholarships'), findsNothing);
    expect(find.byTooltip('Clear opportunity search'), findsOneWidget);

    tester.semantics.tap(
      semanticTapByLabel(RegExp('^Open SOMOS Scholarships, SOMOS\$')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chicana Latina'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'combines category and keyword filters and recovers from no results',
    (tester) async {
      await pumpOpportunities(tester);

      await tester.enterText(find.byType(TextField), 'scholarships');
      await tester.pumpAndSettle();
      expect(find.text('3 opportunities found'), findsOneWidget);

      final somosFilter = find.byWidgetPredicate(
        (widget) =>
            widget is ChoiceChip &&
            widget.label is Text &&
            (widget.label as Text).data == 'SOMOS',
      );
      await tester.tap(somosFilter);
      await tester.pumpAndSettle();
      expect(find.text('1 opportunity found'), findsOneWidget);
      expect(find.text('SOMOS Scholarships'), findsNWidgets(2));
      expect(find.text('Ummah Scholarships'), findsNothing);

      await tester.enterText(find.byType(TextField), 'no matching opportunity');
      await tester.pumpAndSettle();
      expect(find.text('No opportunities found.'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('3 opportunities found'), findsOneWidget);
      expect(find.text('SOMOS Scholarships'), findsOneWidget);
      expect(find.text('Ummah Scholarships'), findsOneWidget);
      expect(find.text('Ubuntu Scholarships'), findsOneWidget);
    },
  );

  testWidgets('named edit and delete actions affect the matching opportunity', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpOpportunities(tester);

    tester.semantics.tap(semanticTapByTooltip('Edit SOMOS Scholarships'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Opportunity'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'SOMOS Scholarships',
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    tester.semantics.tap(semanticTapByTooltip('Delete SOMOS Scholarships'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Opportunity'), findsOneWidget);
    tester.semantics.tap(semanticTapByLabel('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('SOMOS Scholarships'), findsNothing);
    expect(find.text('Opportunity deleted'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('retains content at larger text and high contrast settings', (
    tester,
  ) async {
    await pumpOpportunities(tester, highContrast: true, textScale: 1.8);

    expect(find.text('SOMOS Scholarships'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ummah Scholarships'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Ummah Scholarships'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ubuntu Scholarships'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Ubuntu Scholarships'), findsOneWidget);
  });

  testWidgets('shows an error when opportunities cannot be loaded', (
    tester,
  ) async {
    await pumpOpportunities(
      tester,
      client: _opportunitiesClient(getStatus: 500),
    );

    expect(
      find.text('Could not load opportunities. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('hides expired links by default and orders visible deadlines', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final today = DateTime.now();
    String date(DateTime value) =>
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'id': 1,
            'title': 'Expired opportunity',
            'description': 'This must stay available to admins only.',
            'category': 'SOMOS',
            'iconKey': 'book',
            'links': [
              {
                'name': 'Expired link',
                'url': 'https://example.com/expired',
                'deadline': date(today.subtract(const Duration(days: 1))),
              },
            ],
          },
          {
            'id': 2,
            'title': 'No-deadline opportunity',
            'description': 'This belongs after dated opportunities.',
            'category': 'SOMOS',
            'iconKey': 'book',
            'links': [
              {'name': 'Undated link', 'url': 'https://example.com/undated'},
            ],
          },
          {
            'id': 3,
            'title': 'Current opportunity',
            'description': 'This must remain visible today.',
            'category': 'SOMOS',
            'iconKey': 'book',
            'links': [
              {
                'name': 'Current link',
                'url': 'https://example.com/current',
                'deadline': date(today),
              },
            ],
          },
          {
            'id': 4,
            'title': 'Soon opportunity',
            'description': 'This belongs first.',
            'category': 'SOMOS',
            'iconKey': 'book',
            'links': [
              {
                'name': 'Soon link',
                'url': 'https://example.com/soon',
                'deadline': date(today.add(const Duration(days: 1))),
              },
            ],
          },
          {
            'id': 5,
            'title': 'Later opportunity',
            'description': 'This belongs after the soon deadline.',
            'category': 'SOMOS',
            'iconKey': 'book',
            'links': [
              {
                'name': 'Later link',
                'url': 'https://example.com/later',
                'deadline': date(today.add(const Duration(days: 14))),
              },
            ],
          },
        ]),
        200,
      );
    });

    await pumpOpportunities(tester, client: client);

    expect(find.text('Expired opportunity'), findsNothing);
    expect(find.textContaining('Deadline:'), findsNWidgets(3));
    expect(
      tester.getTopLeft(find.text('Current opportunity')).dy,
      lessThan(tester.getTopLeft(find.text('Soon opportunity')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Soon opportunity')).dy,
      lessThan(tester.getTopLeft(find.text('Later opportunity')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Later opportunity')).dy,
      lessThan(tester.getTopLeft(find.text('No-deadline opportunity')).dy),
    );

    await tester.tap(find.text('Include expired opportunities'));
    await tester.pumpAndSettle();
    expect(find.text('Expired opportunity'), findsOneWidget);
  });

  testWidgets('admin saves and clears a link deadline', (tester) async {
    Map<String, dynamic>? savedOpportunity;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return http.Response(
          jsonEncode([
            {
              'id': 7,
              'title': 'Editor deadline opportunity',
              'description': 'Tests deadline changes from the editor.',
              'category': 'SOMOS',
              'iconKey': 'book',
              'links': [
                {'name': 'Apply', 'url': 'https://example.com/apply'},
              ],
            },
          ]),
          200,
        );
      }

      savedOpportunity = Map<String, dynamic>.from(
        jsonDecode(request.body) as Map,
      );
      savedOpportunity!['id'] = 7;
      return http.Response(jsonEncode(savedOpportunity), 200);
    });
    final deadlineField = find.byKey(
      const ValueKey('opportunity-link-deadline-0'),
    );

    await pumpOpportunities(tester, client: client);
    await tester.tap(find.byTooltip('Edit Editor deadline opportunity'));
    await tester.pumpAndSettle();
    await tester.enterText(deadlineField, '2026-12-15');
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(savedOpportunity!['links'][0]['deadline'], '2026-12-15');

    await tester.tap(find.byTooltip('Edit Editor deadline opportunity'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(deadlineField).controller!.text,
      '2026-12-15',
    );
    await tester.enterText(deadlineField, '');
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(savedOpportunity!['links'][0]['deadline'], isNull);
  });
}

import 'package:belonging_maps_app/screens/community_resources_screen.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'helpers/fake_community_resources_api.dart';
import 'helpers/semantics_finders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeCommunityResourcesApi api;

  setUp(() => api = useFakeCommunityResourcesApi());
  tearDown(() => AuthService.isAdmin = false);

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CommunityResourcesScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens Community Resources from the hamburger menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HamburgerMenu(body: const Scaffold(body: SizedBox.expand())),
      ),
    );

    final semantics = tester.ensureSemantics();
    tester.semantics.tap(semanticTapByTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    tester.semantics.tap(semanticTapByLabel('Community Resources'));
    await tester.pumpAndSettle();

    expect(find.text('Food Pantry'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('shows a loading spinner, then resources from the API', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CommunityResourcesScreen()),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Food Pantry'), findsOneWidget);
    expect(find.text('Mental Health Services'), findsOneWidget);
  });

  testWidgets('lists resources and shows selected resource information', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Food Pantry'));
    await tester.pumpAndSettle();

    expect(find.text('Resource information'), findsOneWidget);
    expect(
      find.text(
        'Free food resources available for students and community members.',
      ),
      findsNWidgets(2),
    );

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Resource information'), findsNothing);
  });

  testWidgets('shows an error with Retry when loading fails', (tester) async {
    api.failRequests = true;
    await pumpScreen(tester);

    expect(find.text("Couldn't load community resources"), findsOneWidget);
    expect(find.text('Food Pantry'), findsNothing);

    api.failRequests = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load community resources"), findsNothing);
    expect(find.text('Food Pantry'), findsOneWidget);
  });

  testWidgets('admin can open the add resource dialog', (tester) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    final semantics = tester.ensureSemantics();
    expect(find.byTooltip('Add resource'), findsOneWidget);

    tester.semantics.tap(semanticTapByTooltip('Add resource'));
    await tester.pumpAndSettle();

    expect(find.text('Add Resource'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('admin adds a resource and it is saved to the API', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Add resource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Book Exchange');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Trade used textbooks with other students.',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Education');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Resource added'), findsOneWidget);
    expect(api.resources.map((r) => r['title']), contains('Book Exchange'));

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Book Exchange'), findsOneWidget);
  });

  testWidgets('a resource added on one device shows up on another', (
    tester,
  ) async {
    // "Device A" adds a resource straight through the API.
    AuthService.isAdmin = true;
    await pumpScreen(tester);
    await tester.tap(find.byTooltip('Add resource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Legal Aid');
    await tester.enterText(find.byType(TextFormField).at(1), 'Free legal help.');
    await tester.enterText(find.byType(TextFormField).at(2), 'Legal');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    // "Device B" opens the screen fresh and loads from the same backend.
    AuthService.isAdmin = false;
    await tester.pumpWidget(const SizedBox());
    await pumpScreen(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.text('Legal Aid'), findsOneWidget);
  });

  testWidgets('admin can edit a resource', (tester) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Edit Food Pantry'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Resource'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Updated Food Pantry',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Updated community food access',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Wellness');

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Food Pantry'), findsOneWidget);
    expect(find.text('Resource updated'), findsOneWidget);
    expect(api.resources.first['title'], 'Updated Food Pantry');
  });

  testWidgets('admin can delete a resource after confirmation', (tester) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    expect(find.text('Food Pantry'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete Food Pantry'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Resource'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete this resource?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Resource deleted'), findsOneWidget);
    expect(find.text('Food Pantry'), findsNothing);
    expect(api.resources.any((r) => r['title'] == 'Food Pantry'), isFalse);
  });

  testWidgets('a failed save shows an error and keeps the list', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    api.failRequests = true;
    await tester.tap(find.byTooltip('Delete Food Pantry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't delete the resource"), findsOneWidget);
    expect(find.text('Food Pantry'), findsOneWidget);
  });
}

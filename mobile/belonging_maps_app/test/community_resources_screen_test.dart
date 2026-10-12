import 'package:belonging_maps_app/screens/community_resources_screen.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'helpers/semantics_finders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('lists resources and shows selected resource information', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CommunityResourcesScreen()),
    );

    expect(find.text('Food Pantry'), findsOneWidget);
    expect(find.text('Mental Health Services'), findsOneWidget);

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

  testWidgets('admin can open the add resource dialog', (tester) async {
    AuthService.isAdmin = true;
    addTearDown(() => AuthService.isAdmin = false);

    await tester.pumpWidget(
      const MaterialApp(home: CommunityResourcesScreen()),
    );

    final semantics = tester.ensureSemantics();
    expect(find.byTooltip('Add resource'), findsOneWidget);

    tester.semantics.tap(semanticTapByTooltip('Add resource'));
    await tester.pumpAndSettle();

    expect(find.text('Add Resource'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('admin can edit a resource', (tester) async {
    AuthService.isAdmin = true;
    addTearDown(() => AuthService.isAdmin = false);

    await tester.pumpWidget(
      const MaterialApp(home: CommunityResourcesScreen()),
    );

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
  });

  testWidgets('admin can delete a resource after confirmation', (tester) async {
    AuthService.isAdmin = true;
    addTearDown(() => AuthService.isAdmin = false);

    await tester.pumpWidget(
      const MaterialApp(home: CommunityResourcesScreen()),
    );

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
  });
}

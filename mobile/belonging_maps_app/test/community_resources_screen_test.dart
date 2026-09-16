import 'package:belonging_maps_app/screens/community_resources_screen.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
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

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Community Resources'));
    await tester.pumpAndSettle();

    expect(find.text('Food Pantry'), findsOneWidget);
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

    expect(find.byIcon(Icons.post_add_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.post_add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Add Resource'), findsOneWidget);
  });

  testWidgets('admin can edit a resource', (tester) async {
    AuthService.isAdmin = true;
    addTearDown(() => AuthService.isAdmin = false);

    await tester.pumpWidget(
      const MaterialApp(home: CommunityResourcesScreen()),
    );

    await tester.tap(find.byTooltip('Edit resource').first);
    await tester.pumpAndSettle();

    expect(find.text('Edit Resource'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Updated Food Pantry');
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
    await tester.tap(find.byTooltip('Delete resource').first);
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

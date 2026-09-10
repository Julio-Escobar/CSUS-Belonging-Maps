import 'package:belonging_maps_app/screens/community_resources_screen.dart';
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
}

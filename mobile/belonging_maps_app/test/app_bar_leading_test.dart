import 'package:belonging_maps_app/screens/about_us_screen.dart';
import 'package:belonging_maps_app/screens/campus_maps_screen.dart';
import 'package:belonging_maps_app/screens/community_maps_directory.dart';
import 'package:belonging_maps_app/screens/favorites_screen.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'package:belonging_maps_app/widgets/location_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Maps keep a back button in the top-left; every other page keeps the
// navigation menu there.

Widget _app(Widget home) {
  return MaterialApp(
    theme: AppTheme.light(colorSafePalette: false, highContrast: false),
    home: home,
  );
}

void main() {
  testWidgets('map pages show a back button instead of the menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const HamburgerMenu(
          title: 'Test Map',
          showBackButton: true,
          body: SizedBox.expand(),
        ),
      ),
    );

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('the map back button returns to the previous page', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const HamburgerMenu(
                    title: 'Test Map',
                    showBackButton: true,
                    body: SizedBox.expand(),
                  ),
                ),
              ),
              child: const Text('Open map'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Open map'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('directory pages keep the navigation menu', (tester) async {
    for (final page in [
      const CampusMapsScreen(),
      const CommunityMapsDirectory(),
    ]) {
      await tester.pumpWidget(_app(page));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Open navigation menu'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    }
  });

  testWidgets('location details use a back button', (tester) async {
    final data = LocationInfoData(
      id: 'student-center-42',
      cardTitle: 'Student Center',
      address: '6000 J Street',
      category: 'Campus Centers',
      type: 'Student services',
      website: '',
      phone: '',
      email: '',
      description: 'A place for students.',
      imageUrl: null,
      socialLinks: const {},
    );

    await tester.pumpWidget(
      _app(LocationFavoriteDetailsScreen(data: data)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets('drawer navigation replaces the page it was opened from', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const HamburgerMenu(body: SizedBox.expand())),
    );

    await _openDrawerItem(tester, 'About Us');
    expect(find.byType(AboutUsScreen), findsOneWidget);

    await _openDrawerItem(tester, 'Campus Maps');
    expect(find.byType(CampusMapsScreen), findsOneWidget);
    // The previous destination was removed instead of stacking behind it.
    expect(find.byType(AboutUsScreen), findsNothing);

    // Back from the destination returns to the root page.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CampusMapsScreen), findsNothing);
    expect(find.byType(HamburgerMenu), findsOneWidget);
  });

  testWidgets('tapping the current destination does not push a duplicate', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const HamburgerMenu(body: SizedBox.expand())),
    );

    await _openDrawerItem(tester, 'About Us');
    expect(find.byType(AboutUsScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    final currentTileFinder = find.widgetWithText(ListTile, 'About Us');
    final currentTile = tester.widget<ListTile>(currentTileFinder);
    expect(currentTile.selected, isTrue);
    await tester.ensureVisible(currentTileFinder);
    await tester.pumpAndSettle();
    await tester.tap(currentTileFinder);
    await tester.pumpAndSettle();
    expect(find.byType(AboutUsScreen), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
  });
}

Future<void> _openDrawerItem(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Open navigation menu'));
  await tester.pumpAndSettle();
  final tile = find.widgetWithText(ListTile, label);
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

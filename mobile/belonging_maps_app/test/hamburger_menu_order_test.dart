import 'package:belonging_maps_app/screens/campus_maps_screen.dart';
import 'package:belonging_maps_app/screens/community_maps_directory.dart';
import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// P1-334: map destinations are grouped at the top of the menu and still
// route to the same screens, in the same visual and screen-reader order.

const _expectedOrder = [
  'Campus Maps',
  'Community Maps',
  'Welcome',
  'Community Resources',
  'Organization Resources',
  'Opportunities',
  'Favorites',
  'Forums',
  'Surveys',
  'Accessibility Settings',
  'Administrator Login',
  'About Us',
];

Future<void> _pumpMenu(WidgetTester tester, {double textScale = 1}) async {
  final preferences = await SharedPreferences.getInstance();
  final controller = AccessibilitySettingsController(preferences);

  await tester.pumpWidget(
    AccessibilitySettingsScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light(colorSafePalette: false, highContrast: false),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: HamburgerMenu(body: const Scaffold(body: SizedBox.expand())),
      ),
    ),
  );
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

/// Menu item labels in the order the drawer lays them out top to bottom.
List<String> _visualOrder(WidgetTester tester) {
  final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
  final labels = <String, double>{};
  for (final tile in tiles) {
    final title = tile.title;
    if (title is! Text || title.data == null) continue;
    final y = tester.getTopLeft(find.byWidget(tile)).dy;
    labels[title.data!] = y;
  }
  final sorted = labels.keys.toList()
    ..sort((a, b) => labels[a]!.compareTo(labels[b]!));
  return sorted;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.isAdmin = false;
  });

  testWidgets('maps are grouped together at the top of the menu', (
    tester,
  ) async {
    await _pumpMenu(tester);

    final order = _visualOrder(tester);
    expect(order, _expectedOrder);
    expect(order.take(2), ['Campus Maps', 'Community Maps']);
  });

  testWidgets('screen-reader order matches the visual order at 200% text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpMenu(tester, textScale: 2);

    expect(_visualOrder(tester), _expectedOrder);

    // Walk the semantics tree in traversal order and keep the menu labels.
    final labels = <String>[];
    void visit(SemanticsNode node) {
      final label = node.label;
      if (_expectedOrder.contains(label) && !labels.contains(label)) {
        labels.add(label);
      }
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    visit(tester.getSemantics(find.byType(HamburgerMenu)));
    expect(labels, _expectedOrder);
    semantics.dispose();
  });

  testWidgets('Campus Maps still opens the campus maps screen', (tester) async {
    await _pumpMenu(tester);
    await tester.tap(find.text('Campus Maps'));
    await tester.pumpAndSettle();
    expect(find.byType(CampusMapsScreen), findsOneWidget);
  });

  testWidgets('Community Maps still opens the community maps directory', (
    tester,
  ) async {
    await _pumpMenu(tester);
    await tester.tap(find.text('Community Maps'));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityMapsDirectory), findsOneWidget);
  });

  testWidgets('admins see Change Password in the admin panel (P1-331)', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    addTearDown(() => AuthService.isAdmin = false);
    await _pumpMenu(tester);

    expect(find.text('Change Password'), findsOneWidget);
    expect(_visualOrder(tester).take(2), ['Campus Maps', 'Community Maps']);
  });

  testWidgets('non-admins do not see Change Password', (tester) async {
    await _pumpMenu(tester);
    expect(find.text('Change Password'), findsNothing);
  });
}

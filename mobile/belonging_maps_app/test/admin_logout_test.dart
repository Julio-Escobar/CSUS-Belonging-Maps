import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpMenu(WidgetTester tester) async {
  final preferences = await SharedPreferences.getInstance();
  final controller = AccessibilitySettingsController(preferences);

  await tester.pumpWidget(
    AccessibilitySettingsScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light(colorSafePalette: false, highContrast: false),
        home: HamburgerMenu(body: const Scaffold(body: SizedBox.expand())),
      ),
    ),
  );
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => AuthService.isAdmin = false);

  testWidgets('non-admins see Administrator Login and no admin panel', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    AuthService.isAdmin = false;
    await _pumpMenu(tester);

    expect(find.text('Administrator Login'), findsOneWidget);
    expect(find.text('Logout'), findsNothing);
    expect(find.text('ADMIN PANEL'), findsNothing);
  });

  testWidgets('Logout clears the saved login and goes back to user mode (P1-217)', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({AuthService.isAdminKey: true});
    await AuthService.loadLogin();
    expect(AuthService.isAdmin, isTrue);

    await _pumpMenu(tester);
    expect(find.text('ADMIN PANEL'), findsOneWidget);

    await tester.ensureVisible(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(AuthService.isAdmin, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(AuthService.isAdminKey), isFalse);

    // Reopen the menu on the new screen: admin controls are gone.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Administrator Login'), findsOneWidget);
    expect(find.text('ADMIN PANEL'), findsNothing);
  });
}

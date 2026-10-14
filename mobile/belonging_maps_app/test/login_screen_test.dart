import 'dart:io';

import 'package:belonging_maps_app/screens/login_screen.dart';
import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpLogin(WidgetTester tester, http.Client client) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final controller = AccessibilitySettingsController(preferences);

  await tester.pumpWidget(
    AccessibilitySettingsScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light(colorSafePalette: false, highContrast: false),
        home: LoginScreen(client: client),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'admin');
  await tester.enterText(find.byType(TextField).at(1), 'pw');
  await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    AuthService.isAdmin = false;
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:5162');
  });

  tearDown(() => AuthService.isAdmin = false);

  testWidgets('shows a clear message when the server is down (P1-215)', (
    tester,
  ) async {
    final client = MockClient(
      (_) async => throw const SocketException('Connection refused'),
    );
    await _pumpLogin(tester, client);

    await _submit(tester);

    expect(find.textContaining("Can't reach the server"), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget); // still on login
    expect(AuthService.isAdmin, isFalse);
  });

  testWidgets('shows Invalid credentials on a rejected login', (tester) async {
    final client = MockClient((_) async => http.Response('', 401));
    await _pumpLogin(tester, client);

    await _submit(tester);

    expect(find.text('Invalid credentials'), findsOneWidget);
    expect(AuthService.isAdmin, isFalse);
  });

  testWidgets('tells the dev when API_BASE_URL is missing (P1-214)', (
    tester,
  ) async {
    dotenv.loadFromString(envString: '', isOptional: true);
    final client = MockClient((_) async => http.Response('', 200));
    await _pumpLogin(tester, client);

    await _submit(tester);

    expect(find.textContaining('API_BASE_URL is missing'), findsOneWidget);
  });
}

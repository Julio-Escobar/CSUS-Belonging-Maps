import 'dart:convert';

import 'package:belonging_maps_app/screens/change_password_screen.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_api.dart';

// P1-332: app side of the admin change-password flow. The backend half
// (authorization, BCrypt check, hash update) is covered by
// backend/BelongingMaps.API.Tests/ChangePasswordTests.cs.

const _current = 'old-password';
const _next = 'brand-new-password';

/// Fake backend that only accepts [_current] for "admin".
MockClient _backend(List<Map<String, dynamic>> requests, {int? status}) {
  return MockClient((request) async {
    if (request.url.path != '/api/auth/change-password') {
      return http.Response('', 404);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    requests.add(body);
    if (status != null) return http.Response('{}', status);
    if (body['username'] != 'admin' || body['currentPassword'] != _current) {
      return http.Response('{}', 401);
    }
    return http.Response('{"message":"Password changed."}', 200);
  });
}

void _logInAsAdmin() {
  AuthService.isAdmin = true;
  AuthService.username = 'admin';
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    loadTestEnv();
    _logInAsAdmin();
  });

  tearDown(() {
    AuthService.isAdmin = false;
    AuthService.username = null;
  });

  group('AuthService.changePassword', () {
    test('sends the saved username with both passwords', () async {
      final requests = <Map<String, dynamic>>[];

      final result = await AuthService.changePassword(
        _current,
        _next,
        client: _backend(requests),
      );

      expect(result, ChangePasswordResult.success);
      expect(requests.single, {
        'username': 'admin',
        'currentPassword': _current,
        'newPassword': _next,
      });
    });

    test('maps backend failures to results', () async {
      final cases = {
        401: ChangePasswordResult.invalidCurrentPassword,
        403: ChangePasswordResult.forbidden,
        400: ChangePasswordResult.invalidNewPassword,
        500: ChangePasswordResult.serverUnreachable,
      };
      for (final entry in cases.entries) {
        final result = await AuthService.changePassword(
          _current,
          _next,
          client: _backend([], status: entry.key),
        );
        expect(result, entry.value, reason: 'status ${entry.key}');
      }
    });

    test('refuses without a logged-in admin', () async {
      AuthService.username = null;
      final requests = <Map<String, dynamic>>[];

      final result = await AuthService.changePassword(
        _current,
        _next,
        client: _backend(requests),
      );

      expect(result, ChangePasswordResult.notLoggedIn);
      expect(requests, isEmpty);
    });

    test('login saves the username and logout clears it', () async {
      AuthService.isAdmin = false;
      AuthService.username = null;
      final client = MockClient(
        (_) async => http.Response('{"role":"Admin"}', 200),
      );

      await AuthService.login('admin', _current, client: client);
      expect(AuthService.username, 'admin');

      AuthService.username = null;
      await AuthService.loadLogin();
      expect(AuthService.username, 'admin');

      await AuthService.logout();
      expect(AuthService.username, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(AuthService.usernameKey), isFalse);
    });
  });

  group('ChangePasswordScreen', () {
    Future<void> pumpScreen(WidgetTester tester, http.Client client) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangePasswordScreen(client: client),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    Future<void> fill(
      WidgetTester tester, {
      String current = _current,
      String next = _next,
      String? confirm,
    }) async {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current password'),
        current,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'),
        next,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        confirm ?? next,
      );
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Change password'));
      await tester.pumpAndSettle();
    }

    testWidgets('has current, new and confirmation fields', (tester) async {
      await pumpScreen(tester, _backend([]));

      expect(find.widgetWithText(TextFormField, 'Current password'), findsOne);
      expect(find.widgetWithText(TextFormField, 'New password'), findsOne);
      expect(
        find.widgetWithText(TextFormField, 'Confirm new password'),
        findsOne,
      );
    });

    testWidgets('requires every field', (tester) async {
      final requests = <Map<String, dynamic>>[];
      await pumpScreen(tester, _backend(requests));

      await submit(tester);

      expect(find.text('Enter your current password'), findsOneWidget);
      expect(find.text('Enter a new password'), findsOneWidget);
      expect(find.text('Confirm your new password'), findsOneWidget);
      expect(requests, isEmpty);
    });

    testWidgets('rejects a short new password', (tester) async {
      final requests = <Map<String, dynamic>>[];
      await pumpScreen(tester, _backend(requests));

      await fill(tester, next: 'short');
      await submit(tester);

      expect(find.text('Use at least 8 characters'), findsOneWidget);
      expect(requests, isEmpty);
    });

    testWidgets('rejects a new password equal to the current one', (
      tester,
    ) async {
      final requests = <Map<String, dynamic>>[];
      await pumpScreen(tester, _backend(requests));

      await fill(tester, next: _current);
      await submit(tester);

      expect(
        find.text('New password must be different from the current one'),
        findsOneWidget,
      );
      expect(requests, isEmpty);
    });

    testWidgets('rejects a confirmation that does not match', (tester) async {
      final requests = <Map<String, dynamic>>[];
      await pumpScreen(tester, _backend(requests));

      await fill(tester, confirm: 'something-else');
      await submit(tester);

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(requests, isEmpty);
    });

    testWidgets('shows an error when the current password is wrong', (
      tester,
    ) async {
      await pumpScreen(tester, _backend([]));

      await fill(tester, current: 'wrong-password');
      await submit(tester);

      expect(find.text('Current password is incorrect.'), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('confirms success and closes the form', (tester) async {
      final requests = <Map<String, dynamic>>[];
      await pumpScreen(tester, _backend(requests));

      await fill(tester);
      await submit(tester);

      expect(requests, hasLength(1));
      expect(find.text('Password changed.'), findsOneWidget);
      expect(find.byType(ChangePasswordScreen), findsNothing);
    });
  });
}

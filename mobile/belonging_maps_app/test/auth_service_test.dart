import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.isAdmin = false;
    dotenv.loadFromString(envString: 'API_BASE_URL=http://localhost:5162');
  });

  tearDown(() => AuthService.isAdmin = false);

  group('saveLogin / loadLogin / logout (P1-216, P1-217)', () {
    test('saveLogin persists the admin flag and loadLogin restores it',
        () async {
      AuthService.isAdmin = true;
      await AuthService.saveLogin();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AuthService.isAdminKey), isTrue);

      // Simulate an app restart: the in-memory flag is gone, prefs are not.
      AuthService.isAdmin = false;
      await AuthService.loadLogin();
      expect(AuthService.isAdmin, isTrue);
    });

    test('loadLogin defaults to user mode when nothing is saved', () async {
      AuthService.isAdmin = true;
      await AuthService.loadLogin();
      expect(AuthService.isAdmin, isFalse);
    });

    test('logout clears the saved flag and drops to user mode', () async {
      AuthService.isAdmin = true;
      await AuthService.saveLogin();

      await AuthService.logout();
      expect(AuthService.isAdmin, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(AuthService.isAdminKey), isFalse);

      // A restart after logout must still be user mode.
      await AuthService.loadLogin();
      expect(AuthService.isAdmin, isFalse);
    });
  });

  group('login (P1-214, P1-215)', () {
    test('returns missingBaseUrl when API_BASE_URL is not set', () async {
      dotenv.loadFromString(envString: '', isOptional: true);
      final result = await AuthService.login('admin', 'pw');
      expect(result, LoginResult.missingBaseUrl);
    });

    test('posts to <API_BASE_URL>/api/auth/login and saves an admin login',
        () async {
      dotenv.loadFromString(envString: 'API_BASE_URL=http://example.test:5162/');
      Uri? calledUrl;
      final client = MockClient((request) async {
        calledUrl = request.url;
        expect(jsonDecode(request.body), {
          'username': 'admin',
          'password': 'pw',
        });
        return http.Response(jsonEncode({'role': 'Admin'}), 200);
      });

      final result = await AuthService.login('admin', 'pw', client: client);

      expect(result, LoginResult.success);
      expect(calledUrl.toString(), 'http://example.test:5162/api/auth/login');
      expect(AuthService.isAdmin, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AuthService.isAdminKey), isTrue);
    });

    test('a non-admin role logs in without admin controls', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'role': 'User'}), 200),
      );
      final result = await AuthService.login('bob', 'pw', client: client);
      expect(result, LoginResult.success);
      expect(AuthService.isAdmin, isFalse);
    });

    test('a 401 means invalid credentials', () async {
      AuthService.isAdmin = true;
      final client = MockClient((_) async => http.Response('', 401));
      final result = await AuthService.login('admin', 'wrong', client: client);
      expect(result, LoginResult.invalidCredentials);
      expect(AuthService.isAdmin, isFalse);
    });

    test('a SocketException means the server is unreachable', () async {
      final client = MockClient(
        (_) async => throw const SocketException('Connection refused'),
      );
      final result = await AuthService.login('admin', 'pw', client: client);
      expect(result, LoginResult.serverUnreachable);
    });

    test('a TimeoutException means the server is unreachable', () async {
      final client = MockClient(
        (_) async => throw TimeoutException('too slow'),
      );
      final result = await AuthService.login('admin', 'pw', client: client);
      expect(result, LoginResult.serverUnreachable);
    });
  });
}

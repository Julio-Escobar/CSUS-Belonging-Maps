import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// What happened when we tried to log in.
enum LoginResult {
  /// Backend accepted the credentials.
  success,

  /// Backend answered but rejected the credentials.
  invalidCredentials,

  /// Backend never answered (timeout, no network, server down).
  serverUnreachable,

  /// API_BASE_URL is missing from .env so we don't know where to call.
  missingBaseUrl,
}

/// Holds the admin flag for the whole app and talks to the backend login
/// endpoint. The flag is saved with SharedPreferences so an admin stays logged
/// in across app restarts (P1-216) until they log out (P1-217).
class AuthService {
  static bool isAdmin = false;

  /// SharedPreferences key for the persisted admin flag.
  static const String isAdminKey = 'auth_is_admin';

  /// How long we wait for the backend before giving up (P1-215).
  static const Duration loginTimeout = Duration(seconds: 10);

  /// Base URL of the backend, read from .env (P1-214). Null when not set.
  static String? get baseUrl {
    final value = dotenv.env['API_BASE_URL']?.trim();
    if (value == null || value.isEmpty) return null;
    // Strip a trailing slash so we can safely append paths.
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  /// POSTs the credentials to /api/auth/login. Pass a [client] in tests to
  /// fake the network.
  static Future<LoginResult> login(
    String username,
    String password, {
    http.Client? client,
  }) async {
    final base = baseUrl;
    if (base == null) return LoginResult.missingBaseUrl;

    final url = Uri.parse('$base/api/auth/login');
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(loginTimeout);

      if (response.statusCode != 200) {
        isAdmin = false;
        return LoginResult.invalidCredentials;
      }

      final data = jsonDecode(response.body);
      isAdmin = data is Map && data['role'] == 'Admin';
      await saveLogin();
      return LoginResult.success;
    } on TimeoutException {
      return LoginResult.serverUnreachable;
    } on SocketException {
      return LoginResult.serverUnreachable;
    } on http.ClientException {
      return LoginResult.serverUnreachable;
    } finally {
      // Only close clients we created; the caller owns an injected one.
      if (client == null) httpClient.close();
    }
  }

  /// Persists the current admin flag (P1-216).
  static Future<void> saveLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isAdminKey, isAdmin);
  }

  /// Restores the admin flag saved by [saveLogin]. Call before runApp so the
  /// first screen already knows whether to show admin controls (P1-216).
  static Future<void> loadLogin() async {
    final prefs = await SharedPreferences.getInstance();
    isAdmin = prefs.getBool(isAdminKey) ?? false;
  }

  /// Clears the saved login and drops back to user mode (P1-217).
  static Future<void> logout() async {
    isAdmin = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(isAdminKey);
  }
}

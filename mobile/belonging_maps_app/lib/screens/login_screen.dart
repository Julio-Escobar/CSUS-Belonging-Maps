import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/hamburger_menu.dart';
import '../services/auth_service.dart';
import 'map_screen.dart';

typedef LoginRequest =
    Future<http.Response> Function({
      required String username,
      required String password,
    });

Future<http.Response> _sendLoginRequest({
  required String username,
  required String password,
}) {
  final url = Uri.parse('http://10.0.2.2:5162/api/auth/login');
  return http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username, 'password': password}),
  );
}

class LoginScreen extends StatelessWidget {
  final LoginRequest _loginRequest;

  LoginScreen({super.key, LoginRequest? loginRequest})
    : _loginRequest = loginRequest ?? _sendLoginRequest;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void handleLogin(BuildContext context) async {
    final username = usernameController.text;
    final password = passwordController.text;

    try {
      final response = await _loginRequest(
        username: username,
        password: password,
      );

      if (response.statusCode == 200) {
        if (!context.mounted) return;
        final data = jsonDecode(response.body);

        AuthService.isAdmin = data['role'] == 'Admin';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid credentials")));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Connection error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      title: "Login",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => handleLogin(context),
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}

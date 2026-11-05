import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/hamburger_menu.dart';
import '../services/auth_service.dart';
import '../services/login_lockout.dart';
import 'map_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Optional HTTP client so tests can fake the backend.
  final http.Client? client;

  const LoginScreen({super.key, this.client});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LoginLockout _lockout = LoginLockout();
  bool _isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final colors = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError ? TextStyle(color: colors.onError) : null,
        ),
        backgroundColor: isError ? colors.error : null,
      ),
    );
  }

  Future<void> _handleRejectedLogin() async {
    final lockedFor = await _lockout.recordFailure();
    _showMessage(
      lockedFor != null ? lockoutMessage(lockedFor) : 'Invalid credentials',
      isError: true,
    );
  }

  Future<void> handleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final remaining = await _lockout.remainingLock();
    if (remaining != null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(lockoutMessage(remaining), isError: true);
      return;
    }

    final result = await AuthService.login(
      usernameController.text,
      passwordController.text,
      client: widget.client,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case LoginResult.success:
        await _lockout.reset();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      case LoginResult.invalidCredentials:
        await _handleRejectedLogin();
      case LoginResult.serverUnreachable:
        _showMessage(
          "Can't reach the server. Check your connection and try again.",
        );
      case LoginResult.missingBaseUrl:
        _showMessage('API_BASE_URL is missing from .env. See .env.example.');
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
              onSubmitted: (_) => handleLogin(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
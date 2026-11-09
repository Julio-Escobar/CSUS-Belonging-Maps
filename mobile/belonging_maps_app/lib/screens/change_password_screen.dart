import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';

/// Lets a logged-in admin change their password (P1-331). Opened from the
/// ADMIN PANEL section of the hamburger menu.
class ChangePasswordScreen extends StatefulWidget {
  /// Optional HTTP client so tests can fake the backend.
  final http.Client? client;

  const ChangePasswordScreen({super.key, this.client});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateCurrent(String? value) {
    if (value == null || value.isEmpty) return 'Enter your current password';
    return null;
  }

  String? _validateNew(String? value) {
    if (value == null || value.isEmpty) return 'Enter a new password';
    if (value.length < AuthService.minPasswordLength) {
      return 'Use at least ${AuthService.minPasswordLength} characters';
    }
    if (value == _currentController.text) {
      return 'New password must be different from the current one';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Confirm your new password';
    if (value != _newController.text) return 'Passwords do not match';
    return null;
  }

  String _messageFor(ChangePasswordResult result) {
    switch (result) {
      case ChangePasswordResult.success:
        return 'Password changed.';
      case ChangePasswordResult.invalidCurrentPassword:
        return 'Current password is incorrect.';
      case ChangePasswordResult.forbidden:
        return 'Only administrators can change their password here.';
      case ChangePasswordResult.invalidNewPassword:
        return 'The server rejected the new password. Use at least '
            '${AuthService.minPasswordLength} characters that differ from the '
            'current password.';
      case ChangePasswordResult.serverUnreachable:
        return "Can't reach the server. Check your connection and try again.";
      case ChangePasswordResult.missingBaseUrl:
        return 'API_BASE_URL is missing from .env. See .env.example.';
      case ChangePasswordResult.notLoggedIn:
        return 'Your login session is missing a username. Log out and log in '
            'again, then try changing your password.';
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    setState(() => _errorMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final result = await AuthService.changePassword(
      _currentController.text,
      _newController.text,
      client: widget.client,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result == ChangePasswordResult.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(result))));
      Navigator.of(context).pop();
      return;
    }

    setState(() => _errorMessage = _messageFor(result));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _currentController,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  validator: _validateCurrent,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newController,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    helperText:
                        'At least ${AuthService.minPasswordLength} characters',
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: _validateNew,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  validator: _validateConfirm,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'Saving new password',
                          ),
                        )
                      : const Text('Change password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

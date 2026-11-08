import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/accessibility_theme.dart';

class InAppWebScreen extends StatefulWidget {
  final String title;
  final String url;

  const InAppWebScreen({super.key, required this.title, required this.url});

  @override
  State<InAppWebScreen> createState() => _InAppWebScreenState();
}

class _InAppWebScreenState extends State<InAppWebScreen> {
  WebViewController? _controller;
  int _progress = 0;
  bool _failed = false;

  static Uri? _parseWebUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  @override
  void initState() {
    super.initState();

    final uri = _parseWebUri(widget.url);
    if (uri == null) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _failed = false);
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onWebResourceError: (error) {
            if (mounted && (error.isForMainFrame ?? true)) {
              setState(() => _failed = true);
            }
          },
          onNavigationRequest: (request) {
            final scheme = Uri.tryParse(request.url)?.scheme;
            final allowed =
                scheme == 'http' || scheme == 'https' || scheme == 'about';
            return allowed
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(uri);
  }

  Future<void> _handleBack(bool didPop, Object? result) async {
    if (didPop) return;

    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    final controller = _controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        backgroundColor: colors.pageBackground,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: controller == null
            ? _buildMessage(
                context,
                icon: Icons.link_off,
                title: 'Website coming soon',
                message: "This website link hasn't been added yet.",
              )
            : Stack(
                children: [
                  WebViewWidget(controller: controller),
                  if (_progress < 100 && !_failed)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _progress == 0 ? null : _progress / 100,
                        minHeight: 3,
                        color: colors.primary,
                        backgroundColor: colors.pageBackground,
                      ),
                    ),
                  if (_failed)
                    Positioned.fill(
                      child: ColoredBox(
                        color: colors.pageBackground,
                        child: _buildMessage(
                          context,
                          icon: Icons.wifi_off,
                          title: 'Unable to load the website',
                          message:
                              'Check your internet connection and try again.',
                          onRetry: () {
                            setState(() => _failed = false);
                            controller.reload();
                          },
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    final colors = AccessibilityColors.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colors.primary),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
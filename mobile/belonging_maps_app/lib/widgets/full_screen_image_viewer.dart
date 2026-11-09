import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/location_attributes.dart';

/// Identifies the full-screen photo viewer, so widget tests can find it without
/// depending on the image provider.
const Key fullScreenImageViewerKey = ValueKey<String>(
  'full-screen-image-viewer',
);

/// Identifies the close button of the full-screen photo viewer.
const Key fullScreenImageCloseKey = ValueKey<String>('full-screen-image-close');

/// Shows a location photo filling the screen.
///
/// The whole image stays visible (it is never cropped), it can be pinched to
/// zoom, and a tap anywhere closes the viewer, as does the close button or the
/// system back gesture.
class FullScreenImageViewer extends StatelessWidget {
  final String? assetPath;
  final String? url;
  final String semanticsLabel;

  const FullScreenImageViewer({
    super.key,
    this.assetPath,
    this.url,
    required this.semanticsLabel,
  });

  /// Opens the viewer for [assetPath] (preferred) or [url].
  static Future<void> show(
    BuildContext context, {
    String? assetPath,
    String? url,
    required String semanticsLabel,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FullScreenImageViewer(
          assetPath: assetPath,
          url: url,
          semanticsLabel: semanticsLabel,
        ),
      ),
    );
  }

  static String? _clean(String? value) {
    final text = cleanLocationAttribute(value);
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final String? asset = _clean(assetPath);
    final String? networkUrl = _clean(url);

    return Scaffold(
      key: fullScreenImageViewerKey,
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Semantics(
                      image: true,
                      label: semanticsLabel,
                      excludeSemantics: true,
                      child: _buildImage(asset: asset, networkUrl: networkUrl),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: IconButton(
                  key: fullScreenImageCloseKey,
                  tooltip: 'Close photo',
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.45),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage({String? asset, String? networkUrl}) {
    if (asset != null) {
      return Image.asset(
        asset,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    if (networkUrl != null) {
      return Image.network(
        networkUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return const Center(
      child: Text(
        'Image unavailable',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}

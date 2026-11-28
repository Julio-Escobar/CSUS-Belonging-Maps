import 'package:flutter/material.dart';

import '../services/accessibility_theme.dart';
import '../services/image_upload_service.dart';
import 'full_screen_image_viewer.dart';

/// Shows an uploaded image (P1-318 / P1-319) with rounded corners, a
/// loading state, and a quiet placeholder if it can't be loaded. Shows
/// nothing when [imageId] is null.
class ResourceImage extends StatelessWidget {
  final int? imageId;
  final double height;

  /// Read by screen readers, e.g. "Photo for Food Pantry".
  final String semanticLabel;

  /// Whether tapping the photo opens it full screen, where it can be pinched
  /// to zoom. Off by default so the edit-form preview stays inert.
  final bool expandOnTap;

  const ResourceImage({
    super.key,
    required this.imageId,
    required this.semanticLabel,
    this.height = 160,
    this.expandOnTap = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = ImageUploadService.urlFor(imageId);
    if (url == null) return const SizedBox.shrink();
    final colors = AccessibilityColors.of(context);

    void openFullScreen() {
      FullScreenImageViewer.show(
        context,
        url: url,
        semanticsLabel: semanticLabel,
      );
    }

    // Row + Expanded fills the available width without reporting an
    // infinite width, so this also works inside dialogs (which measure
    // their content's intrinsic size).
    final Widget photo = Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: height,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                // When the photo is tappable the wrapper below carries the
                // label, so the image itself stays out of the semantics tree.
                excludeFromSemantics: expandOnTap,
                semanticLabel: expandOnTap ? null : semanticLabel,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return ColoredBox(
                    color: colors.primary.withValues(alpha: 0.08),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: colors.primary.withValues(alpha: 0.08),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: colors.secondaryText,
                      semanticLabel: 'Image unavailable',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (!expandOnTap) return photo;

    return Semantics(
      button: true,
      image: true,
      label: semanticLabel,
      hint: 'Opens the photo full screen',
      onTap: openFullScreen,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: openFullScreen,
        child: photo,
      ),
    );
  }
}

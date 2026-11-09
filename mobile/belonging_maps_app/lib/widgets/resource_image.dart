import 'package:flutter/material.dart';

import '../services/accessibility_theme.dart';
import '../services/image_upload_service.dart';

/// Shows an uploaded image (P1-318 / P1-319) with rounded corners, a
/// loading state, and a quiet placeholder if it can't be loaded. Shows
/// nothing when [imageId] is null.
class ResourceImage extends StatelessWidget {
  final int? imageId;
  final double height;

  /// Read by screen readers, e.g. "Photo for Food Pantry".
  final String semanticLabel;

  const ResourceImage({
    super.key,
    required this.imageId,
    required this.semanticLabel,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    final url = ImageUploadService.urlFor(imageId);
    if (url == null) return const SizedBox.shrink();
    final colors = AccessibilityColors.of(context);

    // Row + Expanded fills the available width without reporting an
    // infinite width, so this also works inside dialogs (which measure
    // their content's intrinsic size).
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: height,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                semanticLabel: semanticLabel,
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
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/accessibility_theme.dart';
import 'resource_image.dart';

/// The image chosen in an add/edit form: either the one already saved
/// ([existingImageId]), a newly picked one that still needs uploading
/// ([newBytes]), or none.
class ImageSelection {
  final int? existingImageId;
  final Uint8List? newBytes;

  const ImageSelection({this.existingImageId, this.newBytes});

  const ImageSelection.none() : existingImageId = null, newBytes = null;

  bool get hasImage => existingImageId != null || newBytes != null;
}

/// Picks a photo and returns its bytes, or null if the admin cancels.
typedef ImagePickFunction = Future<Uint8List?> Function(ImageSource source);

/// "Add image / Change / Remove" control used in the Community Resources and
/// Organization Resources forms (P1-318 / P1-319).
class ResourceImageField extends StatelessWidget {
  final ImageSelection value;
  final ValueChanged<ImageSelection> onChanged;
  final bool enabled;

  const ResourceImageField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  /// Largest image the backend accepts.
  static const int maxBytes = 2 * 1024 * 1024;

  /// How photos are picked. Tests replace this with a fake.
  @visibleForTesting
  static ImagePickFunction pickImage = _pickWithImagePicker;

  static Future<Uint8List?> _pickWithImagePicker(ImageSource source) async {
    // Shrink on the phone so uploads are fast and the database stays small.
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    return file?.readAsBytes();
  }

  Future<void> _choose(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from photos'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final bytes = await pickImage(source);
      if (bytes == null) return;
      if (bytes.length > maxBytes) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('That image is too large. Please pick another.'),
          ),
        );
        return;
      }
      onChanged(ImageSelection(newBytes: bytes));
    } catch (_) {
      // Usually a denied camera/photos permission.
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't open the photo picker. Check the app's camera and "
            'photo permissions in Settings.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    Widget? preview;
    if (value.newBytes != null) {
      // Row + Expanded instead of an infinite width so the dialog that holds
      // this field can measure it.
      preview = Semantics(
        image: true,
        label: 'Selected image',
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  value.newBytes!,
                  height: 140,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    height: 140,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: colors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (value.existingImageId != null) {
      preview = ResourceImage(
        imageId: value.existingImageId,
        height: 140,
        semanticLabel: 'Current image',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (preview != null) ...[preview, const SizedBox(height: 8)],
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: enabled ? () => _choose(context) : null,
              icon: Icon(
                value.hasImage
                    ? Icons.swap_horiz
                    : Icons.add_photo_alternate_outlined,
              ),
              label: Text(value.hasImage ? 'Change image' : 'Add image'),
            ),
            if (value.hasImage)
              TextButton.icon(
                onPressed: enabled
                    ? () => onChanged(const ImageSelection.none())
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: colors.destructive,
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove image'),
              ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../services/accessibility_theme.dart';

class CurrentLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CurrentLocationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    return Positioned(
      bottom: 100,
      right: 16,
      child: FloatingActionButton(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        tooltip: 'Go to current location',
        onPressed: onPressed,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

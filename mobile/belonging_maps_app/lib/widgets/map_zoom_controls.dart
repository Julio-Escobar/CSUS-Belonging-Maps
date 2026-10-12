import 'package:flutter/material.dart';

const Color zoomButtonBackgroundColor = Color.fromARGB(255, 47, 95, 62);
const Color zoomButtonIconColor = Colors.white;

class MapZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final double top;
  final double left;

  const MapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    this.top = 16,
    this.left = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: SafeArea(
        child: Column(
          children: [
            _ZoomButton(icon: Icons.add, label: 'Zoom in', onTap: onZoomIn),
            const SizedBox(height: 10),
            _ZoomButton(
              icon: Icons.remove,
              label: 'Zoom out',
              onTap: onZoomOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ZoomButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: zoomButtonBackgroundColor,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        button: true,
        label: label,
        onTap: onTap,
        child: ExcludeSemantics(
          child: IconButton(
            tooltip: label,
            onPressed: onTap,
            icon: Icon(icon, color: zoomButtonIconColor),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ),
      ),
    );
  }
}

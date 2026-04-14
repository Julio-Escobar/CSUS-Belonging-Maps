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
            _ZoomButton(icon: Icons.add, onTap: onZoomIn),
            const SizedBox(height: 10),
            _ZoomButton(icon: Icons.remove, onTap: onZoomOut),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: zoomButtonBackgroundColor,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: zoomButtonIconColor),
        ),
      ),
    );
  }
}

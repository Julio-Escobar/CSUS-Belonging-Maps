import 'package:flutter/material.dart';

import '../screens/in_app_web_screen.dart';
import '../services/accessibility_theme.dart';

class WebsiteCircleButton extends StatelessWidget {
  final String label;
  final String logoPath;
  final String url;

  final bool fillCircle;
  final double imageScale;

  const WebsiteCircleButton({
    super.key,
    required this.label,
    required this.logoPath,
    required this.url,
    this.fillCircle = true,
    this.imageScale = 1.0,
  });

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppWebScreen(title: label, url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Semantics(
      button: true,
      label: 'Open $label website',
      onTap: () => _open(context),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: colors.cardBackground,
            elevation: 3,
            shape: CircleBorder(
              side: BorderSide(color: colors.primary, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(context),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Padding(
                  padding: EdgeInsets.all(fillCircle ? 2 : 10),
                  child: ClipOval(
                    child: Transform.scale(
                      scale: fillCircle ? imageScale : 1.0,
                      child: Image.asset(
                        logoPath,
                        fit: fillCircle ? BoxFit.cover : BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.public,
                          color: colors.primary,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
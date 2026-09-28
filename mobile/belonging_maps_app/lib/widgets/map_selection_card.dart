import 'package:flutter/material.dart';

import '../services/accessibility_theme.dart';

class MapSelectionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final String imagePath;
  final String? logoPath;
  final VoidCallback onTap;

  const MapSelectionCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.imagePath,
    this.logoPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        container: true,
        button: true,
        label: '$label. $subtitle',
        hint: 'Open map',
        onTap: onTap,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                    if (logoPath != null)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: colors.cardBackground,
                          backgroundImage: AssetImage(logoPath!),
                        ),
                      ),
                  ],
                ),
              ),
              ColoredBox(
                color: colors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: colors.action,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

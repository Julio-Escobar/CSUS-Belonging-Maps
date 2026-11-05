import 'package:flutter/material.dart';

import '../services/accessibility_theme.dart';

/// Compact popup used by the Gender Neutral Bathrooms map.
///
/// Unlike [LocationInfoCard], this card is always fully expanded and contains
/// no navigation or "more information" actions. Tapping a restroom marker shows
/// the building, floor, and location description immediately.
class GenderNeutralBathroomInfoCard extends StatelessWidget {
  const GenderNeutralBathroomInfoCard({
    super.key,
    required this.buildingName,
    required this.floor,
    required this.description,
    required this.onClose,
  });

  static const String restroomIconAsset =
      'assets/map_icons/general/GenderNeutralBathroom.png';

  final String buildingName;
  final String floor;
  final String description;
  final VoidCallback onClose;

  bool _hasValue(String value) => value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    final title = _hasValue(buildingName)
        ? buildingName
        : 'Gender Neutral Bathroom';
    final details = _hasValue(description)
        ? description
        : 'No location details available.';

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
          ),
          child: Semantics(
            container: true,
            liveRegion: true,
            label: 'Gender neutral bathroom details',
            child: Material(
              color: colors.primary,
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          restroomIconAsset,
                          width: 32,
                          height: 32,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          tooltip: 'Close location details',
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          icon: Icon(Icons.close, color: colors.onPrimary),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: colors.onPrimary.withValues(alpha: 0.2),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_hasValue(floor)) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.layers_outlined,
                                size: 18,
                                color: colors.onPrimary.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Floor $floor',
                                  style: TextStyle(
                                    color: colors.onPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          details,
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

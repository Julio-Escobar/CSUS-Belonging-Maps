import 'package:flutter/material.dart';

import '../services/accessibility_theme.dart';
import 'location_card_style.dart';

class LactationRoomInfoCard extends StatelessWidget {
  const LactationRoomInfoCard({
    super.key,
    required this.buildingName,
    required this.roomInfo,
    required this.onClose,
  });

  final String buildingName;
  final String roomInfo;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

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
            label: 'Lactation room details',
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
                        Icon(
                          Icons.child_care,
                          size: 32,
                          color: colors.onPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              buildingName.isEmpty
                                  ? 'Lactation Room'
                                  : buildingName,
                              style: LocationCardText.title(colors.onPrimary),
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
                    child: Text(
                      roomInfo.isEmpty
                          ? 'Room or floor details are not available.'
                          : roomInfo,
                      style: LocationCardText.body(colors.onPrimary),
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

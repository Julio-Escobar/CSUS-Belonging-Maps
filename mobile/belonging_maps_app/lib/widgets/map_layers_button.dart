import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

const Color layersButtonBackgroundColor = Color.fromARGB(255, 47, 95, 62);
const Color layersButtonIconColor = Colors.white;

class MapLayerEntry {
  final String label;
  final FeatureLayer layer;

  const MapLayerEntry({required this.label, required this.layer});
}

class MapLayersButton extends StatelessWidget {
  final List<MapLayerEntry> entries;

  const MapLayersButton({super.key, required this.entries});

  void _openLayerPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Text(
                      'Map Layers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final entry in entries)
                    CheckboxListTile(
                      value: entry.layer.isVisible,
                      activeColor: layersButtonBackgroundColor,
                      title: Text(entry.label),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (checked) {
                        setSheetState(() {
                          entry.layer.isVisible = checked ?? true;
                        });
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: layersButtonBackgroundColor,
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openLayerPanel(context),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.layers, color: layersButtonIconColor),
        ),
      ),
    );
  }
}

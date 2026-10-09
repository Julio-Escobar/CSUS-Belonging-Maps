import 'dart:async';

import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

import '/constants/map_icon_config.dart';
import '/services/layer_filter.dart';

const Color layersButtonBackgroundColor = Color.fromARGB(255, 47, 95, 62);
const Color layersButtonIconColor = Colors.white;

/// A community-map layer (category) together with the state needed to filter
/// the individual location types it contains.
class MapLayerEntry {
  MapLayerEntry({required this.label, required this.layer, this.config});

  final String label;
  final FeatureLayer layer;

  /// Icon configuration for this layer, used as a fallback source of [types]
  /// when the layer's data cannot be queried (see [loadLayerTypes]).
  final LayerIconConfig? config;

  /// Every location type available in this layer. Populated asynchronously the
  /// first time the layers panel is opened; empty until then.
  List<String> types = const [];

  /// The types currently enabled. Seeded with all [types] once they load.
  final Set<String> selectedTypes = <String>{};

  /// True while [types] is being loaded from the layer's data.
  bool isLoadingTypes = false;

  bool get hasTypes => types.isNotEmpty;

  /// True when every available type is selected. This is the state shown by
  /// the category's "All" option, so deselecting any single type clears it.
  bool get allTypesSelected =>
      types.isNotEmpty && selectedTypes.length >= types.length;
}

class MapLayersButton extends StatelessWidget {
  final List<MapLayerEntry> entries;

  /// Invoked after a category or type checkbox changes, so the owning screen
  /// can recompose each layer's definition expression (combining the type
  /// filter with any active search).
  final VoidCallback? onFilterChanged;

  const MapLayersButton({
    super.key,
    required this.entries,
    this.onFilterChanged,
  });

  void _openLayerPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _LayerPanel(
        entries: entries,
        onFilterChanged: onFilterChanged,
      ),
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

/// The content of the layers bottom sheet. Each category is an [ExpansionTile]
/// whose trailing arrow reveals its location types, so individual types can be
/// checked or unchecked. Types are loaded from the layer's data the first time
/// the panel is shown.
class _LayerPanel extends StatefulWidget {
  const _LayerPanel({required this.entries, this.onFilterChanged});

  final List<MapLayerEntry> entries;
  final VoidCallback? onFilterChanged;

  @override
  State<_LayerPanel> createState() => _LayerPanelState();
}

class _LayerPanelState extends State<_LayerPanel> {
  @override
  void initState() {
    super.initState();
    unawaited(_loadTypes());
  }

  /// Loads the available location types for any entry that has not loaded them
  /// yet, seeding every type as selected (no type filtering by default).
  Future<void> _loadTypes() async {
    for (final entry in widget.entries) {
      if (entry.hasTypes || entry.isLoadingTypes) continue;

      entry.isLoadingTypes = true;
      final types = await loadLayerTypes(entry.layer, config: entry.config);
      entry.types = types;
      if (entry.selectedTypes.isEmpty) {
        entry.selectedTypes.addAll(types);
      }
      entry.isLoadingTypes = false;

      if (!mounted) return;
      widget.onFilterChanged?.call();
      setState(() {});
    }
  }

  void _onCategoryChanged(MapLayerEntry entry, bool show) {
    // The category checkbox only controls layer visibility. It never changes
    // which types are selected.
    setState(() {
      entry.layer.isVisible = show;
    });
    widget.onFilterChanged?.call();
  }

  void _onTypeChanged(MapLayerEntry entry, String type, bool selected) {
    setState(() {
      if (selected) {
        entry.selectedTypes.add(type);
        // Selecting a type implies the category should be shown. Leave the
        // remaining types as they are, so only the chosen type is displayed.
        entry.layer.isVisible = true;
      } else {
        entry.selectedTypes.remove(type);
      }
    });
    widget.onFilterChanged?.call();
  }

  /// Handles the "All" option: selecting it enables every type in the category,
  /// deselecting it disables every type. Its checked state is derived
  /// ([MapLayerEntry.allTypesSelected]), so unchecking any individual type
  /// automatically clears it.
  void _onAllTypesChanged(MapLayerEntry entry, bool selectAll) {
    setState(() {
      entry.selectedTypes.clear();
      if (selectAll) {
        entry.selectedTypes.addAll(entry.types);
        entry.layer.isVisible = true;
      }
    });
    widget.onFilterChanged?.call();
  }

  List<Widget> _buildTypeTiles(MapLayerEntry entry) {
    if (!entry.hasTypes) {
      if (entry.isLoadingTypes) {
        return const [
          Padding(
            padding: EdgeInsets.fromLTRB(52, 0, 20, 12),
            child: Text(
              'Loading types…',
              style: TextStyle(
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ];
      }
      return const [];
    }

    return [
      CheckboxListTile(
        value: entry.allTypesSelected,
        activeColor: layersButtonBackgroundColor,
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.only(left: 32),
        title: const Text(
          'All',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        onChanged: (checked) => _onAllTypesChanged(entry, checked ?? false),
      ),
      for (final type in entry.types)
        CheckboxListTile(
          value: entry.selectedTypes.contains(type),
          activeColor: layersButtonBackgroundColor,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: const EdgeInsets.only(left: 32),
          title: Text(type, style: const TextStyle(fontSize: 14)),
          onChanged: (checked) => _onTypeChanged(entry, type, checked ?? false),
        ),
    ];
  }

  Widget _buildEntry(MapLayerEntry entry) {
    return ExpansionTile(
      key: PageStorageKey<String>(entry.label),
      controlAffinity: ListTileControlAffinity.trailing,
      leading: Checkbox(
        value: entry.layer.isVisible,
        activeColor: layersButtonBackgroundColor,
        onChanged: (checked) => _onCategoryChanged(entry, checked ?? true),
      ),
      title: Text(entry.label),
      children: [
        // When the category is hidden, its types are dimmed to show that
        // checked types are not currently active. Interaction is preserved so
        // selecting a type can re-enable the category.
        for (final tile in _buildTypeTiles(entry))
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: entry.layer.isVisible ? 1.0 : 0.4,
            child: tile,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              'Map Layers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final entry in widget.entries) _buildEntry(entry),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}


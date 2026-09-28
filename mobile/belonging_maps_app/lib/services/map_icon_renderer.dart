import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/foundation.dart';

import '/constants/map_icon_config.dart';

/// Default on-screen size (in device-independent pixels) for map icons.
///
/// The rasterized source icons are 121px, so this leaves plenty of headroom
/// for high-density displays. Adjust here to change every map at once.
const double mapIconSize = 40;

/// The attribute field used to distinguish icon types across all layers.
const String mapIconTypeField = 'Type';

/// A feature layer paired with the icon configuration that should be applied
/// to it.
class LayerIconAssignment {
  const LayerIconAssignment({required this.layer, required this.config});

  final FeatureLayer layer;
  final LayerIconConfig config;
}

/// Cache of loaded symbols keyed by `assetPath@size`, so icons shared between
/// layers (and communities) are only rasterized/loaded once per session.
final Map<String, PictureMarkerSymbol> _symbolCache = {};

Future<PictureMarkerSymbol?> _symbolFor(String assetPath, double size) async {
  final cacheKey = '$assetPath@$size';
  final cached = _symbolCache[cacheKey];
  if (cached != null) return cached;

  try {
    final image = await ArcGISImage.fromAsset(assetPath);
    final symbol = PictureMarkerSymbol.withImage(image)
      ..width = size
      ..height = size;
    _symbolCache[cacheKey] = symbol;
    return symbol;
  } catch (error) {
    // A single missing/broken icon should never prevent the layer from
    // rendering; it simply falls through to the category's default symbol.
    debugPrint('Failed to load map icon "$assetPath": $error');
    return null;
  }
}

/// Builds a [UniqueValueRenderer] for [layer] from [config] and assigns it, so
/// each feature is drawn with the icon configured for its [typeField] value.
Future<void> applyLayerIconRenderer(
  FeatureLayer layer,
  LayerIconConfig config, {
  String typeField = mapIconTypeField,
  double iconSize = mapIconSize,
}) async {
  final fallbackSymbol = await _symbolFor(
    mapIconAssetPath(config.fallback),
    iconSize,
  );

  final uniqueValues = <UniqueValue>[];
  for (final entry in config.byType.entries) {
    final symbol = await _symbolFor(mapIconAssetPath(entry.value), iconSize);
    if (symbol == null) continue;
    uniqueValues.add(
      UniqueValue(label: entry.key, values: [entry.key], symbol: symbol),
    );
  }

  layer.renderer = UniqueValueRenderer(
    fieldNames: [typeField],
    uniqueValues: uniqueValues,
    defaultLabel: 'Other',
    defaultSymbol: fallbackSymbol,
  );
}

/// Applies icon renderers for several layers at once.
Future<void> applyLayerIconRenderers(
  List<LayerIconAssignment> assignments, {
  String typeField = mapIconTypeField,
  double iconSize = mapIconSize,
}) async {
  await Future.wait(
    assignments.map(
      (assignment) => applyLayerIconRenderer(
        assignment.layer,
        assignment.config,
        typeField: typeField,
        iconSize: iconSize,
      ),
    ),
  );
}

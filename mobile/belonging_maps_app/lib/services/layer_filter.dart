import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:flutter/foundation.dart';

import '/constants/map_icon_config.dart';
import '/services/map_icon_renderer.dart';

/// Maximum number of features fetched when discovering a layer's `Type`
/// values. The community layers are small, so a single page is enough; this is
/// kept well above their record counts so no type is missed.
const int _typeQueryMaxFeatures = 2000;

/// Loads the distinct location types present in [layer]'s data.
///
/// The live `Type` values are the source of truth. When the query fails or
/// returns nothing (for example while offline), the known types from
/// [config]'s `byType` map are used as a fallback so the filter still offers
/// something useful.
Future<List<String>> loadLayerTypes(
  FeatureLayer layer, {
  LayerIconConfig? config,
  String typeField = mapIconTypeField,
}) async {
  final queried = await _queryLayerTypes(layer, typeField: typeField);
  if (queried.isNotEmpty) return queried;

  return (<String>{...?config?.byType.keys}.toList()..sort());
}

Future<List<String>> _queryLayerTypes(
  FeatureLayer layer, {
  required String typeField,
}) async {
  try {
    if (layer.loadStatus != LoadStatus.loaded) {
      await layer.load();
    }

    final table = layer.featureTable;
    if (table is! ServiceFeatureTable) return const [];

    final parameters = QueryParameters()
      ..whereClause = '1=1'
      ..returnGeometry = false
      ..maxFeatures = _typeQueryMaxFeatures;

    final result = await table.queryFeatures(parameters);
    final values = <String>{};

    for (final feature in result.features()) {
      final value = feature.attributes[typeField]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        values.add(value);
      }
    }

    return values.toList()..sort();
  } catch (error) {
    debugPrint('Error loading layer types: $error');
    return const [];
  }
}

/// Builds the SQL clause that restricts [typeField] to [selectedTypes].
///
/// Returns an empty string when there is nothing to filter by — either no
/// known [allTypes] or every type selected — so callers can safely AND the
/// result with other clauses. Returns a "match nothing" clause (`1=0`) when
/// every type has been deselected.
String buildTypeClause(
  List<String> allTypes,
  Set<String> selectedTypes, {
  String typeField = mapIconTypeField,
}) {
  if (allTypes.isEmpty || selectedTypes.length >= allTypes.length) {
    return '';
  }
  if (selectedTypes.isEmpty) return '1=0';

  final quoted = selectedTypes
      .map((type) => "'${type.replaceAll("'", "''")}'")
      .join(', ');
  return '$typeField IN ($quoted)';
}

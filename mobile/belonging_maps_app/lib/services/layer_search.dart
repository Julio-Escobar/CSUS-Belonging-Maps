import 'package:arcgis_maps/arcgis_maps.dart';

/// Builds the search portion of [layer]'s definition expression for [query].
///
/// Returns an empty string when the query is blank or the layer has no
/// searchable name fields, so callers can safely combine the result with
/// other filters (see `buildTypeClause` in `layer_filter.dart`).
Future<String> buildLayerSearchClause(FeatureLayer layer, String query) async {
  final escapedQuery = query.replaceAll("'", "''");
  if (escapedQuery.trim().isEmpty) return '';

  final upperQuery = escapedQuery.toUpperCase();

  if (layer.loadStatus != LoadStatus.loaded) {
    await layer.load();
  }

  final table = layer.featureTable;
  if (table == null) return '';

  final fields = table.fields
      .map((f) => f.name)
      .where((name) =>
          name.toUpperCase().contains("NAME") ||
          name.toUpperCase().contains("TITLE") ||
          name.toUpperCase().contains("FACILITY"))
      .toList();

  if (fields.isEmpty) return '';

  return fields
      .map((f) => "UPPER($f) LIKE '%$upperQuery%'")
      .join(" OR ");
}

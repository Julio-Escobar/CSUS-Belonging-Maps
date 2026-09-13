import 'package:arcgis_maps/arcgis_maps.dart';

Future<void> applyLayerSearch(List<FeatureLayer> layers, String query) async {
  final escapedQuery = query.replaceAll("'", "''");

  if (escapedQuery.trim().isEmpty) {
    for (final layer in layers) {
      layer.definitionExpression = '';
    }
    return;
  }

  final upperQuery = escapedQuery.toUpperCase();

  for (final layer in layers) {
    if (layer.loadStatus != LoadStatus.loaded) {
      await layer.load();
    }

    final table = layer.featureTable;
    if (table == null) continue;

    final fields = table.fields
        .map((f) => f.name)
        .where((name) =>
            name.toUpperCase().contains("NAME") ||
            name.toUpperCase().contains("TITLE") ||
            name.toUpperCase().contains("FACILITY"))
        .toList();

    if (fields.isEmpty) continue;

    final conditions = fields
        .map((f) => "UPPER($f) LIKE '%$upperQuery%'")
        .join(" OR ");

    layer.definitionExpression = conditions;
  }
}

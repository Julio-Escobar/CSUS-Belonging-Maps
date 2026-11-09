import 'package:arcgis_maps/arcgis_maps.dart';

/// Shared search for every map screen (P1-327). A location matches when the
/// query appears, ignoring case, in its name, its category, or its address.
///
/// The field lists below cover the names used across the SOMOS, Ummah and
/// Ubuntu feature layers. Matching is by substring of the uppercased field
/// name so variants like `Company_Name`, `FACILITY_NAME` or `Street_Address`
/// are picked up too.
const _nameFieldHints = ['NAME', 'TITLE', 'FACILITY'];
const _categoryFieldHints = ['CATEGORY', 'TYPE'];
const _addressFieldHints = ['ADDRESS', 'LOCATION', 'STREET', 'CITY', 'ZIP'];

/// Which of [fieldNames] the search looks at (name, category and address
/// fields), in their original order.
List<String> searchableFieldNames(Iterable<String> fieldNames) {
  const hints = [
    ..._nameFieldHints,
    ..._categoryFieldHints,
    ..._addressFieldHints,
  ];
  return fieldNames.where((name) {
    final upper = name.toUpperCase();
    return hints.any(upper.contains);
  }).toList();
}

/// Builds a case-insensitive SQL where clause matching [query] against
/// [fieldNames].
///
/// [categoryLabel] is the layer's category as people see it in the app (for
/// example "Food" or "Religion"). When the query is part of that label every
/// location in the layer matches, so typing "food" shows the Food layer even
/// if no single feature has "food" in its fields.
///
/// Returns an empty string for a blank query so callers can combine the
/// result with the type filter (see `buildTypeClause` in `layer_filter.dart`).
/// Returns `1=0` when nothing in the layer can match, which hides the layer's
/// features instead of leaving them all showing.
String buildSearchClause({
  required Iterable<String> fieldNames,
  required String query,
  String? categoryLabel,
}) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return '';

  final label = categoryLabel?.trim().toLowerCase() ?? '';
  if (label.isNotEmpty && label.contains(trimmed.toLowerCase())) {
    return '1=1';
  }

  final fields = searchableFieldNames(fieldNames);
  if (fields.isEmpty) return '1=0';

  final upperQuery = trimmed.replaceAll("'", "''").toUpperCase();
  return fields.map((f) => "UPPER($f) LIKE '%$upperQuery%'").join(' OR ');
}

/// Builds the search part of [layer]'s definition expression for [query].
/// Only text fields are searched, since `UPPER()` fails on numeric fields.
Future<String> buildLayerSearchClause(
  FeatureLayer layer,
  String query, {
  String? categoryLabel,
}) async {
  if (query.trim().isEmpty) return '';

  if (layer.loadStatus != LoadStatus.loaded) {
    await layer.load();
  }

  final table = layer.featureTable;
  final textFields =
      table?.fields
          .where((f) => f.type == FieldType.text)
          .map((f) => f.name)
          .toList() ??
      const <String>[];

  return buildSearchClause(
    fieldNames: textFields,
    query: query,
    categoryLabel: categoryLabel,
  );
}

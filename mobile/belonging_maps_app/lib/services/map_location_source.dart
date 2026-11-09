import 'package:arcgis_maps/arcgis_maps.dart';

import '../models/location_attributes.dart';

const mapLocationPageSize = 50;

class MapLocation {
  final String name;
  final String category;
  final Map<String, dynamic> attributes;
  final Geometry? geometry;

  const MapLocation({
    required this.name,
    required this.category,
    required this.attributes,
    this.geometry,
  });

  factory MapLocation.fromAttributes(
    Map<String, dynamic> attributes, {
    required String category,
    Geometry? geometry,
  }) {
    return MapLocation(
      name: locationTitleFromAttributes(attributes),
      category: category,
      attributes: attributes,
      geometry: geometry,
    );
  }
}

class MapLocationPage {
  final List<MapLocation> locations;
  final bool hasMore;

  MapLocationPage(this.locations, {bool? hasMore})
    : hasMore = hasMore ?? (locations.length == mapLocationPageSize);
}

class MapLocationSource {
  final String name;
  final Future<MapLocationPage> Function(int offset) loadPage;

  const MapLocationSource({required this.name, required this.loadPage});
}

bool mapLocationMatches(MapLocation location, String query) {
  final keyword = query.trim().toLowerCase();
  if (keyword.isEmpty) return false;

  return <Object?>[
    location.name,
    location.category,
    ...location.attributes.values,
  ].any((value) => value?.toString().toLowerCase().contains(keyword) ?? false);
}

Future<List<MapLocation>> loadMapLocationSuggestions(
  Iterable<MapLocationSource> sources, {
  required String query,
  int limit = 5,
}) async {
  if (query.trim().isEmpty || limit <= 0) return const [];

  final matches = <MapLocation>[];
  final seen = <String>{};
  for (final source in sources) {
    try {
      final page = await source.loadPage(0);
      for (final location in page.locations) {
        if (!mapLocationMatches(location, query)) continue;
        final key = '${location.category}|${location.name}'.toLowerCase();
        if (!seen.add(key)) continue;
        matches.add(location);
        if (matches.length == limit) return matches;
      }
    } catch (_) {
      // Suggestions should remain available from other map layers when one
      // service is unavailable.
    }
  }
  return matches;
}

MapLocationSource arcGisLocationSource({
  required String name,
  required FeatureLayer layer,
}) {
  return MapLocationSource(
    name: name,
    loadPage: (offset) async {
      final table = layer.featureTable;
      if (table is! ServiceFeatureTable) {
        throw StateError('This map layer cannot be browsed.');
      }

      await table.load();
      final query = QueryParameters()
        ..whereClause = layer.definitionExpression.isEmpty
            ? '1=1'
            : layer.definitionExpression
        ..returnGeometry = true
        ..maxFeatures = mapLocationPageSize
        ..resultOffset = offset;
      query.orderByFields.add(OrderBy(fieldName: table.objectIdField));

      final result = await table.queryFeaturesWithFieldOptions(
        parameters: query,
        queryFeatureFields: QueryFeatureFields.loadAll,
      );
      final features = result.features().toList();
      return MapLocationPage(
        features
            .map(
              (feature) => MapLocation.fromAttributes(
                feature.attributes,
                category: name,
                geometry: feature.geometry,
              ),
            )
            .toList(),
        hasMore:
            features.isNotEmpty &&
            (result.isTransferLimitExceeded ||
                features.length == mapLocationPageSize),
      );
    },
  );
}

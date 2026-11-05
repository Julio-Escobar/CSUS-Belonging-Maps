import 'package:flutter_test/flutter_test.dart';

import 'package:belonging_maps_app/services/map_location_source.dart';

MapLocation location(
  String name,
  String category, {
  Map<String, dynamic> attributes = const {},
}) {
  return MapLocation(name: name, category: category, attributes: attributes);
}

MapLocationSource source(String name, List<MapLocation> locations) {
  return MapLocationSource(
    name: name,
    loadPage: (_) async => MapLocationPage(locations, hasMore: false),
  );
}

void main() {
  test(
    'returns case-insensitive location suggestions from names and attributes',
    () async {
      final suggestions = await loadMapLocationSuggestions([
        source('Campus locations', [
          location(
            'Dreamer Resource Center',
            'Student Services',
            attributes: {'BUILDING': 'Lassen Hall'},
          ),
          location('Food Pantry', 'Basic Needs'),
        ]),
      ], query: 'lassen');

      expect(suggestions.map((item) => item.name), ['Dreamer Resource Center']);
    },
  );

  test('caps suggestions and continues after an unavailable layer', () async {
    final unavailable = MapLocationSource(
      name: 'Unavailable',
      loadPage: (_) async => throw StateError('offline'),
    );
    final suggestions = await loadMapLocationSuggestions(
      [
        unavailable,
        source('Campus locations', [
          location('Student Union', 'Campus locations'),
          location('Student Health Center', 'Campus locations'),
          location('Student Success Center', 'Campus locations'),
        ]),
      ],
      query: 'student',
      limit: 2,
    );

    expect(suggestions.map((item) => item.name), [
      'Student Union',
      'Student Health Center',
    ]);
  });
}

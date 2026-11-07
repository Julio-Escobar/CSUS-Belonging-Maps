import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/somos_campus_food.dart';

/// Bundled configured dataset for the Latine food options on campus.
const String somosCampusFoodAsset = 'assets/data/somos_campus_food.json';

/// The label used for the Latine food options in the category filter, the
/// Browse locations list, and the location card.
const String latineFoodCategory = 'Latine Food';

/// Loads the Latine food dataset from the app's bundled assets.
///
/// Pass a custom [bundle] in tests. Any missing, malformed, or invalid data
/// throws so the map screen can log the failure and keep the rest of the map.
Future<List<SomosCampusFood>> loadSomosCampusFood({AssetBundle? bundle}) async {
  final source = await (bundle ?? rootBundle).loadString(somosCampusFoodAsset);
  return parseSomosCampusFood(source);
}

/// Parses and validates the JSON representation of the food dataset.
List<SomosCampusFood> parseSomosCampusFood(String source) {
  final dynamic decoded = jsonDecode(source);
  if (decoded is! List) {
    throw const FormatException('The Latine food dataset must be a JSON list.');
  }

  final food = <SomosCampusFood>[];
  final seenIds = <String>{};

  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException(
        'Each Latine food option must be a JSON object.',
      );
    }

    final location = SomosCampusFood.fromJson(entry);
    if (!seenIds.add(location.id)) {
      throw FormatException('Duplicate Latine food option id: ${location.id}.');
    }
    food.add(location);
  }

  if (food.isEmpty) {
    throw const FormatException('The Latine food dataset is empty.');
  }

  food.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return List<SomosCampusFood>.unmodifiable(food);
}

/// Returns the food options matching [query] and any selected [categories].
///
/// The query matches the name, building, room, category, and description so
/// users can search for either a restaurant or the building that houses it.
List<SomosCampusFood> filterSomosCampusFood(
  List<SomosCampusFood> food, {
  String query = '',
  Set<String> categories = const <String>{},
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return food
      .where((location) {
        if (categories.isNotEmpty && !categories.contains(location.category)) {
          return false;
        }
        if (normalizedQuery.isEmpty) return true;

        final searchableText = <String>[
          location.name,
          location.building,
          location.room,
          location.category,
          location.description,
        ].join(' ').toLowerCase();

        return searchableText.contains(normalizedQuery);
      })
      .toList(growable: false);
}

/// The distinct categories available in the category filter for the food.
Set<String> somosCampusFoodCategories(List<SomosCampusFood> food) {
  return food.map((location) => location.category).toSet();
}

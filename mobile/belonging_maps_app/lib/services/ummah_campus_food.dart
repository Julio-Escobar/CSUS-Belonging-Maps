import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/ummah_campus_food.dart';

/// Bundled configured dataset for the halal food options on campus.
const String ummahCampusFoodAsset = 'assets/data/ummah_campus_food.json';

/// The label used for the halal food options in the category filter, the
/// Browse locations list, and the location card.
const String ummahCampusFoodCategory = 'Halal Food';

/// Loads the halal food dataset from the app's bundled assets.
///
/// Pass a custom [bundle] in tests. Any missing, malformed, or invalid data
/// throws so the map screen can log the failure and keep the rest of the map.
Future<List<UmmahCampusFood>> loadUmmahCampusFood({AssetBundle? bundle}) async {
  final source = await (bundle ?? rootBundle).loadString(ummahCampusFoodAsset);
  return parseUmmahCampusFood(source);
}

/// Parses and validates the JSON representation of the food dataset.
List<UmmahCampusFood> parseUmmahCampusFood(String source) {
  final dynamic decoded = jsonDecode(source);
  if (decoded is! List) {
    throw const FormatException(
      'The halal food dataset must be a JSON list.',
    );
  }

  final food = <UmmahCampusFood>[];
  final seenIds = <String>{};

  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException(
        'Each halal food option must be a JSON object.',
      );
    }

    final location = UmmahCampusFood.fromJson(entry);
    if (!seenIds.add(location.id)) {
      throw FormatException('Duplicate halal food option id: ${location.id}.');
    }
    food.add(location);
  }

  if (food.isEmpty) {
    throw const FormatException('The halal food dataset is empty.');
  }

  food.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return List<UmmahCampusFood>.unmodifiable(food);
}

/// Returns the food options matching [query] and any selected [categories].
///
/// The query matches the name, building, room, category, and description so
/// users can search for either a restaurant or the building that houses it.
List<UmmahCampusFood> filterUmmahCampusFood(
  List<UmmahCampusFood> food, {
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
Set<String> ummahCampusFoodCategories(List<UmmahCampusFood> food) {
  return food.map((location) => location.category).toSet();
}

import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/ummah_campus_center.dart';

/// Bundled configured dataset for the Ummah campus centers.
const String ummahCampusCentersAsset = 'assets/data/ummah_campus_centers.json';

/// Loads the Ummah campus center dataset from the app's bundled assets.
///
/// Pass a custom [bundle] in tests. Any missing, malformed, or invalid data
/// throws so the map screen can fall back to showing only the other markers.
Future<List<UmmahCampusCenter>> loadUmmahCampusCenters({
  AssetBundle? bundle,
}) async {
  final source = await (bundle ?? rootBundle).loadString(
    ummahCampusCentersAsset,
  );
  return parseUmmahCampusCenters(source);
}

/// Parses and validates the JSON representation of the center dataset.
List<UmmahCampusCenter> parseUmmahCampusCenters(String source) {
  final dynamic decoded = jsonDecode(source);
  if (decoded is! List) {
    throw const FormatException(
      'The Ummah campus center dataset must be a JSON list.',
    );
  }

  final centers = <UmmahCampusCenter>[];
  final seenIds = <String>{};

  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException(
        'Each Ummah campus center must be a JSON object.',
      );
    }

    final center = UmmahCampusCenter.fromJson(entry);
    if (!seenIds.add(center.id)) {
      throw FormatException('Duplicate Ummah campus center id: ${center.id}.');
    }
    centers.add(center);
  }

  if (centers.isEmpty) {
    throw const FormatException('The Ummah campus center dataset is empty.');
  }

  centers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return List<UmmahCampusCenter>.unmodifiable(centers);
}

/// Returns the centers matching [query] and any selected [categories].
///
/// The query matches the center name, building, room, category, description,
/// and support services so users can search for either a center or a service.
List<UmmahCampusCenter> filterUmmahCampusCenters(
  List<UmmahCampusCenter> centers, {
  String query = '',
  Set<String> categories = const <String>{},
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return centers
      .where((center) {
        if (categories.isNotEmpty && !categories.contains(center.category)) {
          return false;
        }
        if (normalizedQuery.isEmpty) return true;

        final searchableText = <String>[
          center.name,
          center.building,
          center.room,
          center.category,
          center.description,
          ...center.supportServices,
        ].join(' ').toLowerCase();

        return searchableText.contains(normalizedQuery);
      })
      .toList(growable: false);
}

/// The distinct categories available in the category filter for the centers.
Set<String> ummahCampusCenterCategories(List<UmmahCampusCenter> centers) {
  return centers.map((center) => center.category).toSet();
}

import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/somos_campus_center.dart';

/// Bundled configured dataset for the SOMOS campus centers.
const String somosCampusCentersAsset =
    'assets/data/somos_campus_centers.json';

/// Loads the SOMOS campus center dataset from the app's bundled assets.
///
/// Pass a custom [bundle] in tests. Any missing, malformed, or invalid data
/// throws so the map screen can fall back to showing only the numbered
/// resources.
Future<List<SomosCampusCenter>> loadSomosCampusCenters({
  AssetBundle? bundle,
}) async {
  final source = await (bundle ?? rootBundle).loadString(
    somosCampusCentersAsset,
  );
  return parseSomosCampusCenters(source);
}

/// Parses and validates the JSON representation of the center dataset.
List<SomosCampusCenter> parseSomosCampusCenters(String source) {
  final dynamic decoded = jsonDecode(source);
  if (decoded is! List) {
    throw const FormatException(
      'The SOMOS campus center dataset must be a JSON list.',
    );
  }

  final centers = <SomosCampusCenter>[];
  final seenIds = <String>{};

  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException(
        'Each SOMOS campus center must be a JSON object.',
      );
    }

    final center = SomosCampusCenter.fromJson(entry);
    if (!seenIds.add(center.id)) {
      throw FormatException(
        'Duplicate SOMOS campus center id: ${center.id}.',
      );
    }
    centers.add(center);
  }

  if (centers.isEmpty) {
    throw const FormatException('The SOMOS campus center dataset is empty.');
  }

  centers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return List<SomosCampusCenter>.unmodifiable(centers);
}

/// Returns the centers matching [query] and any selected [categories].
///
/// The query matches the center name, building, room, category, description,
/// and support services so users can search for either a center or a service.
List<SomosCampusCenter> filterSomosCampusCenters(
  List<SomosCampusCenter> centers, {
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
Set<String> somosCampusCenterCategories(List<SomosCampusCenter> centers) {
  return centers.map((center) => center.category).toSet();
}

import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/ubuntu_campus_center.dart';

/// Bundled configured dataset for the Ubuntu campus centers.
const String ubuntuCampusCentersAsset =
    'assets/data/ubuntu_campus_centers.json';

/// Loads the Ubuntu campus center dataset from the app's bundled assets.
///
/// Pass a custom [bundle] in tests. Any missing, malformed, or invalid data
/// throws so the map screen can fall back to showing only the numbered
/// resources.
Future<List<UbuntuCampusCenter>> loadUbuntuCampusCenters({
  AssetBundle? bundle,
}) async {
  final source = await (bundle ?? rootBundle).loadString(
    ubuntuCampusCentersAsset,
  );
  return parseUbuntuCampusCenters(source);
}

/// Parses and validates the JSON representation of the center dataset.
List<UbuntuCampusCenter> parseUbuntuCampusCenters(String source) {
  final dynamic decoded = jsonDecode(source);
  if (decoded is! List) {
    throw const FormatException(
      'The Ubuntu campus center dataset must be a JSON list.',
    );
  }

  final centers = <UbuntuCampusCenter>[];
  final seenIds = <String>{};

  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException(
        'Each Ubuntu campus center must be a JSON object.',
      );
    }

    final center = UbuntuCampusCenter.fromJson(entry);
    if (!seenIds.add(center.id)) {
      throw FormatException(
        'Duplicate Ubuntu campus center id: ${center.id}.',
      );
    }
    centers.add(center);
  }

  if (centers.isEmpty) {
    throw const FormatException('The Ubuntu campus center dataset is empty.');
  }

  centers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return List<UbuntuCampusCenter>.unmodifiable(centers);
}

/// Returns the centers matching [query] and any selected [categories].
///
/// The query matches the center name, building, room, category, description,
/// and support services so users can search for either a center or a service.
List<UbuntuCampusCenter> filterUbuntuCampusCenters(
  List<UbuntuCampusCenter> centers, {
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
Set<String> ubuntuCampusCenterCategories(List<UbuntuCampusCenter> centers) {
  return centers.map((center) => center.category).toSet();
}

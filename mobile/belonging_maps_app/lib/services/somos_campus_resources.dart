import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/somos_campus_resource.dart';

/// Bundled configured dataset for the SOMOS campus resource map.
const String somosCampusResourcesAsset =
    'assets/data/somos_campus_resources.json';

/// Loads the SOMOS campus resource dataset from the app's bundled assets.
///
/// Pass a custom [bundle] in tests. Any missing, malformed, or invalid data
/// throws so the map screen can display its error state.
Future<List<SomosCampusResource>> loadSomosCampusResources({
  AssetBundle? bundle,
}) async {
  final source = await (bundle ?? rootBundle).loadString(
    somosCampusResourcesAsset,
  );
  return parseSomosCampusResources(source);
}

/// Parses and validates the JSON representation of the resource dataset.
List<SomosCampusResource> parseSomosCampusResources(String source) {
  final dynamic decoded = jsonDecode(source);
  if (decoded is! List) {
    throw const FormatException(
      'The SOMOS campus resource dataset must be a JSON list.',
    );
  }

  final resources = <SomosCampusResource>[];
  final seenNumbers = <int>{};

  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException(
        'Each SOMOS campus resource must be a JSON object.',
      );
    }

    final resource = SomosCampusResource.fromJson(entry);
    if (!seenNumbers.add(resource.number)) {
      throw FormatException(
        'Duplicate SOMOS campus resource number: ${resource.number}.',
      );
    }
    resources.add(resource);
  }

  if (resources.isEmpty) {
    throw const FormatException('The SOMOS campus resource dataset is empty.');
  }

  resources.sort((a, b) => a.number.compareTo(b.number));
  return List<SomosCampusResource>.unmodifiable(resources);
}

/// Returns the resources matching [query] and any selected [categories].
///
/// The query matches the resource name, building, room, category, and
/// description so users can search for either an office or a service.
List<SomosCampusResource> filterSomosCampusResources(
  List<SomosCampusResource> resources, {
  String query = '',
  Set<String> categories = const <String>{},
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return resources
      .where((resource) {
        if (categories.isNotEmpty && !categories.contains(resource.category)) {
          return false;
        }
        if (normalizedQuery.isEmpty) return true;

        final searchableText = <String>[
          resource.name,
          resource.building,
          resource.room,
          resource.category,
          resource.description,
        ].join(' ').toLowerCase();

        return searchableText.contains(normalizedQuery);
      })
      .toList(growable: false);
}

/// The distinct categories available in the category filter.
Set<String> somosCampusResourceCategories(List<SomosCampusResource> resources) {
  return resources.map((resource) => resource.category).toSet();
}

/// Extracts the selected category names from the expression produced by
/// `MapFilterButton` (for example, `CATEGORY IN ('Basic Needs')`).
Set<String> parseCategoryFilterExpression(String expression) {
  if (expression.trim().isEmpty) return <String>{};

  return RegExp(
    r"'([^']*)'",
  ).allMatches(expression).map((match) => match.group(1)!).toSet();
}

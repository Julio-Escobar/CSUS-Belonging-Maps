import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/ummah_campus_prayer.dart';

/// Bundled configured dataset for the campus prayer rooms and wudu stations.
const String ummahCampusPrayerAsset = 'assets/data/ummah_campus_prayer.json';

/// The label used for the prayer rooms in the category filter, the Browse
/// locations list, and the location card.
const String ummahCampusPrayerCategory = 'Prayer & Wudu';

/// Loads the prayer room dataset from the app's bundled assets.
///
/// Pass a custom [bundle] in tests. Any missing, malformed, or invalid data
/// throws so the map screen can log the failure and keep the rest of the map.
Future<List<UmmahCampusPrayer>> loadUmmahCampusPrayer({
  AssetBundle? bundle,
}) async {
  final source = await (bundle ?? rootBundle).loadString(
    ummahCampusPrayerAsset,
  );
  return parseUmmahCampusPrayer(source);
}

/// Parses and validates the JSON representation of the prayer dataset.
List<UmmahCampusPrayer> parseUmmahCampusPrayer(String source) {
  final dynamic decoded = jsonDecode(source);
  if (decoded is! List) {
    throw const FormatException(
      'The campus prayer room dataset must be a JSON list.',
    );
  }

  final rooms = <UmmahCampusPrayer>[];
  final seenIds = <String>{};

  for (final entry in decoded) {
    if (entry is! Map<String, dynamic>) {
      throw const FormatException(
        'Each campus prayer room must be a JSON object.',
      );
    }

    final room = UmmahCampusPrayer.fromJson(entry);
    if (!seenIds.add(room.id)) {
      throw FormatException('Duplicate campus prayer room id: ${room.id}.');
    }
    rooms.add(room);
  }

  if (rooms.isEmpty) {
    throw const FormatException(
      'The campus prayer room dataset is empty.',
    );
  }

  rooms.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return List<UmmahCampusPrayer>.unmodifiable(rooms);
}

/// Returns the prayer rooms matching [query] and any selected [categories].
///
/// The query matches the name, building, room, floor, category, description,
/// and amenities so users can search for a building or for wudu stations.
List<UmmahCampusPrayer> filterUmmahCampusPrayer(
  List<UmmahCampusPrayer> rooms, {
  String query = '',
  Set<String> categories = const <String>{},
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return rooms
      .where((room) {
        if (categories.isNotEmpty && !categories.contains(room.category)) {
          return false;
        }
        if (normalizedQuery.isEmpty) return true;

        final searchableText = <String>[
          room.name,
          room.building,
          room.room,
          room.floor,
          room.category,
          room.description,
          ...room.amenities,
        ].join(' ').toLowerCase();

        return searchableText.contains(normalizedQuery);
      })
      .toList(growable: false);
}

/// The distinct categories available in the category filter for the rooms.
Set<String> ummahCampusPrayerCategories(List<UmmahCampusPrayer> rooms) {
  return rooms.map((room) => room.category).toSet();
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FavoriteType { location, opportunity }

class FavoriteEntry {
  final FavoriteType type;
  final String id;
  final String title;
  final Map<String, dynamic> data;

  const FavoriteEntry({
    required this.type,
    required this.id,
    required this.title,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'title': title,
    'data': data,
  };

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) {
    final type = FavoriteType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => throw FormatException(
        'Unknown favorite type: ${json['type']}',
      ),
    );
    final id = json['id'];
    final title = json['title'];
    final data = json['data'];
    if (id is! String || id.isEmpty || title is! String || data is! Map) {
      throw const FormatException('Invalid favorite entry.');
    }

    return FavoriteEntry(
      type: type,
      id: id,
      title: title,
      data: Map<String, dynamic>.from(data),
    );
  }
}

class FavoritesStore extends ChangeNotifier {
  FavoritesStore._();

  static final FavoritesStore instance = FavoritesStore._();
  static const String _storageKey = 'saved_favorites_v1';

  Future<List<FavoriteEntry>> loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_storageKey);
    if (stored == null || stored.isEmpty) return <FavoriteEntry>[];

    final decoded = jsonDecode(stored);
    if (decoded is! List) {
      throw const FormatException('Saved favorites must be a list.');
    }
    return decoded
        .map(
          (item) => FavoriteEntry.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<bool> contains(FavoriteType type, String id) async {
    final entries = await loadFavorites();
    return entries.any((entry) => entry.type == type && entry.id == id);
  }

  Future<void> save(FavoriteEntry favorite) async {
    final entries = await loadFavorites();
    final index = entries.indexWhere(
      (entry) => entry.type == favorite.type && entry.id == favorite.id,
    );
    if (index == -1) {
      entries.add(favorite);
    } else {
      entries[index] = favorite;
    }
    await _write(entries);
  }

  Future<void> remove(FavoriteType type, String id) async {
    final entries = await loadFavorites();
    entries.removeWhere((entry) => entry.type == type && entry.id == id);
    await _write(entries);
  }

  Future<void> _write(List<FavoriteEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not save favorites locally.');
    notifyListeners();
  }
}

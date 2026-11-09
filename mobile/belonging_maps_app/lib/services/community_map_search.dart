import 'dart:async';

import '../widgets/map_layers_button.dart';
import 'layer_filter.dart';
import 'layer_search.dart';
import 'map_location_source.dart';

/// Message for a search that found nothing (P1-327).
String noSearchResultsMessage(String query) =>
    'No locations match "${query.trim()}". Try a name, category, or address, '
    'or clear the search to see every location.';

/// What the search bar should show after a search finishes.
class CommunityMapSearchResult {
  final String query;
  final List<MapLocation> suggestions;

  const CommunityMapSearchResult(this.query, this.suggestions);

  /// No query, nothing to show. Used at start and after clearing.
  static const none = CommunityMapSearchResult('', []);

  bool get hasQuery => query.trim().isNotEmpty;

  /// Text for the "no results" row, or null when there's nothing to report.
  String? get noResultsMessage =>
      hasQuery && suggestions.isEmpty ? noSearchResultsMessage(query) : null;
}

/// Search shared by the SOMOS, Ummah and Ubuntu community maps (P1-327,
/// P1-328). Each keystroke filters the map layers and then loads matching
/// locations for the suggestion list. If the person keeps typing, results
/// for the older text are thrown away so they can't overwrite newer ones.
class CommunityMapSearch {
  final Future<void> Function(String query) _applyFilters;
  final Future<List<MapLocation>> Function(String query) _loadSuggestions;
  int _request = 0;

  CommunityMapSearch({
    required Future<void> Function(String query) applyFilters,
    required Future<List<MapLocation>> Function(String query) loadSuggestions,
  }) : _applyFilters = applyFilters,
       _loadSuggestions = loadSuggestions;

  /// Search wired to real ArcGIS layers. A layer's search clause is ANDed
  /// with its type filter so the two don't overwrite each other, and the
  /// layer's label counts as its category.
  factory CommunityMapSearch.forLayers(List<MapLayerEntry> entries) {
    return CommunityMapSearch(
      applyFilters: (query) async {
        for (final entry in entries) {
          final typeClause = buildTypeClause(entry.types, entry.selectedTypes);
          final searchClause = await buildLayerSearchClause(
            entry.layer,
            query,
            categoryLabel: entry.label,
          );
          final clauses = <String>[
            if (typeClause.isNotEmpty) typeClause,
            if (searchClause.isNotEmpty) '($searchClause)',
          ];
          entry.layer.definitionExpression = clauses.join(' AND ');
        }
      },
      loadSuggestions: (query) => loadMapLocationSuggestions(
        visibleLocationSources(entries),
        query: query,
      ),
    );
  }

  /// Runs a search for [query]. Returns null when a newer search started
  /// before this one finished, so the caller should ignore it.
  Future<CommunityMapSearchResult?> search(String query) async {
    final request = ++_request;
    await _applyFilters(query);
    if (request != _request) return null;

    if (query.trim().isEmpty) return CommunityMapSearchResult.none;

    final suggestions = await _loadSuggestions(query);
    if (request != _request) return null;
    return CommunityMapSearchResult(query, suggestions);
  }
}

/// Location sources for the layers currently switched on.
List<MapLocationSource> visibleLocationSources(List<MapLayerEntry> entries) {
  return entries
      .where((entry) => entry.layer.isVisible)
      .map(
        (entry) => arcGisLocationSource(name: entry.label, layer: entry.layer),
      )
      .toList();
}

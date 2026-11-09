import 'dart:async';

import 'package:belonging_maps_app/services/community_map_search.dart';
import 'package:belonging_maps_app/services/layer_search.dart';
import 'package:belonging_maps_app/services/map_location_source.dart';
import 'package:belonging_maps_app/widgets/map_search_bar.dart';
import 'package:belonging_maps_app/widgets/search_suggestion_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/semantics_finders.dart';

// P1-329: shared community-map search covers name, category and address,
// clearing, no results, and accessible search controls.

const _fields = [
  'OBJECTID',
  'Company_Name',
  'Type',
  'CATEGORY',
  'ADDRESS',
  'CITY',
  'PHONE',
  'DESCRIPTION',
];

MapLocation _location(String name, String category, String address) {
  return MapLocation(
    name: name,
    category: category,
    attributes: {'Company_Name': name, 'ADDRESS': address},
  );
}

void main() {
  group('searchableFieldNames', () {
    test('keeps name, category and address fields only', () {
      expect(searchableFieldNames(_fields), [
        'Company_Name',
        'Type',
        'CATEGORY',
        'ADDRESS',
        'CITY',
      ]);
    });
  });

  group('buildSearchClause', () {
    test('is empty for a blank query so the map shows everything', () {
      expect(buildSearchClause(fieldNames: _fields, query: '   '), '');
    });

    test('matches name, category and address fields case-insensitively', () {
      final clause = buildSearchClause(fieldNames: _fields, query: 'broadway');

      expect(clause, contains("UPPER(Company_Name) LIKE '%BROADWAY%'"));
      expect(clause, contains("UPPER(Type) LIKE '%BROADWAY%'"));
      expect(clause, contains("UPPER(CATEGORY) LIKE '%BROADWAY%'"));
      expect(clause, contains("UPPER(ADDRESS) LIKE '%BROADWAY%'"));
      expect(clause, isNot(contains('PHONE')));
      expect(clause, isNot(contains('DESCRIPTION')));
    });

    test('trims the query', () {
      expect(
        buildSearchClause(fieldNames: ['Name'], query: '  taco  '),
        "UPPER(Name) LIKE '%TACO%'",
      );
    });

    test('escapes quotes so names like O\'Neil do not break the SQL', () {
      expect(
        buildSearchClause(fieldNames: ['Name'], query: "o'neil"),
        "UPPER(Name) LIKE '%O''NEIL%'",
      );
    });

    test(
      'a query that is part of the layer category shows the whole layer',
      () {
        expect(
          buildSearchClause(
            fieldNames: _fields,
            query: 'FOOD',
            categoryLabel: 'Food',
          ),
          '1=1',
        );
        expect(
          buildSearchClause(
            fieldNames: _fields,
            query: 'serv',
            categoryLabel: 'Community Services',
          ),
          '1=1',
        );
      },
    );

    test('hides the layer when it has nothing searchable', () {
      expect(buildSearchClause(fieldNames: ['OBJECTID'], query: 'taco'), '1=0');
    });
  });

  group('mapLocationMatches', () {
    final market = _location('La Fiesta Market', 'Food', '1234 Broadway');

    test('matches by name, category or address ignoring case', () {
      expect(mapLocationMatches(market, 'fiesta'), isTrue);
      expect(mapLocationMatches(market, 'FOOD'), isTrue);
      expect(mapLocationMatches(market, 'broadway'), isTrue);
      expect(mapLocationMatches(market, 'library'), isFalse);
    });
  });

  group('CommunityMapSearch', () {
    final market = _location('La Fiesta Market', 'Food', '1234 Broadway');

    test('returns matching suggestions', () async {
      final filtered = <String>[];
      final search = CommunityMapSearch(
        applyFilters: (query) async => filtered.add(query),
        loadSuggestions: (query) async => [market],
      );

      final result = await search.search('fiesta');

      expect(filtered, ['fiesta']);
      expect(result!.suggestions, [market]);
      expect(result.noResultsMessage, isNull);
    });

    test('reports no results with the query in the message', () async {
      final search = CommunityMapSearch(
        applyFilters: (_) async {},
        loadSuggestions: (_) async => const [],
      );

      final result = await search.search('zzz');

      expect(result!.noResultsMessage, noSearchResultsMessage('zzz'));
      expect(result.noResultsMessage, contains('"zzz"'));
    });

    test('clearing restores the unfiltered map and hides messages', () async {
      final filtered = <String>[];
      var loads = 0;
      final search = CommunityMapSearch(
        applyFilters: (query) async => filtered.add(query),
        loadSuggestions: (_) async {
          loads++;
          return const [];
        },
      );

      await search.search('zzz');
      final cleared = await search.search('');

      expect(filtered.last, '');
      expect(loads, 1);
      expect(cleared, same(CommunityMapSearchResult.none));
      expect(cleared!.noResultsMessage, isNull);
      expect(cleared.suggestions, isEmpty);
    });

    test('ignores results from an older search that finishes late', () async {
      final slow = Completer<List<MapLocation>>();
      final search = CommunityMapSearch(
        applyFilters: (_) async {},
        loadSuggestions: (query) =>
            query == 'fi' ? slow.future : Future.value([market]),
      );

      final older = search.search('fi');
      final newer = await search.search('fiesta');
      slow.complete(const []);

      expect(newer!.suggestions, [market]);
      expect(await older, isNull);
    });
  });

  group('MapSearchBar', () {
    Future<TextEditingController> pumpBar(
      WidgetTester tester, {
      String text = '',
      String? noResultsMessage,
      ValueChanged<String>? onChanged,
      List<SearchSuggestion> suggestions = const [],
    }) async {
      final controller = TextEditingController(text: text);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: MapSearchBar(
                controller: controller,
                onChanged: onChanged ?? (_) {},
                noResultsMessage: noResultsMessage,
                suggestions: suggestions,
              ),
            ),
          ),
        ),
      );
      return controller;
    }

    testWidgets('has no clear button while empty', (tester) async {
      await pumpBar(tester);
      expect(find.byTooltip('Clear search'), findsNothing);
    });

    testWidgets('clear button empties the field and resets the map', (
      tester,
    ) async {
      final changes = <String>[];
      final controller = await pumpBar(
        tester,
        text: 'fiesta',
        onChanged: changes.add,
      );

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changes, ['']);
      expect(find.byTooltip('Clear search'), findsNothing);
    });

    testWidgets('clear button is a named action for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpBar(tester, text: 'fiesta');

      expect(semanticTapByTooltip('Clear search'), findsOne);
      semantics.dispose();
    });

    testWidgets('search field is labelled and hints at what it matches', (
      tester,
    ) async {
      await pumpBar(tester);

      expect(find.text('Search map locations'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.hintText, 'Name, category, or address');
    });

    testWidgets('announces the no-results message as a live region', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final message = noSearchResultsMessage('zzz');
      await pumpBar(tester, text: 'zzz', noResultsMessage: message);

      expect(find.text(message), findsOneWidget);
      expect(
        find.semantics.byPredicate((node) {
          final data = node.getSemanticsData();
          return data.label.contains(message) &&
              data.flagsCollection.isLiveRegion;
        }),
        findsOne,
      );
      semantics.dispose();
    });

    testWidgets('selecting a suggestion opens that location', (tester) async {
      var opened = false;
      await pumpBar(
        tester,
        text: 'fiesta',
        suggestions: [
          SearchSuggestion(
            title: 'La Fiesta Market',
            subtitle: 'Food',
            onSelected: () => opened = true,
          ),
        ],
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.tap(find.text('La Fiesta Market'));

      expect(opened, isTrue);
    });
  });
}

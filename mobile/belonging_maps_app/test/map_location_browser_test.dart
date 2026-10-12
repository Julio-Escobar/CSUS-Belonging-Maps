import 'dart:async';

import 'package:belonging_maps_app/models/location_attributes.dart';
import 'package:belonging_maps_app/services/map_location_source.dart';
import 'package:belonging_maps_app/widgets/location_info_card.dart';
import 'package:belonging_maps_app/widgets/map_location_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Rect globalSemanticsRect(SemanticsNode node) {
  var bounds = node.rect;
  SemanticsNode? current = node;
  while (current != null) {
    final transform = current.transform;
    if (transform != null) {
      bounds = MatrixUtils.transformRect(transform, bounds);
    }
    current = current.parent;
  }
  return bounds;
}

Offset semanticsCoordinates(Offset logicalPoint, double devicePixelRatio) {
  return logicalPoint * devicePixelRatio;
}

Offset logicalCoordinates(Offset physicalPoint, double devicePixelRatio) {
  return physicalPoint / devicePixelRatio;
}

Future<void> tapSemanticsBoundsCenter(
  WidgetTester tester,
  SemanticsNode semanticTarget,
) async {
  final physicalCenter = globalSemanticsRect(semanticTarget).center;
  await tester.tapAt(
    logicalCoordinates(physicalCenter, tester.view.devicePixelRatio),
  );
}

void main() {
  test('uses the campus facility name from existing map attributes', () {
    final location = MapLocation.fromAttributes({
      'FACILITY_NAME': 'Community Center',
      'ADDRESS': '123 Main Street',
    }, category: 'Campus locations');
    expect(location.name, 'Community Center');
    expect(location.attributes['ADDRESS'], '123 Main Street');
  });

  test('uses the same preferred name in the list and details card', () {
    final attributes = {
      'Company_Name': 'Community Center',
      'Name': 'Center Name',
      'FACILITY_NAME': 'Facility Name',
    };

    final location = MapLocation.fromAttributes(
      attributes,
      category: 'Community Services',
    );
    final details = LocationInfoData.fromAttributes(attributes);

    expect(location.name, 'Community Center');
    expect(details.cardTitle, location.name);
  });

  test('skips placeholder names and uses the next available field', () {
    final attributes = {
      'Company_Name': ' n/a ',
      'Name': 'Useful Name',
      'FACILITY_NAME': 'Facility Name',
    };

    final location = MapLocation.fromAttributes(
      attributes,
      category: 'Campus locations',
    );
    final details = LocationInfoData.fromAttributes(attributes);

    expect(location.name, 'Useful Name');
    expect(details.cardTitle, location.name);
    expect(cleanLocationAttribute(' null '), isEmpty);
  });

  Future<void> openBrowser(
    WidgetTester tester,
    List<MapLocationSource> sources,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final location = await showMapLocationBrowser(context, sources);
                if (context.mounted && location != null) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Selected ${location.category}: ${location.name}',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Browse locations'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Browse locations'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty visible-layers state', (tester) async {
    await openBrowser(tester, []);
    expect(
      find.text('Turn on a map layer to browse locations.'),
      findsOneWidget,
    );
  });

  testWidgets('shows an empty location list', (tester) async {
    await openBrowser(tester, [
      MapLocationSource(
        name: 'Campus locations',
        loadPage: (_) async => MapLocationPage([]),
      ),
    ]);
    await tester.tap(find.text('Campus locations'));
    await tester.pumpAndSettle();
    expect(find.text('No locations found.'), findsOneWidget);
  });

  testWidgets('activating a layer heading loads that layer', (tester) async {
    final semantics = tester.ensureSemantics();
    var businessServiceLoads = 0;
    var foodLoads = 0;
    await openBrowser(tester, [
      MapLocationSource(
        name: 'Business Services',
        loadPage: (_) async {
          businessServiceLoads++;
          return MapLocationPage([
            MapLocation.fromAttributes({
              'Company_Name': 'Business A',
            }, category: 'Business Services'),
          ]);
        },
      ),
      MapLocationSource(
        name: 'Halal Foods',
        loadPage: (_) async {
          foodLoads++;
          return MapLocationPage([
            MapLocation.fromAttributes({
              'Company_Name': 'Cafe B',
            }, category: 'Halal Foods'),
          ]);
        },
      ),
    ]);

    final businessServices = find.semantics.byLabel(
      RegExp('Business Services'),
    );
    expect(businessServices, findsOneWidget);
    tester.semantics.tap(businessServices);
    await tester.pumpAndSettle();

    expect(businessServiceLoads, 1);
    expect(foodLoads, 0);
    expect(
      find.bySemanticsLabel('Open Business A, Business Services'),
      findsOneWidget,
    );
    expect(find.text('Cafe B'), findsNothing);
    semantics.dispose();
  });

  const categories = [
    'Business Services',
    'Community Services',
    'Halal Foods',
    'Religious & Cultural',
    'Education',
  ];

  testWidgets('each community section opens a location from its own source', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final loadCounts = <String, int>{
      for (final category in categories) category: 0,
    };
    final sources = [
      for (final category in categories)
        MapLocationSource(
          name: category,
          loadPage: (_) async {
            loadCounts[category] = loadCounts[category]! + 1;
            return MapLocationPage([
              MapLocation.fromAttributes({
                'Name': 'Location for $category',
              }, category: category),
            ]);
          },
        ),
    ];

    for (final category in categories) {
      final previousCounts = Map<String, int>.from(loadCounts);
      await openBrowser(tester, sources);

      final heading = find.semantics.byLabel(RegExp(RegExp.escape(category)));
      expect(heading, findsOneWidget);
      final headingTextRect = tester.getRect(find.text(category));
      final headingSemanticRect = globalSemanticsRect(
        tester.getSemantics(find.text(category)),
      );
      expect(
        headingSemanticRect.contains(
          semanticsCoordinates(
            headingTextRect.center,
            tester.view.devicePixelRatio,
          ),
        ),
        isTrue,
        reason:
            '$category semantic rect $headingSemanticRect should cover text rect $headingTextRect',
      );
      await tapSemanticsBoundsCenter(tester, heading.evaluate().single);
      await tester.pumpAndSettle();

      final locationName = 'Location for $category';
      final location = find.semantics.byLabel('Open $locationName, $category');
      expect(location, findsOneWidget);
      for (final otherCategory in categories.where(
        (item) => item != category,
      )) {
        expect(find.text('Location for $otherCategory'), findsNothing);
        expect(loadCounts[otherCategory], previousCounts[otherCategory]);
      }

      await tapSemanticsBoundsCenter(tester, location.evaluate().single);
      await tester.pumpAndSettle();
      expect(find.text('Selected $category: $locationName'), findsOneWidget);
      expect(loadCounts[category], previousCounts[category]! + 1);
    }
    semantics.dispose();
  });

  testWidgets('semantic activation opens only the selected community layer', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final loadCounts = <String, int>{
      for (final category in categories) category: 0,
    };
    final sources = [
      for (final category in categories)
        MapLocationSource(
          name: category,
          loadPage: (_) async {
            loadCounts[category] = loadCounts[category]! + 1;
            return MapLocationPage([
              MapLocation.fromAttributes({
                'Name': 'Location for $category',
              }, category: category),
            ]);
          },
        ),
    ];

    for (final category in categories) {
      final previousCounts = Map<String, int>.from(loadCounts);
      await openBrowser(tester, sources);

      final heading = find.semantics.byLabel(
        RegExp('^${RegExp.escape(category)}\$'),
      );
      expect(heading, findsOneWidget);
      tester.semantics.tap(heading);
      await tester.pumpAndSettle();

      final locationName = 'Location for $category';
      final location = find.semantics.byLabel('Open $locationName, $category');
      expect(location, findsOneWidget);
      expect(loadCounts[category], previousCounts[category]! + 1);
      for (final otherCategory in categories.where(
        (item) => item != category,
      )) {
        expect(find.text('Location for $otherCategory'), findsNothing);
        expect(loadCounts[otherCategory], previousCounts[otherCategory]);
      }

      tester.semantics.tap(location);
      await tester.pumpAndSettle();
      expect(find.text('Selected $category: $locationName'), findsOneWidget);
    }
    semantics.dispose();
  });

  testWidgets('later heading stays aligned after an earlier section expands', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();

    await openBrowser(tester, [
      MapLocationSource(
        name: 'Business Services',
        loadPage: (_) async => MapLocationPage(
          ['Business A', 'Business B', 'Business C', 'Business D']
              .map(
                (name) => MapLocation.fromAttributes({
                  'Name': name,
                }, category: 'Business Services'),
              )
              .toList(),
        ),
      ),
      MapLocationSource(
        name: 'Community Services',
        loadPage: (_) async => MapLocationPage([
          MapLocation.fromAttributes({
            'Name': 'Community A',
          }, category: 'Community Services'),
        ]),
      ),
    ]);

    await tapSemanticsBoundsCenter(
      tester,
      find.semantics.byLabel('Business Services').evaluate().single,
    );
    await tester.pumpAndSettle();
    expect(find.text('Business A'), findsOneWidget);

    final communityHeading = find.semantics.byLabel('Community Services');
    expect(communityHeading, findsOneWidget);
    await tapSemanticsBoundsCenter(tester, communityHeading.evaluate().single);
    await tester.pumpAndSettle();

    expect(find.text('Business A'), findsOneWidget);
    expect(find.text('Community A'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Open Community A, Community Services'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Open Business A, Business Services'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('semantic target bounds activate the focused location row', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2424);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await openBrowser(tester, [
      MapLocationSource(
        name: 'Business Services',
        loadPage: (_) async => MapLocationPage(
          ['First location', 'Second location', 'Third location']
              .map(
                (name) => MapLocation.fromAttributes({
                  'Name': name,
                }, category: 'Business Services'),
              )
              .toList(),
        ),
      ),
    ]);
    await tapSemanticsBoundsCenter(
      tester,
      find.semantics.byLabel('Business Services').evaluate().single,
    );
    await tester.pumpAndSettle();

    final thirdLocation = find.semantics.byLabel(
      'Open Third location, Business Services',
    );
    final thirdTextRect = tester.getRect(find.text('Third location'));
    final thirdSemanticRect = globalSemanticsRect(
      tester.getSemantics(find.text('Third location')),
    );
    expect(
      thirdSemanticRect.contains(
        semanticsCoordinates(
          thirdTextRect.center,
          tester.view.devicePixelRatio,
        ),
      ),
      isTrue,
      reason:
          'semantic rect $thirdSemanticRect should cover row text rect $thirdTextRect',
    );
    await tapSemanticsBoundsCenter(tester, thirdLocation.evaluate().single);
    await tester.pumpAndSettle();

    expect(
      find.text('Selected Business Services: Third location'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('reports loading, retries an error, and selects a named item', (
    tester,
  ) async {
    final pending = Completer<MapLocationPage>();
    var requests = 0;
    await openBrowser(tester, [
      MapLocationSource(
        name: 'Halal Foods',
        loadPage: (_) {
          requests++;
          if (requests == 1) return pending.future;
          if (requests == 2) throw StateError('Offline');
          return Future.value(
            MapLocationPage([
              MapLocation.fromAttributes({
                'Company_Name': 'Cafe',
                'ADDRESS': '456 River Road',
              }, category: 'Halal Foods'),
            ]),
          );
        },
      ),
    ]);
    await tester.tap(find.text('Halal Foods'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load locations.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load locations.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Open Cafe, Halal Foods'), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Open Cafe, Halal Foods'));
    await tester.pumpAndSettle();
    expect(find.text('Selected Halal Foods: Cafe'), findsOneWidget);
    expect(requests, 3);
  });

  testWidgets('keeps loading after a short page marked as incomplete', (
    tester,
  ) async {
    final offsets = <int>[];
    await openBrowser(tester, [
      MapLocationSource(
        name: 'Community Services',
        loadPage: (offset) async {
          offsets.add(offset);
          if (offset == 0) {
            return MapLocationPage(
              [
                MapLocation.fromAttributes({
                  'Name': 'First location',
                }, category: 'Community Services'),
                MapLocation.fromAttributes({
                  'Name': 'Second location',
                }, category: 'Community Services'),
              ],
              hasMore: true,
            );
          }
          return MapLocationPage([
            MapLocation.fromAttributes({
              'Name': 'Final location',
            }, category: 'Community Services'),
          ]);
        },
      ),
    ]);

    await tester.tap(find.text('Community Services'));
    await tester.pumpAndSettle();
    expect(find.text('Load more'), findsOneWidget);

    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(offsets, [0, 2]);
    expect(find.text('First location'), findsOneWidget);
    expect(find.text('Second location'), findsOneWidget);
    expect(find.text('Final location'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('loads one page at a time', (tester) async {
    final offsets = <int>[];
    await openBrowser(tester, [
      MapLocationSource(
        name: 'Community Services',
        loadPage: (offset) async {
          offsets.add(offset);
          if (offset == 0) {
            return MapLocationPage(
              List.generate(
                mapLocationPageSize,
                (index) => MapLocation.fromAttributes({
                  'Name': 'Location $index',
                }, category: 'Community Services'),
              ),
            );
          }
          return MapLocationPage([
            MapLocation.fromAttributes({
              'Name': 'Last location',
            }, category: 'Community Services'),
          ]);
        },
      ),
    ]);
    await tester.tap(find.text('Community Services'));
    await tester.pumpAndSettle();
    expect(offsets, [0]);
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(offsets, [0, mapLocationPageSize]);
    expect(find.text('Last location'), findsOneWidget);
    expect(find.text('Load more'), findsNothing);
  });
}

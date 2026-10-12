import 'package:belonging_maps_app/widgets/current_location_buttons.dart';
import 'package:belonging_maps_app/widgets/map_filter_button.dart';
import 'package:belonging_maps_app/widgets/map_layers_button.dart';
import 'package:belonging_maps_app/widgets/map_zoom_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/semantics_finders.dart';

void main() {
  testWidgets('map controls match their action by semantics and touch', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var zoomIn = 0;
    var zoomOut = 0;
    var currentLocation = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              MapZoomControls(
                onZoomIn: () => zoomIn++,
                onZoomOut: () => zoomOut++,
              ),
              CurrentLocationButton(onPressed: () => currentLocation++),
            ],
          ),
        ),
      ),
    );

    tester.semantics.tap(semanticTapByLabel('Zoom in'));
    tester.semantics.tap(semanticTapByLabel('Zoom out'));
    tester.semantics.tap(semanticTapByTooltip('Go to current location'));
    expect((zoomIn, zoomOut, currentLocation), (1, 1, 1));

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.tap(find.byTooltip('Go to current location'));
    expect((zoomIn, zoomOut, currentLocation), (2, 2, 2));
    semantics.dispose();
  });

  testWidgets('the named map layers action opens the layer panel', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: MapLayersButton(entries: []),
          ),
        ),
      ),
    );

    tester.semantics.tap(semanticTapByTooltip('Map layers'));
    await tester.pumpAndSettle();
    expect(find.text('Map Layers'), findsOneWidget);

    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Map layers'));
    await tester.pumpAndSettle();
    expect(find.text('Map Layers'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the campus filter name opens the category filter', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final expressions = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapFilterButton(
            featureLayer: null,
            loadFilters: () async => ['Community Center'],
            onDefinitionExpressionChanged: expressions.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.semantics.tap(
      semanticTapByLabel('Filter map locations by Category'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Filter by Category'), findsOneWidget);
    expect(find.text('Community Center'), findsOneWidget);

    tester.semantics.tap(semanticTapByLabel('Community Center'));
    await tester.pumpAndSettle();
    tester.semantics.tap(semanticTapByLabel(RegExp('Apply')));
    await tester.pumpAndSettle();
    expect(expressions, ["CATEGORY IN ('Community Center')"]);
    expect(find.byTooltip('Clear map location filters'), findsOneWidget);
    tester.semantics.tap(semanticTapByTooltip('Clear map location filters'));
    await tester.pumpAndSettle();
    expect(expressions, ["CATEGORY IN ('Community Center')", '']);

    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Filter by Category'), findsOneWidget);
    semantics.dispose();
  });
}

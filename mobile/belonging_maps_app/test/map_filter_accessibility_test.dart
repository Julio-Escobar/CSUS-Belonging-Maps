import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/widgets/map_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'filter sheet scrolls at 200 percent text and retries a failed load',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var attempts = 0;
      final applied = <String>[];

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: MaterialApp(
            theme: AppTheme.light(colorSafePalette: true, highContrast: true),
            home: Scaffold(
              body: MapFilterButton(
                featureLayer: null,
                loadFilters: () async {
                  attempts++;
                  if (attempts == 1) throw StateError('offline');
                  return List<String>.generate(
                    20,
                    (index) => 'Category $index',
                  );
                },
                onDefinitionExpressionChanged: applied.add,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load filter options.'), findsOneWidget);
      expect(find.byTooltip('Close filters'), findsOneWidget);

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Category 19'),
        240,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Category 19'), findsOneWidget);
      await tester.tap(find.text('Category 19'));
      await tester.pump();
      await tester.tap(find.textContaining('Apply'));
      await tester.pumpAndSettle();

      expect(applied, ["CATEGORY IN ('Category 19')"]);
    },
  );

  testWidgets(
    'clear all is centered above apply and keeps categories in place',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapFilterButton(
              featureLayer: null,
              loadFilters: () async => ['Community Center', 'Student Services'],
              onDefinitionExpressionChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Filter'));
      await tester.pumpAndSettle();

      final chipFinder = find.ancestor(
        of: find.text('Community Center'),
        matching: find.byType(FilterChip),
      );
      final chipBefore = tester.getTopLeft(chipFinder);
      expect(find.text('Clear all'), findsNothing);

      await tester.tap(find.text('Community Center'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all'), findsOneWidget);
      expect(tester.getTopLeft(chipFinder), chipBefore);

      final clearAll = tester.getCenter(find.text('Clear all'));
      final apply = tester.getCenter(find.text('Apply (1 selected)'));
      expect(clearAll.dy, greaterThan(chipBefore.dy));
      expect(clearAll.dy, lessThan(apply.dy));
      expect((clearAll.dx - apply.dx).abs(), lessThan(0.5));

      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      expect(find.text('Clear all'), findsNothing);
      expect(find.text('Show All'), findsOneWidget);
      expect(tester.widget<FilterChip>(chipFinder).selected, isFalse);
    },
  );

  testWidgets('filter options match the community layer panel in dark mode', (
    tester,
  ) async {
    final colors = AccessibilityColors.normalDark;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(colorSafePalette: false, highContrast: false),
        darkTheme: AppTheme.dark(colorSafePalette: false, highContrast: false),
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: MapFilterButton(
            featureLayer: null,
            loadFilters: () async => ['Community Center', 'Student Services'],
            onDefinitionExpressionChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.text('Filter by Category'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Material && widget.color == colors.cardBackground,
        ),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.text('Community Center')).style?.color,
      colors.primaryText,
    );

    final chipFinder = find.ancestor(
      of: find.text('Community Center'),
      matching: find.byType(FilterChip),
    );
    expect(
      tester.widget<FilterChip>(chipFinder).side!.color,
      colors.primaryText,
    );

    await tester.tap(find.text('Community Center'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text('Community Center')).style?.color,
      colors.onPrimary,
    );
    expect(
      tester.widget<FilterChip>(chipFinder).side!.color,
      colors.primaryText,
    );
  });
}

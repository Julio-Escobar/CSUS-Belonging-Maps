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
}

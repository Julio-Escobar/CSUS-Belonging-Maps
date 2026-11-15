import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/widgets/map_search_bar.dart';
import 'package:belonging_maps_app/widgets/search_suggestion_list.dart';

import 'helpers/semantics_finders.dart';

void main() {
  testWidgets('exposes a location suggestion as an accessible action', (
    tester,
  ) async {
    var selected = false;
    final controller = TextEditingController(text: 'student');
    final semantics = tester.ensureSemantics();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: MapSearchBar(
              controller: controller,
              onChanged: (_) {},
              suggestions: [
                SearchSuggestion(
                  title: 'Student Union',
                  subtitle: 'Campus locations',
                  onSelected: () => selected = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.text('Student Union'), findsOneWidget);

    await tester.tapAt(const Offset(20, 500));
    await tester.pump();
    expect(find.text('Student Union'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.text('Student Union'), findsOneWidget);

    tester.semantics.tap(
      semanticTapByLabel(RegExp('^Open Student Union, Campus locations\$')),
    );
    await tester.pump();
    expect(selected, isTrue);
    semantics.dispose();
  });

  testWidgets('uses the same colors as the other map controls', (tester) async {
    final colors = AccessibilityColors.forSettings(
      colorSafePalette: true,
      highContrast: false,
    );
    final controller = TextEditingController(text: 'student');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(colorSafePalette: true, highContrast: false),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: MapSearchBar(controller: controller, onChanged: (_) {}),
          ),
        ),
      ),
    );

    expect(
      find.ancestor(
        of: find.byType(TextField),
        matching: find.byWidgetPredicate(
          (widget) => widget is Material && widget.color == colors.primary,
        ),
      ),
      findsOneWidget,
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.color, colors.onPrimary);
    expect(field.cursorColor, colors.onPrimary);
    expect(
      field.decoration?.labelStyle?.color,
      colors.onPrimary.withValues(alpha: 0.9),
    );
    expect(field.decoration?.floatingLabelStyle?.color, colors.onPrimary);
    expect(
      field.decoration?.hintStyle?.color,
      colors.onPrimary.withValues(alpha: 0.85),
    );
    expect(
      (field.decoration?.focusedBorder as OutlineInputBorder).borderSide.color,
      colors.onPrimary,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.search)).color,
      colors.onPrimary,
    );
    expect(
      tester.widget<Icon>(find.byIcon(Icons.clear)).color,
      colors.onPrimary,
    );
  });
}

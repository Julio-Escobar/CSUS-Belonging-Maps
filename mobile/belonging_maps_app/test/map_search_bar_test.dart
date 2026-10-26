import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:belonging_maps_app/widgets/map_search_bar.dart';
import 'package:belonging_maps_app/widgets/search_suggestion_list.dart';

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

    await tester.tap(
      find.bySemanticsLabel(RegExp('^Open Student Union, Campus locations\$')),
    );
    expect(selected, isTrue);
    semantics.dispose();
  });
}

import 'package:belonging_maps_app/widgets/location_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// P1-336: location cards show a scrollbar only when their content overflows,
// and the scroll region stays usable with large text and screen readers.

Future<void> _pumpCard(
  WidgetTester tester, {
  required String description,
  bool showFullInfo = true,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final data = LocationInfoData.fromAttributes({
    'Company_Name': 'La Fiesta Market',
    'ADDRESS': '1234 Broadway, Sacramento, CA',
    'DESCRIPTION': description,
  }, fallbackCategory: 'Food');

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: LocationInfoCard(
          data: data,
          showFullInfo: showFullInfo,
          onClose: () {},
          onShowMore: () {},
          onShowLess: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ScrollPosition _cardScrollPosition(WidgetTester tester) {
  final scrollable = tester.state<ScrollableState>(
    find.descendant(
      of: find.byType(LocationCardScrollArea),
      matching: find.byType(Scrollable),
    ),
  );
  return scrollable.position;
}

final _longDescription = List.filled(
  40,
  'Family-owned grocery with fresh produce, a hot food counter, and a bakery.',
).join(' ');

void main() {
  testWidgets('long cards overflow and show a visible scrollbar', (
    tester,
  ) async {
    await _pumpCard(tester, description: _longDescription);

    expect(find.byKey(const Key('locationCardScrollbar')), findsOneWidget);
    final scrollbar = tester.widget<RawScrollbar>(
      find.byKey(const Key('locationCardScrollbar')),
    );
    expect(scrollbar.thumbVisibility, isTrue);
    expect(_cardScrollPosition(tester).maxScrollExtent, greaterThan(0));
  });

  testWidgets('scrollbar follows the scroll position', (tester) async {
    await _pumpCard(tester, description: _longDescription);
    final position = _cardScrollPosition(tester);
    expect(position.pixels, 0);

    await tester.drag(
      find.byType(LocationCardScrollArea),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(position.pixels, greaterThan(0));
  });

  testWidgets('short cards have nothing to scroll', (tester) async {
    await _pumpCard(tester, description: 'Groceries.', showFullInfo: false);

    expect(_cardScrollPosition(tester).maxScrollExtent, 0);
  });

  testWidgets('actions at the bottom stay reachable by scrolling', (
    tester,
  ) async {
    await _pumpCard(tester, description: _longDescription);

    await tester.scrollUntilVisible(
      find.text('Show less'),
      200,
      scrollable: find.descendant(
        of: find.byType(LocationCardScrollArea),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Show less').hitTestable(), findsOneWidget);
  });

  testWidgets('content keeps a gutter so the thumb never covers it', (
    tester,
  ) async {
    await _pumpCard(tester, description: _longDescription);

    final area = tester.getRect(find.byType(LocationCardScrollArea));
    final address = tester.getRect(find.text('1234 Broadway, Sacramento, CA'));
    expect(
      area.right - address.right,
      greaterThanOrEqualTo(LocationCardScrollArea.scrollbarGutter),
    );
  });

  testWidgets('exposes a labelled scrollable region at 200% text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpCard(tester, description: _longDescription, textScale: 2);

    expect(
      find.semantics.byPredicate((node) {
        final data = node.getSemanticsData();
        return data.label == 'Location details';
      }),
      findsOne,
    );
    expect(
      find.semantics.byPredicate((node) {
        final data = node.getSemanticsData();
        return data.hasAction(SemanticsAction.scrollUp) ||
            data.hasAction(SemanticsAction.scrollDown);
      }),
      findsAtLeast(1),
    );
    semantics.dispose();
  });
}

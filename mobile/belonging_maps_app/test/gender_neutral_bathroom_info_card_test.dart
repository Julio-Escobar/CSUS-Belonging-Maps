import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/widgets/gender_neutral_bathroom_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildCard({
  String buildingName = 'University Union',
  String floor = '1, 2, 3',
  String description =
      'One inside the Pride Center, one across from Starbucks, and one in '
      'the CARES and Food Pantry hallway.',
  VoidCallback? onClose,
}) {
  return MaterialApp(
    theme: AppTheme.light(colorSafePalette: false, highContrast: false),
    home: Scaffold(
      body: GenderNeutralBathroomInfoCard(
        buildingName: buildingName,
        floor: floor,
        description: description,
        onClose: onClose ?? () {},
      ),
    ),
  );
}

void main() {
  testWidgets('shows the name, floor, and description immediately', (
    tester,
  ) async {
    await tester.pumpWidget(buildCard());

    expect(find.text('University Union'), findsOneWidget);
    expect(find.text('Floor 1, 2, 3'), findsOneWidget);
    expect(
      find.text(
        'One inside the Pride Center, one across from Starbucks, and one in '
        'the CARES and Food Pantry hallway.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Type:'), findsNothing);
    expect(find.text('More information'), findsNothing);
    expect(find.text('Show less'), findsNothing);
    expect(find.text('Open in Maps'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('close button invokes the dismiss callback', (tester) async {
    var closed = false;
    await tester.pumpWidget(buildCard(onClose: () => closed = true));

    await tester.tap(find.byTooltip('Close location details'));

    expect(closed, isTrue);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      buildCard(
        buildingName: 'Ernest E Tschannen Science Complex',
        description:
            'One on each floor by the gendered restrooms. This description is '
            'long enough to require the popup to scroll on a small screen.',
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byTooltip('Close location details').hitTestable(),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}

import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/widgets/lactation_room_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the building and official room information', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(colorSafePalette: false, highContrast: false),
        home: Scaffold(
          body: LactationRoomInfoCard(
            buildingName: 'Tahoe Hall',
            roomInfo: 'In Tahoe Hall 2002 and Tahoe Hall 3006',
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('Tahoe Hall'), findsOneWidget);
    expect(find.text('In Tahoe Hall 2002 and Tahoe Hall 3006'), findsOneWidget);
    expect(find.semantics.byLabel('Lactation room details'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(colorSafePalette: false, highContrast: false),
        home: Scaffold(
          body: LactationRoomInfoCard(
            buildingName: 'Ernest E Tschannen Science Building',
            roomInfo:
                'First floor. This room detail remains readable with large '
                'text on a small phone.',
            onClose: () {},
          ),
        ),
      ),
    );

    expect(
      find.byTooltip('Close location details').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}

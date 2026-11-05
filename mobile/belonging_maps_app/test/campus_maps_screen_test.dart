import 'package:belonging_maps_app/screens/campus_maps_screen.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/widgets/map_selection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Records how the screen asks the platform to open the map site.
class FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  FakeUrlLauncherPlatform({this.result = true, this.error});

  bool result;
  Object? error;
  int launchCount = 0;
  String? launchedUrl;
  PreferredLaunchMode? launchedMode;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchCount++;
    launchedUrl = url;
    launchedMode = options.mode;
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }
}

Future<void> pumpCampusMaps(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(colorSafePalette: false, highContrast: false),
      home: const CampusMapsScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get interactiveMapButton =>
    find.widgetWithText(ElevatedButton, 'Interactive Campus Map');

Finder get genderNeutralBathroomsButton =>
    find.widgetWithText(ElevatedButton, 'Gender Neutral Bathrooms');

void main() {
  late FakeUrlLauncherPlatform launcher;
  late UrlLauncherPlatform originalLauncher;

  setUp(() {
    originalLauncher = UrlLauncherPlatform.instance;
    launcher = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = launcher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalLauncher;
  });

  testWidgets('shows the map launch buttons above the campus map cards', (
    tester,
  ) async {
    await pumpCampusMaps(tester);

    expect(interactiveMapButton, findsOneWidget);
    expect(genderNeutralBathroomsButton, findsOneWidget);
    // Three campus maps plus the duplicated SOMOS card lower on the page.
    expect(find.byType(MapSelectionCard), findsNWidgets(4));

    final buttonRect = tester.getRect(interactiveMapButton);
    final bathroomsButtonRect = tester.getRect(genderNeutralBathroomsButton);
    final firstCardRect = tester.getRect(find.byType(MapSelectionCard).first);
    expect(buttonRect.top, lessThan(firstCardRect.top));
    expect(buttonRect.height, greaterThanOrEqualTo(48));
    expect(bathroomsButtonRect.top, greaterThan(buttonRect.bottom));
    expect(bathroomsButtonRect.top, lessThan(firstCardRect.top));
    expect(bathroomsButtonRect.height, greaterThanOrEqualTo(48));
  });

  testWidgets('opens the map site in the in-app browser', (tester) async {
    await pumpCampusMaps(tester);

    await tester.tap(interactiveMapButton);
    await tester.pumpAndSettle();

    expect(launcher.launchCount, 1);
    expect(launcher.launchedUrl, interactiveCampusMapUrl);
    expect(launcher.launchedMode, PreferredLaunchMode.inAppBrowserView);

    // The browser is an overlay, so the directory never loses its place.
    expect(find.byType(CampusMapsScreen), findsOneWidget);
    expect(find.text('Unable to open the campus map'), findsNothing);
  });

  testWidgets('failed launch shows an error state that can be dismissed', (
    tester,
  ) async {
    launcher.result = false;
    await pumpCampusMaps(tester);

    await tester.tap(interactiveMapButton);
    await tester.pumpAndSettle();

    expect(find.text('Unable to open the campus map'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);

    await tester.tap(find.text('Go Back'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to open the campus map'), findsNothing);
    expect(find.byType(CampusMapsScreen), findsOneWidget);
    expect(interactiveMapButton, findsOneWidget);
  });

  testWidgets('Try Again retries the launch from the error state', (
    tester,
  ) async {
    launcher.result = false;
    await pumpCampusMaps(tester);

    await tester.tap(interactiveMapButton);
    await tester.pumpAndSettle();
    expect(launcher.launchCount, 1);

    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(launcher.launchCount, 2);
    expect(find.text('Unable to open the campus map'), findsOneWidget);
  });

  testWidgets('a launch exception shows the error state', (tester) async {
    launcher.error = PlatformException(code: 'launch_failure');
    await pumpCampusMaps(tester);

    await tester.tap(interactiveMapButton);
    await tester.pumpAndSettle();

    expect(find.text('Unable to open the campus map'), findsOneWidget);
    expect(find.text('Go Back'), findsOneWidget);
  });

  testWidgets('fits a small phone with large text and keeps its tap target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpCampusMaps(tester);
    await tester.ensureVisible(interactiveMapButton);

    final rect = tester.getRect(interactiveMapButton);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(320));
    expect(rect.width, greaterThanOrEqualTo(48));
    expect(rect.height, greaterThanOrEqualTo(48));
    expect(interactiveMapButton.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(genderNeutralBathroomsButton);
    final bathroomsRect = tester.getRect(genderNeutralBathroomsButton);
    expect(bathroomsRect.left, greaterThanOrEqualTo(0));
    expect(bathroomsRect.right, lessThanOrEqualTo(320));
    expect(bathroomsRect.width, greaterThanOrEqualTo(48));
    expect(bathroomsRect.height, greaterThanOrEqualTo(48));
    expect(genderNeutralBathroomsButton.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}

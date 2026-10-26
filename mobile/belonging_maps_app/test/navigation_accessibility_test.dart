import 'package:belonging_maps_app/main.dart';
import 'package:belonging_maps_app/screens/accessibility_settings_screen.dart';
import 'package:belonging_maps_app/screens/campus_maps_screen.dart';
import 'package:belonging_maps_app/screens/community_maps_directory.dart';
import 'package:belonging_maps_app/screens/welcome_screen.dart';
import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/widgets/map_selection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  bool colorSafe = false,
  bool highContrast = false,
  NavigatorObserver? observer,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(
        colorSafePalette: colorSafe,
        highContrast: highContrast,
      ),
      highContrastTheme: AppTheme.light(
        colorSafePalette: colorSafe,
        highContrast: true,
      ),
      navigatorObservers: [if (observer != null) observer],
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

class RouteRecorder extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) pushed.add(route);
  }
}

void main() {
  const pages = [WelcomeScreen(), CampusMapsScreen(), CommunityMapsDirectory()];

  testWidgets('one card action supports both screen readers and touch', (
    tester,
  ) async {
    var activations = 0;
    await pumpPage(
      tester,
      Scaffold(
        body: MapSelectionCard(
          label: 'SOMOS Campus Map',
          subtitle: 'SOMOS Campus',
          imagePath: 'assets/somoscampusmap.png',
          onTap: () => activations++,
        ),
      ),
    );

    final action = find.semantics.byLabel('SOMOS Campus Map. SOMOS Campus');
    expect(action, findsOne);
    expect(find.semantics.byFlag(SemanticsFlag.isButton), findsOne);
    tester.semantics.tap(action);
    expect(activations, 1);
    await tester.tap(find.byType(MapSelectionCard));
    expect(activations, 2);
    expect(action.evaluate().single.childrenCount, 0);
  });

  for (final (page, destinations) in [
    (
      const CampusMapsScreen(),
      ['SomosCampusMap', 'UmmahCampusMap', 'UbuntuCampusMap', 'SomosCampusMap'],
    ),
    (
      const CommunityMapsDirectory(),
      [
        'SomosCommunityMap',
        'UmmahCommunityMap',
        'UbuntuCommunityMap',
        'SomosCommunityMap',
        'UmmahCommunityMap',
        'UbuntuCommunityMap',
      ],
    ),
  ]) {
    testWidgets(
      '${page.runtimeType} cards keep their destination and semantic action',
      (tester) async {
        final observer = RouteRecorder();
        await pumpPage(tester, page, observer: observer);
        expect(
          find.byType(MapSelectionCard),
          findsNWidgets(destinations.length),
        );

        for (var i = 0; i < destinations.length; i++) {
          final cardFinder = find.byType(MapSelectionCard).at(i);
          await tester.ensureVisible(cardFinder);
          await tester.pumpAndSettle();
          final card = tester.widget<MapSelectionCard>(cardFinder);
          final action = find.semantics.byLabel(
            '${card.label}. ${card.subtitle}',
          );
          expect(action, findsOne);
          tester.semantics.tap(action);
          expect(observer.pushed.length, i + 1);
          final route = observer.pushed.last as MaterialPageRoute<dynamic>;
          expect(
            route.builder(tester.element(cardFinder)).runtimeType.toString(),
            destinations[i],
          );

          // Inspect the destination without mounting the native ArcGIS view.
          observer.navigator!.removeRoute(route);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('Welcome actions open both directories and return with Back', (
    tester,
  ) async {
    await pumpPage(tester, const WelcomeScreen());
    expect(find.semantics.byLabel('Belonging Maps logo'), findsOne);

    for (final (label, type) in [
      ('Campus Maps', CampusMapsScreen),
      ('Community Maps', CommunityMapsDirectory),
    ]) {
      tester.semantics.tap(find.semantics.byLabel(label));
      await tester.pumpAndSettle();
      expect(find.byType(type), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
    }
  });

  testWidgets(
    'closed menu has no hidden actions and the open menu hides page actions',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpPage(tester, const WelcomeScreen());
      expect(find.semantics.byLabel('Accessibility Settings'), findsNothing);
      expect(find.semantics.byLabel('Campus Maps'), findsOne);
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pump();
      expect(find.semantics.byLabel('Campus Maps'), findsOne);
      expect(find.semantics.byLabel('Belonging Maps logo'), findsNothing);
      final drawer = tester.widget<AnimatedPositioned>(
        find.byType(AnimatedPositioned),
      );
      expect(drawer.left, 0);
      expect(drawer.duration, Duration.zero);
      await tester.ensureVisible(find.text('Accessibility Settings'));
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel('Accessibility Settings'), findsOne);
      await tester.tap(find.byTooltip('Close navigation menu'));
      await tester.pump();
      expect(find.semantics.byLabel('Accessibility Settings'), findsNothing);
      expect(find.semantics.byLabel('Belonging Maps logo'), findsOne);
    },
  );

  for (final page in pages) {
    testWidgets(
      '${page.runtimeType} fits large text on a small phone with device accessibility enabled',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(
              highContrast: true,
              boldText: true,
              disableAnimations: true,
              accessibleNavigation: true,
            );
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await pumpPage(tester, const WelcomeScreen());
        if (page is! WelcomeScreen) {
          final label = page is CampusMapsScreen
              ? 'Campus Maps'
              : 'Community Maps';
          tester.semantics.tap(find.semantics.byLabel(label));
          await tester.pumpAndSettle();
        }

        final context = tester.element(find.byType(page.runtimeType));
        final media = MediaQuery.of(context);
        expect(media.textScaler.scale(16), 32);
        expect(media.highContrast, isTrue);
        expect(media.boldText, isTrue);
        expect(media.disableAnimations, isTrue);
        expect(media.accessibleNavigation, isTrue);
        expect(AccessibilityColors.of(context).outline, Colors.black);
        final title = page is WelcomeScreen
            ? 'Belonging Maps'
            : page is CampusMapsScreen
            ? 'Campus Maps'
            : 'Community Maps';
        expect(find.semantics.byLabel(title), findsOne);
        final controls = page is WelcomeScreen
            ? find.byType(ElevatedButton)
            : find.byType(MapSelectionCard);
        for (var i = 0; i < controls.evaluate().length; i++) {
          await tester.ensureVisible(controls.at(i));
          await tester.pumpAndSettle();
          final rect = tester.getRect(controls.at(i));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(320));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
          expect(controls.at(i).hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          for (final element
              in find
                  .descendant(
                    of: controls.at(i),
                    matching: find.byType(RichText),
                  )
                  .evaluate()) {
            expect(
              (element.renderObject! as RenderParagraph).didExceedMaxLines,
              isFalse,
            );
          }
        }
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      },
    );
  }

  for (final colorSafe in [false, true]) {
    for (final highContrast in [false, true]) {
      testWidgets(
        'all pages use the palette: colorSafe=$colorSafe highContrast=$highContrast',
        (tester) async {
          final colors = AccessibilityColors.forSettings(
            colorSafePalette: colorSafe,
            highContrast: highContrast,
          );
          for (final page in pages) {
            await pumpPage(
              tester,
              page,
              colorSafe: colorSafe,
              highContrast: highContrast,
            );
            final context = tester.element(find.byType(page.runtimeType));
            expect(AccessibilityColors.of(context).primary, colors.primary);
            final scaffold = tester.widget<Scaffold>(
              find.byType(Scaffold).last,
            );
            expect(
              scaffold.backgroundColor,
              page is WelcomeScreen ? colors.primary : colors.pageBackground,
            );
            expect(
              Theme.of(context).appBarTheme.backgroundColor,
              colors.primary,
            );
            if (page is WelcomeScreen) {
              final button = tester.widget<ElevatedButton>(
                find.byType(ElevatedButton).first,
              );
              expect(
                button.style!.foregroundColor!.resolve({}),
                colors.primary,
              );
              expect(
                button.style!.backgroundColor!.resolve({}),
                colors.cardBackground,
              );
            } else {
              final caption = find.descendant(
                of: find.byType(MapSelectionCard).first,
                matching: find.byType(Text),
              );
              expect(
                tester.widget<Text>(caption.first).style!.color,
                colors.primaryText,
              );
              expect(
                tester.widget<Text>(caption.last).style!.color,
                colors.secondaryText,
              );
            }
            expect(tester.takeException(), isNull);
          }
          for (final (foreground, background) in [
            (colors.onPrimary, colors.primary),
            (colors.primary, colors.pageBackground),
            (colors.primary, colors.cardBackground),
            (colors.primaryText, colors.cardBackground),
            (colors.secondaryText, colors.cardBackground),
            (colors.secondaryText, colors.pageBackground),
            (colors.action, colors.cardBackground),
          ]) {
            final a = foreground.computeLuminance();
            final b = background.computeLuminance();
            final ratio = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
            expect(ratio, greaterThanOrEqualTo(4.5));
          }
        },
      );
    }
  }

  testWidgets(
    'settings changes reach all pages and survive app reconstruction',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = await AccessibilitySettingsController.load();
      addTearDown(settings.dispose);
      await tester.pumpWidget(BelongingMapsApp(settings: settings));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Accessibility Settings'));
      await tester.tap(find.text('Accessibility Settings'));
      await tester.pumpAndSettle();
      expect(find.byType(AccessibilitySettingsScreen), findsOneWidget);
      for (final title in [
        'Color-safe palette',
        'App high-contrast fallback',
      ]) {
        await tester.tap(find.widgetWithText(SwitchListTile, title));
        await tester.pumpAndSettle();
      }
      await tester.pageBack();
      await tester.pumpAndSettle();

      Future<void> checkPages() async {
        final welcome = tester.element(find.byType(WelcomeScreen));
        expect(
          AccessibilityColors.of(welcome).primary,
          AccessibilityColors.colorSafe.primary,
        );
        expect(AccessibilityColors.of(welcome).outline, Colors.black);
        for (final (label, type) in [
          ('Campus Maps', CampusMapsScreen),
          ('Community Maps', CommunityMapsDirectory),
        ]) {
          final button = find.widgetWithText(ElevatedButton, label);
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          await tester.tap(button);
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(type));
          expect(
            AccessibilityColors.of(context).primary,
            AccessibilityColors.colorSafe.primary,
          );
          expect(AccessibilityColors.of(context).outline, Colors.black);
          await tester.pageBack();
          await tester.pumpAndSettle();
        }
      }

      await checkPages();
      await tester.pumpWidget(const SizedBox.shrink());
      final restored = await AccessibilitySettingsController.load();
      addTearDown(restored.dispose);
      expect(restored.colorSafePalette, isTrue);
      expect(restored.highContrastFallback, isTrue);
      await tester.pumpWidget(BelongingMapsApp(settings: restored));
      await tester.pumpAndSettle();
      await checkPages();
    },
  );
}

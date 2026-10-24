import 'package:belonging_maps_app/models/forum_post.dart';
import 'package:belonging_maps_app/screens/community_resources_screen.dart';
import 'package:belonging_maps_app/screens/forums_screen.dart';
import 'package:belonging_maps_app/screens/opportunities.dart';
import 'package:belonging_maps_app/screens/organization_resources_screen.dart';
import 'package:belonging_maps_app/screens/surveys_screen.dart';
import 'package:belonging_maps_app/services/accessibility_settings.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'package:flutter/material.dart';
import 'helpers/fake_community_resources_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(useFakeCommunityResourcesApi);

  final screens = <_AdminScreenCase>[
    _AdminScreenCase(
      name: 'Opportunities',
      build: () => const OpportunitiesScreen(),
      action: () => find.byTooltip('Add opportunity'),
      dialogTitle: 'Add Opportunity',
      addLink: true,
    ),
    _AdminScreenCase(
      name: 'Surveys',
      build: () => const SurveysScreen(),
      action: () => find.byTooltip('Add survey'),
      dialogTitle: 'Add Survey',
    ),
    _AdminScreenCase(
      name: 'Community Resources',
      build: () => const CommunityResourcesScreen(),
      action: () => find.byTooltip('Add resource'),
      dialogTitle: 'Add Resource',
    ),
    _AdminScreenCase(
      name: 'Organization Resources',
      build: () => const OrganizationResourcesScreen(),
      action: () => find.byTooltip('Add resource'),
      dialogTitle: 'Add Resource',
    ),
    _AdminScreenCase(
      name: 'Forums',
      build: () => ForumsScreen(
        posts: [
          ForumPost(
            title: 'A long forum title that should wrap on a narrow phone',
            author: 'A community member with a long display name',
            postedAt: DateTime(2026, 10, 10, 12),
            bodyPreview:
                'This forum post has enough text to check that the card grows and the content remains readable at a larger text size.',
          ),
        ],
      ),
      action: () => find.byTooltip(
        'Delete A long forum title that should wrap on a narrow phone',
      ),
      dialogTitle: 'Delete this post?',
      isConfirmation: true,
    ),
  ];

  for (final screen in screens) {
    testWidgets(
      '${screen.name} stays usable with 200% text on a narrow screen',
      (tester) async {
        AuthService.isAdmin = true;
        addTearDown(() => AuthService.isAdmin = false);
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pumpAdminScreen(tester, screen.build());

        expect(find.byType(Card), findsWidgets);
        expect(find.byType(ListView), findsWidgets);
        final cardFinder = find.byType(Card).first;
        final card = tester.widget<Card>(cardFinder);
        final theme = Theme.of(tester.element(cardFinder));
        final colors = AccessibilityColors.of(tester.element(cardFinder));
        expect(card.color ?? theme.cardTheme.color, colors.cardBackground);
        expect(tester.takeException(), isNull, reason: screen.name);

        final action = screen.action();
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();

        expect(find.text(screen.dialogTitle), findsOneWidget);
        if (screen.isConfirmation) {
          expect(find.text('Delete'), findsOneWidget);
        } else {
          expect(find.byType(TextFormField), findsWidgets);
        }

        if (screen.addLink) {
          await tester.tap(find.text('Add Link'));
          await tester.pumpAndSettle();
        }

        expect(tester.takeException(), isNull, reason: screen.name);
      },
    );
  }

  final editScreens = <_EditScreenCase>[
    _EditScreenCase(
      name: 'Opportunities',
      build: () => const OpportunitiesScreen(),
      action: () => find.byTooltip('Edit SOMOS Scholarships'),
      dialogTitle: 'Edit Opportunity',
    ),
    _EditScreenCase(
      name: 'Surveys',
      build: () => const SurveysScreen(),
      action: () => find.byTooltip('Edit Feedback Survey'),
      dialogTitle: 'Edit Survey',
    ),
    _EditScreenCase(
      name: 'Community Resources',
      build: () => const CommunityResourcesScreen(),
      action: () => find.byTooltip('Edit Food Pantry'),
      dialogTitle: 'Edit Resource',
    ),
    _EditScreenCase(
      name: 'Organization Resources',
      build: () => const OrganizationResourcesScreen(),
      action: () => find.byTooltip('Edit SOMOS Student Organization'),
      dialogTitle: 'Edit Resource',
    ),
  ];

  for (final screen in editScreens) {
    testWidgets('${screen.name} edit form stays usable with 200% text', (
      tester,
    ) async {
      AuthService.isAdmin = true;
      addTearDown(() => AuthService.isAdmin = false);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpAdminScreen(tester, screen.build());
      final action = screen.action();
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      expect(find.text(screen.dialogTitle), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
      expect(tester.takeException(), isNull, reason: screen.name);
    });
  }

  final detailsScreens = <_DetailsScreenCase>[
    _DetailsScreenCase(
      name: 'Opportunities',
      build: () => const OpportunitiesScreen(),
      action: () => find.text('SOMOS Scholarships').first,
      details: 'Tap a scholarship to visit its website',
    ),
    _DetailsScreenCase(
      name: 'Community Resources',
      build: () => const CommunityResourcesScreen(),
      action: () => find.text('Food Pantry').first,
      details: 'Resource information',
    ),
    _DetailsScreenCase(
      name: 'Organization Resources',
      build: () => const OrganizationResourcesScreen(),
      action: () => find.text('SOMOS Student Organization').first,
      details: 'Resource information',
    ),
  ];

  for (final screen in detailsScreens) {
    testWidgets('${screen.name} details stay usable with 200% text', (
      tester,
    ) async {
      AuthService.isAdmin = true;
      addTearDown(() => AuthService.isAdmin = false);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpAdminScreen(tester, screen.build());
      await tester.tap(screen.action());
      await tester.pumpAndSettle();

      expect(find.text(screen.details), findsOneWidget);
      expect(tester.takeException(), isNull, reason: screen.name);
    });
  }

  test('the app theme gives high contrast to cards, dialogs, and messages', () {
    final colors = AccessibilityColors.forSettings(
      colorSafePalette: true,
      highContrast: true,
    );
    final theme = AppTheme.light(colorSafePalette: true, highContrast: true);
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;

    expect(theme.cardTheme.color, colors.cardBackground);
    expect(cardShape.side.color, colors.outline);
    expect(theme.dialogTheme.backgroundColor, colors.cardBackground);
    expect(theme.snackBarTheme.backgroundColor, colors.primaryText);
    expect(theme.snackBarTheme.contentTextStyle?.color, colors.cardBackground);
    expect(
      theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
      colors.primary,
    );
  });

  testWidgets('delete confirmations use the selected destructive color', (
    tester,
  ) async {
    final deleteScreens = <_DeleteScreenCase>[
      _DeleteScreenCase(
        build: () => const OpportunitiesScreen(),
        action: () => find.byTooltip('Delete SOMOS Scholarships'),
      ),
      _DeleteScreenCase(
        build: () => const SurveysScreen(),
        action: () => find.byTooltip('Delete Feedback Survey'),
      ),
      _DeleteScreenCase(
        build: () => const CommunityResourcesScreen(),
        action: () => find.byTooltip('Delete Food Pantry'),
      ),
      _DeleteScreenCase(
        build: () => const OrganizationResourcesScreen(),
        action: () => find.byTooltip('Delete SOMOS Student Organization'),
      ),
      _DeleteScreenCase(
        build: () => ForumsScreen(
          posts: [
            ForumPost(
              title: 'A forum post',
              author: 'A community member',
              postedAt: DateTime(2026, 10, 10),
              bodyPreview: 'A post to test its delete confirmation.',
            ),
          ],
        ),
        action: () => find.byTooltip('Delete A forum post'),
      ),
    ];

    AuthService.isAdmin = true;
    addTearDown(() => AuthService.isAdmin = false);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final screen in deleteScreens) {
      await _pumpAdminScreen(tester, screen.build());
      final action = screen.action();
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();

      final deleteButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Delete'),
      );
      final colors = AccessibilityColors.of(
        tester.element(find.byType(AlertDialog).last),
      );
      expect(
        deleteButton.style?.backgroundColor?.resolve({}),
        colors.destructive,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the admin title fits at 200% text on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(colorSafePalette: true, highContrast: true),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: const HamburgerMenu(
            title: 'Community Resources',
            body: SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('the admin navigation menu removes motion when requested', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    addTearDown(() => AuthService.isAdmin = false);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const HamburgerMenu(body: SizedBox.expand()),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pump();

    expect(
      tester
          .widget<AnimatedPositioned>(find.byType(AnimatedPositioned))
          .duration,
      Duration.zero,
    );
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration,
      Duration.zero,
    );
  });
}

Future<void> _pumpAdminScreen(WidgetTester tester, Widget screen) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final settings = AccessibilitySettingsController(preferences);

  await tester.pumpWidget(
    AccessibilitySettingsScope(
      controller: settings,
      child: MaterialApp(
        theme: AppTheme.light(colorSafePalette: true, highContrast: true),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
            highContrast: true,
          ),
          child: screen,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _AdminScreenCase {
  const _AdminScreenCase({
    required this.name,
    required this.build,
    required this.action,
    required this.dialogTitle,
    this.addLink = false,
    this.isConfirmation = false,
  });

  final String name;
  final Widget Function() build;
  final Finder Function() action;
  final String dialogTitle;
  final bool addLink;
  final bool isConfirmation;
}

class _DeleteScreenCase {
  const _DeleteScreenCase({required this.build, required this.action});

  final Widget Function() build;
  final Finder Function() action;
}

class _EditScreenCase {
  const _EditScreenCase({
    required this.name,
    required this.build,
    required this.action,
    required this.dialogTitle,
  });

  final String name;
  final Widget Function() build;
  final Finder Function() action;
  final String dialogTitle;
}

class _DetailsScreenCase {
  const _DetailsScreenCase({
    required this.name,
    required this.build,
    required this.action,
    required this.details,
  });

  final String name;
  final Widget Function() build;
  final Finder Function() action;
  final String details;
}

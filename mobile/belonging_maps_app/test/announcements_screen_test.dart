import 'dart:convert';

import 'package:belonging_maps_app/screens/announcements_screen.dart';
import 'package:belonging_maps_app/services/auth_service.dart';
import 'package:belonging_maps_app/widgets/full_screen_image_viewer.dart';
import 'package:belonging_maps_app/widgets/hamburger_menu.dart';
import 'package:belonging_maps_app/widgets/resource_image.dart';
import 'package:belonging_maps_app/widgets/resource_image_field.dart';
import 'helpers/fake_api.dart';
import 'helpers/fake_community_resources_api.dart';
import 'helpers/semantics_finders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _RecordingUrlLauncher extends UrlLauncherPlatform {
  final List<String> launchedUrls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }
}

void main() {
  late FakeCommunityResourcesApi api;
  late UrlLauncherPlatform originalLauncher;
  late _RecordingUrlLauncher launcher;

  setUp(() {
    api = useFakeCommunityResourcesApi();
    originalLauncher = UrlLauncherPlatform.instance;
    launcher = _RecordingUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalLauncher;
    AuthService.isAdmin = false;
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AnnouncementsScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens Announcements from the hamburger menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HamburgerMenu(body: const Scaffold(body: SizedBox.expand())),
      ),
    );

    final semantics = tester.ensureSemantics();
    tester.semantics.tap(semanticTapByTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    tester.semantics.tap(semanticTapByLabel('Announcements'));
    await tester.pumpAndSettle();

    expect(find.text('Food Pantry'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Announcements'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Announcements is the highlighted drawer destination', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    ListTile tileFor(String label) =>
        tester.widget<ListTile>(find.widgetWithText(ListTile, label));

    expect(tileFor('Announcements').selected, isTrue);
    expect(tileFor('Scholarships').selected, isFalse);
  });

  testWidgets('shows a loading spinner, then resources from the API', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AnnouncementsScreen()),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Food Pantry'), findsOneWidget);
    expect(find.text('Mental Health Services'), findsOneWidget);
  });

  testWidgets('lists resources and shows selected resource information', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Food Pantry'));
    await tester.pumpAndSettle();

    expect(find.text('Resource information'), findsOneWidget);
    expect(
      find.text(
        'Free food resources available for students and community members.',
      ),
      findsNWidgets(2),
    );
    expect(find.text('Open link'), findsNothing);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Resource information'), findsNothing);
  });

  testWidgets('tapping the photo in the resource dialog opens it full screen', (
    tester,
  ) async {
    loadTestEnv();
    api.resources.first['imageId'] = 42;
    await pumpScreen(tester);

    await tester.tap(find.text('Food Pantry'));
    await tester.pumpAndSettle();

    final dialogPhoto = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(ResourceImage),
    );
    expect(dialogPhoto, findsOneWidget);

    await tester.tap(dialogPhoto);
    await tester.pumpAndSettle();

    // The photo opens in the same zoomable viewer the info cards use.
    expect(find.byKey(fullScreenImageViewerKey), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);

    await tester.tap(find.byKey(fullScreenImageCloseKey));
    await tester.pumpAndSettle();

    // Closing the viewer leaves the resource dialog open behind it.
    expect(find.byKey(fullScreenImageViewerKey), findsNothing);
    expect(find.text('Resource information'), findsOneWidget);
  });

  testWidgets('tapping a card photo still opens the resource information', (
    tester,
  ) async {
    loadTestEnv();
    api.resources.first['imageId'] = 42;
    await pumpScreen(tester);

    await tester.tap(find.byType(ResourceImage).first);
    await tester.pumpAndSettle();

    expect(find.text('Resource information'), findsOneWidget);
    expect(find.byKey(fullScreenImageViewerKey), findsNothing);
  });

  testWidgets('a resource without a photo shows no photo to tap', (
    tester,
  ) async {
    loadTestEnv();
    await pumpScreen(tester);

    expect(find.byType(ResourceImage), findsNothing);
  });

  testWidgets('search filters by title and description and can be cleared', (
    tester,
  ) async {
    await pumpScreen(tester);

    final semantics = tester.ensureSemantics();
    final searchField = find.byType(TextField);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Search resources').first).label,
      'Search resources',
    );

    await tester.enterText(searchField, 'Counseling');
    await tester.pumpAndSettle();
    expect(find.text('Mental Health Services'), findsOneWidget);
    expect(find.text('Food Pantry'), findsNothing);

    await tester.enterText(searchField, 'Pantry');
    await tester.pumpAndSettle();
    expect(find.text('Food Pantry'), findsOneWidget);
    expect(find.text('Mental Health Services'), findsNothing);

    await tester.enterText(searchField, 'no resource matches this');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Food Pantry'), findsOneWidget);
    expect(find.text('Mental Health Services'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('shows an error with Retry when loading fails', (tester) async {
    api.failRequests = true;
    await pumpScreen(tester);

    expect(find.text("Couldn't load announcements"), findsOneWidget);
    expect(
      find.text("Couldn't load announcements (server error 500)."),
      findsOneWidget,
    );
    expect(find.text('Food Pantry'), findsNothing);

    api.failRequests = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't load announcements"), findsNothing);
    expect(find.text('Food Pantry'), findsOneWidget);
  });

  testWidgets('admin can open the add resource dialog', (tester) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    final semantics = tester.ensureSemantics();
    expect(find.byTooltip('Add resource'), findsOneWidget);

    tester.semantics.tap(semanticTapByTooltip('Add resource'));
    await tester.pumpAndSettle();

    expect(find.text('Add Resource'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('admin adds a resource and it is saved to the API', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Add resource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Book Exchange');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Trade used textbooks with other students.',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Education');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Resource added'), findsOneWidget);
    expect(api.resources.map((r) => r['title']), contains('Book Exchange'));
    expect(
      api.resources.firstWhere((r) => r['title'] == 'Book Exchange')['link'],
      isNull,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Book Exchange'), findsOneWidget);
  });

  testWidgets('a failed add keeps the form open with what the admin typed', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Add resource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Book Exchange');
    await tester.enterText(find.byType(TextFormField).at(1), 'Trade books.');
    await tester.enterText(find.byType(TextFormField).at(2), 'Education');

    api.failRequests = true;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    // Dialog is still open, shows the error, and kept the typed text.
    expect(find.text('Add Resource'), findsOneWidget);
    expect(find.textContaining("Couldn't add the resource"), findsOneWidget);
    expect(find.text('Book Exchange'), findsOneWidget);
    expect(find.text('Resource added'), findsNothing);

    // Retrying once the server is back saves it and closes the dialog.
    api.failRequests = false;
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Add Resource'), findsNothing);
    expect(find.text('Resource added'), findsOneWidget);
    expect(api.resources.map((r) => r['title']), contains('Book Exchange'));
  });

  testWidgets('admin adds a resource with an image', (tester) async {
    AuthService.isAdmin = true;
    // A real 1x1 PNG so the preview can decode it.
    ResourceImageField.pickImage = (_) async => base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    );
    addTearDown(() => ResourceImageField.pickImage = (_) async => null);
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Add resource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Garden Club');
    await tester.enterText(find.byType(TextFormField).at(1), 'Grow food.');
    await tester.enterText(find.byType(TextFormField).at(2), 'Food');

    await tester.ensureVisible(find.text('Add image'));
    await tester.tap(find.text('Add image'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from photos'));
    await tester.pumpAndSettle();

    // The picked photo is previewed and can be removed or changed.
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Selected image',
      ),
      findsOneWidget,
    );
    expect(find.text('Change image'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Resource added'), findsOneWidget);
    expect(api.uploadedImages, 1);
    final saved = api.resources.firstWhere((r) => r['title'] == 'Garden Club');
    expect(saved['imageId'], isNotNull);
  });

  testWidgets('admin can remove an image from a resource', (tester) async {
    AuthService.isAdmin = true;
    api.resources.first['imageId'] = 42;
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Edit Food Pantry'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Remove image'));
    await tester.tap(find.text('Remove image'));
    await tester.pumpAndSettle();
    expect(find.text('Add image'), findsOneWidget);

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Resource updated'), findsOneWidget);
    expect(api.resources.first['imageId'], isNull);
    expect(api.uploadedImages, 0);
  });

  testWidgets('admin adds a resource with an optional link', (tester) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Add resource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Food Drive');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Donate canned food for students.',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Food');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'https://example.edu/food-drive',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Resource added'), findsOneWidget);
    final saved = api.resources.firstWhere((r) => r['title'] == 'Food Drive');
    expect(saved['link'], 'https://example.edu/food-drive');
  });

  testWidgets('an invalid announcement link blocks saving', (tester) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Add resource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Book Exchange');
    await tester.enterText(find.byType(TextFormField).at(1), 'Trade books.');
    await tester.enterText(find.byType(TextFormField).at(2), 'Education');
    await tester.enterText(find.byType(TextFormField).at(3), 'not a link');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a full link starting with https://'),
      findsOneWidget,
    );
    expect(find.text('Add Resource'), findsOneWidget);
    expect(api.resources.any((r) => r['title'] == 'Book Exchange'), isFalse);
  });

  testWidgets('an announcement link opens from the details dialog', (
    tester,
  ) async {
    api.resources.first['link'] = 'https://example.edu/food-pantry';
    await pumpScreen(tester);

    await tester.tap(find.text('Food Pantry'));
    await tester.pumpAndSettle();

    expect(find.text('Open link'), findsOneWidget);
    await tester.tap(find.text('Open link'));
    await tester.pumpAndSettle();

    expect(launcher.launchedUrls, ['https://example.edu/food-pantry']);
  });

  testWidgets('admin can remove an announcement link', (tester) async {
    AuthService.isAdmin = true;
    api.resources.first['link'] = 'https://example.edu/food-pantry';
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Edit Food Pantry'));
    await tester.pumpAndSettle();
    expect(find.text('https://example.edu/food-pantry'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(3), '');
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Resource updated'), findsOneWidget);
    expect(api.resources.first['link'], isNull);
  });

  testWidgets('a resource added on one device shows up on another', (
    tester,
  ) async {
    // "Device A" adds a resource straight through the API.
    AuthService.isAdmin = true;
    await pumpScreen(tester);
    await tester.tap(find.byTooltip('Add resource'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Legal Aid');
    await tester.enterText(find.byType(TextFormField).at(1), 'Free legal help.');
    await tester.enterText(find.byType(TextFormField).at(2), 'Legal');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add'));
    await tester.pumpAndSettle();

    // "Device B" opens the screen fresh and loads from the same backend.
    AuthService.isAdmin = false;
    await tester.pumpWidget(const SizedBox());
    await pumpScreen(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.text('Legal Aid'), findsOneWidget);
  });

  testWidgets('admin can edit a resource', (tester) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Edit Food Pantry'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Resource'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Updated Food Pantry',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Updated community food access',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Wellness');

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Food Pantry'), findsOneWidget);
    expect(find.text('Resource updated'), findsOneWidget);
    expect(api.resources.first['title'], 'Updated Food Pantry');
  });

  testWidgets('admin can delete a resource after confirmation', (tester) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    expect(find.text('Food Pantry'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete Food Pantry'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Resource'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete this resource?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Resource deleted'), findsOneWidget);
    expect(find.text('Food Pantry'), findsNothing);
    expect(api.resources.any((r) => r['title'] == 'Food Pantry'), isFalse);
  });

  testWidgets('a failed save shows an error and keeps the list', (
    tester,
  ) async {
    AuthService.isAdmin = true;
    await pumpScreen(tester);

    api.failRequests = true;
    await tester.tap(find.byTooltip('Delete Food Pantry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.textContaining("Couldn't delete the resource"), findsOneWidget);
    expect(find.text('Food Pantry'), findsOneWidget);
  });
}

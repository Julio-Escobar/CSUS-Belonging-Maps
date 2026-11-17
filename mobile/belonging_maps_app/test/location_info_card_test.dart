import 'package:belonging_maps_app/widgets/full_screen_image_viewer.dart';
import 'package:belonging_maps_app/widgets/location_info_card.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

const String _foodIconAsset = 'assets/map_icons/food/HF11px.png';

/// Records how the card asks the platform to open a link.
///
/// [canLaunch] always returns false on purpose: the card must not depend on
/// that check, because Android 11+ and iOS report false for `tel:` and
/// `mailto:` unless the app declares the schemes.
class FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  FakeUrlLauncherPlatform({this.result = true, this.error});

  /// What [launchUrl] returns, simulating a missing phone or mail app.
  bool result;

  /// When set, [launchUrl] throws it, which is what iOS does for invalid URLs.
  Object? error;

  int launchCount = 0;
  String? launchedUrl;
  PreferredLaunchMode? launchedMode;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => false;

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

/// Location card data for a location with a website and contact details.
LocationInfoData _contactLocationData() {
  return LocationInfoData(
    cardTitle: 'PRIDE Center',
    address: 'University Union, Room 2230',
    category: 'Campus Centers',
    type: 'Center',
    website: 'https://www.csus.edu/pride-center/',
    phone: '(916) 278-1234',
    email: 'pride-center@csus.edu',
    description: 'A welcoming space for students.',
    imageUrl: null,
    socialLinks: const {},
  );
}

/// Location card data for a Latine art location that has a bundled photo.
LocationInfoData _artLocationData({String? imageAsset}) {
  return LocationInfoData(
    cardTitle: 'Chicano Park-RCAF',
    address: '6000 J Street, Sacramento, CA',
    category: 'Public Art and Artists',
    type: 'Sculpture',
    website: '',
    phone: '',
    email: '',
    description: 'No description available.',
    imageUrl: null,
    imageAsset: imageAsset,
    socialLinks: const {},
  );
}

/// Location card data for a Ummah campus center that has its own logo.
LocationInfoData _centerLocationData({
  BoxFit? orgLogoFit,
  Color? orgLogoBackgroundColor,
}) {
  return LocationInfoData(
    cardTitle: 'Southwest Asian and North African Center',
    address: 'AIRC, Room 1012',
    category: 'Campus Centers',
    type: '',
    website: 'https://www.csus.edu/',
    phone: '',
    email: '',
    description: 'A center.',
    imageUrl: null,
    socialLinks: const {},
    orgLogo:
        'assets/ummah_campus_map_assets/'
        'southwest_asian_and_north_african_center.png',
    orgLogoFit: orgLogoFit,
    orgLogoBackgroundColor: orgLogoBackgroundColor,
  );
}

/// Location card data for a numbered campus resource.
LocationInfoData _numberedLocationData({String number = '7'}) {
  return LocationInfoData(
    cardTitle: 'Associated Students, Inc. (ASI)',
    address: 'University Union',
    category: 'Campus Life',
    type: '',
    website: '',
    phone: '',
    email: '',
    description: 'A campus resource.',
    imageUrl: null,
    socialLinks: const {},
    orgLogoLabel: number,
    orgLogoBackgroundColor: mapInfoCardColor,
  );
}

/// Location card data for a location that bundles its own icon asset.
LocationInfoData _iconLocationData({String asset = _foodIconAsset}) {
  return LocationInfoData(
    cardTitle: 'Midtown Taqueria',
    address: 'University Union',
    category: 'Food',
    type: '',
    website: '',
    phone: '',
    email: '',
    description: 'A food option.',
    imageUrl: null,
    socialLinks: const {},
    orgLogo: asset,
  );
}

void main() {
  late UrlLauncherPlatform originalUrlLauncher;
  late FakeUrlLauncherPlatform launcher;

  setUp(() {
    originalUrlLauncher = UrlLauncherPlatform.instance;
    launcher = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = launcher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalUrlLauncher;
  });

  group('LocationInfoData.fromAttributes', () {
    test('maps sprint 4 popup fields from community map attributes', () {
      final data = LocationInfoData.fromAttributes({
        'Company_Name': 'PRIDE Center',
        'WEBSITE': 'https://www.csus.edu/pride-center',
        'PHONE': '916-278-1234',
        'EMAIL': 'pride-center@csus.edu',
      });

      expect(data.cardTitle, 'PRIDE Center');
      expect(data.website, 'https://www.csus.edu/pride-center');
      expect(data.phone, '916-278-1234');
      expect(data.email, 'pride-center@csus.edu');
    });

    test('falls back to URL when WEBSITE is unavailable', () {
      final data = LocationInfoData.fromAttributes({
        'Name': 'Food Pantry',
        'WEBSITE': 'n/a',
        'URL': 'https://www.csus.edu/food-pantry',
      });

      expect(data.cardTitle, 'Food Pantry');
      expect(data.website, 'https://www.csus.edu/food-pantry');
    });

    test('uses FACILITY_NAME for campus map details', () {
      final data = LocationInfoData.fromAttributes({
        'FACILITY_NAME': 'Coloma Community Center',
        'ADDRESS': '4623 T Street',
      });
      expect(data.cardTitle, 'Coloma Community Center');
      expect(data.address, '4623 T Street');
    });

    test('maps the bundled photo asset of an art location', () {
      final data = LocationInfoData.fromAttributes({
        'Name': 'UFW Fountain',
        'IMAGE_ASSET': 'assets/somos_campus_map_art/UFW_Fountain.jpg',
      });

      expect(data.imageAsset, 'assets/somos_campus_map_art/UFW_Fountain.jpg');
      expect(data.hasImage, isTrue);

      final withoutPhoto = LocationInfoData.fromAttributes({
        'Name': 'Serna Plaza',
      });
      expect(withoutPhoto.imageAsset, isNull);
      expect(withoutPhoto.hasImage, isFalse);
    });
  });

  group('LocationInfoCard', () {
    testWidgets('uses the active accessibility palette', (tester) async {
      final colors = AccessibilityColors.forSettings(
        colorSafePalette: true,
        highContrast: false,
      );
      final data = _artLocationData();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(colorSafePalette: true, highContrast: false),
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: true,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );

      expect(tester.widget<Card>(find.byType(Card)).color, colors.primary);
      expect(
        tester.widget<Text>(find.text(data.cardTitle).first).style!.color,
        colors.onPrimary,
      );
      final favoriteIcon = tester.widget<Icon>(find.byIcon(Icons.star_border));
      expect(favoriteIcon.color, colors.onPrimary);
      expect(favoriteIcon.size, 28);
    });

    testWidgets('long campus name leaves more information reachable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = false;
      final data = LocationInfoData.fromAttributes({
        'FACILITY_NAME': 'Coloma Community Center',
      }, fallbackCategory: 'Campus locations');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              onClose: () {},
              onShowMore: () => opened = true,
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(locationInfoImageKey), findsNothing);
      await tester.tap(find.text('More information'));
      expect(opened, isTrue);
    });

    testWidgets(
      'shows location name, website, and contact info in expanded popup',
      (tester) async {
        final data = LocationInfoData(
          cardTitle: 'PRIDE Center',
          address: '6000 J Street, Sacramento, CA',
          category: 'Community Resource',
          type: 'Support',
          website: 'https://www.csus.edu/pride-center',
          phone: '916-278-1234',
          email: 'pride-center@csus.edu',
          description: 'A welcoming space for students.',
          imageUrl: null,
          socialLinks: const {},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationInfoCard(
                data: data,
                showFullInfo: true,
                onClose: () {},
                onShowMore: () {},
                onShowLess: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('PRIDE Center'), findsOneWidget);
        expect(find.text('Open website'), findsOneWidget);
        expect(find.text('Call 916-278-1234'), findsOneWidget);
        expect(find.text('Email pride-center@csus.edu'), findsOneWidget);
      },
    );

    testWidgets('embeds the bundled photo in the compact title card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final data = _artLocationData(
        imageAsset: 'assets/somos_campus_map_art/ChicanoPark.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('More information'), findsOneWidget);

      final image = tester.widget<Image>(find.byKey(locationInfoImageKey));
      expect(
        image.image,
        isA<ResizeImage>().having(
          (provider) => provider.imageProvider,
          'imageProvider',
          const AssetImage('assets/somos_campus_map_art/ChicanoPark.png'),
        ),
      );
    });

    testWidgets('shows the bundled photo in the expanded card', (tester) async {
      final data = _artLocationData(
        imageAsset: 'assets/somos_campus_map_art/UFW_Fountain.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: true,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(locationInfoImageKey), findsOneWidget);
    });

    testWidgets('network photos stay in the expanded card', (tester) async {
      final data = LocationInfoData(
        cardTitle: 'PRIDE Center',
        address: '6000 J Street, Sacramento, CA',
        category: 'Community Resource',
        type: 'Support',
        website: '',
        phone: '',
        email: '',
        description: 'A welcoming space for students.',
        imageUrl: 'https://example.com/pride-center.jpg',
        socialLinks: const {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(locationInfoImageKey), findsNothing);
    });

    testWidgets('the photo fits on a small screen with a long title', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final data = LocationInfoData(
        cardTitle: 'Chicano Oral History Project and Community Mural Archive',
        address: '6000 J Street, Sacramento, CA',
        category: 'Public Art and Artists',
        type: 'Gallery',
        website: '',
        phone: '',
        email: '',
        description: 'No description available.',
        imageUrl: null,
        imageAsset: 'assets/somos_campus_map_art/ChicanoOralHistoryProject.PNG',
        socialLinks: const {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(locationInfoImageKey), findsOneWidget);
    });

    testWidgets(
      'the summary card shows only the title, type, address, and photo',
      (tester) async {
        final data = LocationInfoData(
          cardTitle: 'Chicano Park-RCAF',
          address: '6000 Jed Smith Dr, Sacramento, CA 95819',
          category: 'Public Art and Artists',
          type: 'Sculpture',
          website: 'https://www.csus.edu',
          phone: '916-278-1234',
          email: 'art@csus.edu',
          description: 'A mural celebrating Chicano Park.',
          imageUrl: null,
          imageAsset: 'assets/somos_campus_map_art/ChicanoPark.png',
          socialLinks: const {'Instagram': 'https://instagram.com/csus'},
          locationLat: 38.56091,
          locationLng: -121.42405,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationInfoCard(
                data: data,
                showFullInfo: false,
                summaryOnly: true,
                onClose: () {},
                onShowMore: () {},
                onShowLess: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Chicano Park-RCAF'), findsOneWidget);
        expect(find.text('Sculpture'), findsOneWidget);
        expect(
          find.text('6000 Jed Smith Dr, Sacramento, CA 95819'),
          findsOneWidget,
        );

        final typeStyle = tester.widget<Text>(find.text('Sculpture')).style!;
        final addressStyle = tester
            .widget<Text>(find.text('6000 Jed Smith Dr, Sacramento, CA 95819'))
            .style!;
        expect(typeStyle.color, mapInfoPrimaryTextColor);
        expect(typeStyle.color, addressStyle.color);

        expect(
          tester.widget<Image>(find.byKey(locationInfoImageKey)).fit,
          BoxFit.contain,
        );

        expect(find.text('Public Art and Artists'), findsNothing);
        expect(find.text('A mural celebrating Chicano Park.'), findsNothing);
        expect(find.text('Open website'), findsNothing);
        expect(find.text('Call 916-278-1234'), findsNothing);
        expect(find.text('Email art@csus.edu'), findsNothing);
        expect(find.text('More information'), findsNothing);
        expect(find.text('Show less'), findsNothing);
        expect(find.text('Open in Maps'), findsNothing);
      },
    );

    testWidgets('the summary card never expands', (tester) async {
      final data = LocationInfoData(
        cardTitle: 'UFW Fountain',
        address: '6000 Jed Smith Dr, Sacramento, CA 95819',
        category: 'Public Art and Artists',
        type: 'Fountain',
        website: '',
        phone: '',
        email: '',
        description: 'RCAF',
        imageUrl: null,
        imageAsset: 'assets/somos_campus_map_art/UFW_Fountain.jpg',
        socialLinks: const {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: true,
              summaryOnly: true,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Fountain'), findsOneWidget);
      expect(find.text('RCAF'), findsNothing);
      expect(find.text('Show less'), findsNothing);
      expect(find.byKey(locationInfoImageKey), findsOneWidget);
    });

    testWidgets(
      'the summary card stays usable with large text on a small screen',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final data = LocationInfoData(
          cardTitle: 'Dolores Huerta Tree and Community Gathering Space',
          address:
              'Serna Center, Riverfront Center, Sacramento, CA 95628 95819',
          category: 'Public Art and Artists',
          type: 'Meeting Space',
          website: '',
          phone: '',
          email: '',
          description: '',
          imageUrl: null,
          imageAsset: 'assets/somos_campus_map_art/DoloresHuertaTree.jpg',
          socialLinks: const {},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: LocationInfoCard(
                  data: data,
                  showFullInfo: false,
                  summaryOnly: true,
                  onClose: () {},
                  onShowMore: () {},
                  onShowLess: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(locationInfoImageKey), findsOneWidget);
      },
    );

    testWidgets('tapping the art photo opens it full screen', (tester) async {
      final data = _artLocationData(
        imageAsset: 'assets/somos_campus_map_art/ChicanoPark.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              summaryOnly: true,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(locationInfoImageKey));
      await tester.pumpAndSettle();

      expect(find.byKey(fullScreenImageViewerKey), findsOneWidget);

      await tester.tap(find.byKey(fullScreenImageCloseKey));
      await tester.pumpAndSettle();

      expect(find.byKey(fullScreenImageViewerKey), findsNothing);
      expect(find.text('Chicano Park-RCAF'), findsOneWidget);
    });

    testWidgets('other card photos stay inert', (tester) async {
      final data = _artLocationData(
        imageAsset: 'assets/somos_campus_map_art/ChicanoPark.png',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(locationInfoImageKey));
      await tester.pumpAndSettle();

      expect(find.byKey(fullScreenImageViewerKey), findsNothing);
    });

    testWidgets('a wide organization logo is fitted inside the card', (
      tester,
    ) async {
      final data = _centerLocationData(orgLogoFit: BoxFit.contain);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Southwest Asian and North African Center'),
        findsOneWidget,
      );
      // Wide wordmarks are scaled down inside a white box, not cropped to fill
      // a circular avatar, so the whole logo stays readable.
      const logoAsset =
          'assets/ummah_campus_map_assets/'
          'southwest_asian_and_north_african_center.png';
      final logo = tester.widget<Image>(find.byType(Image));
      expect(logo.fit, BoxFit.contain);
      expect(
        logo.image,
        isA<AssetImage>().having(
          (provider) => provider.assetName,
          'assetName',
          logoAsset,
        ),
      );
      final avatars = tester.widgetList<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(
        avatars.where(
          (avatar) =>
              avatar.backgroundImage is AssetImage &&
              (avatar.backgroundImage! as AssetImage).assetName == logoAsset,
        ),
        isEmpty,
      );

      // Without a configured background the logo box stays white.
      final box = tester.widget<Container>(find.byKey(locationInfoLogoBoxKey));
      expect((box.decoration! as BoxDecoration).color, Colors.white);
    });

    testWidgets('a center logo uses its configured background', (tester) async {
      final data = _centerLocationData(
        orgLogoFit: BoxFit.contain,
        orgLogoBackgroundColor: mapInfoCardColor,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.widget<Container>(find.byKey(locationInfoLogoBoxKey));
      expect((box.decoration! as BoxDecoration).color, mapInfoCardColor);
    });

    testWidgets('the expanded card keeps the configured logo background', (
      tester,
    ) async {
      final data = _centerLocationData(
        orgLogoFit: BoxFit.contain,
        orgLogoBackgroundColor: mapInfoCardColor,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: true,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.widget<Container>(find.byKey(locationInfoLogoBoxKey));
      expect((box.decoration! as BoxDecoration).color, mapInfoCardColor);
    });

    test('saved cards keep the configured logo background', () {
      final data = _centerLocationData(
        orgLogoFit: BoxFit.contain,
        orgLogoBackgroundColor: mapInfoCardColor,
      );

      final restored = LocationInfoData.fromFavoriteJson(data.toFavoriteJson());

      expect(restored.orgLogoFit, BoxFit.contain);
      expect(restored.orgLogoBackgroundColor, mapInfoCardColor);
    });

    testWidgets('a numbered resource shows its marker number', (tester) async {
      final data = _numberedLocationData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      final box = tester.widget<Container>(find.byKey(locationInfoLogoBoxKey));
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, mapInfoCardColor);
      expect(decoration.border, isNotNull);
    });

    testWidgets('the expanded card keeps the numbered icon', (tester) async {
      final data = _numberedLocationData(number: '12');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: true,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      final box = tester.widget<Container>(find.byKey(locationInfoLogoBoxKey));
      expect(
        (box.decoration! as BoxDecoration).color,
        mapInfoCardColor,
      );
    });

    test('saved numbered locations keep their marker number', () {
      final data = _numberedLocationData(number: '12');

      final restored = LocationInfoData.fromFavoriteJson(data.toFavoriteJson());

      expect(restored.orgLogoLabel, '12');
      expect(restored.orgLogoBackgroundColor, mapInfoCardColor);
    });

    testWidgets('a location icon asset uses the circular avatar', (
      tester,
    ) async {
      final data = _iconLocationData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(
        avatar.backgroundImage,
        isA<AssetImage>().having(
          (provider) => provider.assetName,
          'assetName',
          _foodIconAsset,
        ),
      );
    });

    testWidgets('a square organization logo keeps the circular avatar', (
      tester,
    ) async {
      final data = _centerLocationData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: false,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The community, SOMOS, and Ubuntu maps pass no fit, so their logos keep
      // the original circular avatar.
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('unified location card information', () {
    test('reads the mixed-case attributes community layers publish', () {
      final data = LocationInfoData.fromAttributes({
        'Name': 'Sharif & Co. Jewelers',
        'Category': 'Businesses & Services',
        'Type': 'Clothing',
        'Owned': 'Muslim Owned',
        'Address': '1251 Roseville Pkwy',
        'City': 'Roseville',
        'State': 'CA',
        'ZIP_Code': 95678,
        'Phone_Number': '(916) 232-7477',
        'Email': 'hello@sharif.co',
        'Website': 'https://www.sharif.co/',
        'Instagram': 'https://www.instagram.com/sharifandco/',
      }, fallbackCategory: 'Businesses');

      expect(data.cardTitle, 'Sharif & Co. Jewelers');
      expect(data.address, '1251 Roseville Pkwy, Roseville, CA 95678');
      expect(data.category, 'Businesses & Services');
      expect(data.type, 'Clothing');
      expect(data.owned, 'Muslim Owned');
      expect(data.phone, '(916) 232-7477');
      expect(data.email, 'hello@sharif.co');
      expect(data.website, 'https://www.sharif.co/');
      expect(
        data.socialLinks['Instagram'],
        'https://www.instagram.com/sharifandco/',
      );
    });

    test('reads support services and amenities from campus attributes', () {
      final data = LocationInfoData.fromAttributes({
        'NAME': 'PRIDE Center',
        'SUPPORT_SERVICES': 'Pride Center library\nRainbow ally training',
        'AMENITIES': ['Prayer space', 'Wudu stations'],
      });

      expect(data.supportServices, [
        'Pride Center library',
        'Rainbow ally training',
      ]);
      expect(data.amenities, ['Prayer space', 'Wudu stations']);
    });

    test('drops an inline support services list from the description', () {
      final data = LocationInfoData.fromAttributes({
        'NAME': 'El Centro Serna',
        'DESCRIPTION':
            'A welcoming center.\n\nSupport Services:\n'
            '\u2022 Advising Guidance\n\u2022 Scholarships',
        'SUPPORT_SERVICES': 'Advising Guidance\nScholarships',
      });

      expect(data.description, 'A welcoming center.');
      expect(data.supportServices, ['Advising Guidance', 'Scholarships']);
    });

    test('saved cards keep the new information', () {
      final data = LocationInfoData.fromAttributes({
        'Name': 'Zest Folsom',
        'Owned': 'Muslim Owned',
        'SUPPORT_SERVICES': 'Catering',
        'AMENITIES': 'Outdoor seating',
      });

      final restored = LocationInfoData.fromFavoriteJson(data.toFavoriteJson());

      expect(restored.owned, 'Muslim Owned');
      expect(restored.supportServices, ['Catering']);
      expect(restored.amenities, ['Outdoor seating']);
    });

    testWidgets('orders the expanded information consistently', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final data = LocationInfoData.fromAttributes({
        'NAME': 'PRIDE Center',
        'ADDRESS': 'University Union, Room 2230',
        'CATEGORY': 'Campus Centers',
        'TYPE': 'Center',
        'OWNED': 'Student Run',
        'DESCRIPTION': 'A welcoming space for students.',
        'SUPPORT_SERVICES': 'Advising',
        'AMENITIES': 'Study lounge',
        'WEBSITE': 'https://www.csus.edu/pride-center/',
        'PHONE': '(916) 278-1234',
        'EMAIL': 'pride-center@csus.edu',
        'Instagram': 'https://www.instagram.com/csus/',
        'LATITUDE': 38.56091,
        'LONGITUDE': -121.42405,
        'IMAGE_ASSET': 'assets/somos_campus_map_art/ChicanoPark.png',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: true,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ordered = <String>[
        'University Union, Room 2230',
        'Open in Maps',
        'Category: Campus Centers',
        'Type: Center',
        'Ownership: Student Run',
        'Description: A welcoming space for students.',
        'Support Services',
        '\u2022 Advising',
        'Amenities',
        '\u2022 Study lounge',
        'Open website',
        'Call (916) 278-1234',
        'Email pride-center@csus.edu',
        'Follow Us',
      ];

      final offsets = ordered
          .map((label) => tester.getTopLeft(find.text(label).first).dy)
          .toList();
      for (var i = 1; i < offsets.length; i++) {
        expect(
          offsets[i],
          greaterThan(offsets[i - 1]),
          reason: '${ordered[i]} should follow ${ordered[i - 1]}',
        );
      }

      expect(find.byKey(locationInfoImageKey), findsOneWidget);
    });

    testWidgets('field labels are bold and their values are not', (
      tester,
    ) async {
      final data = LocationInfoData.fromAttributes({
        'NAME': 'PRIDE Center',
        'CATEGORY': 'Campus Centers',
        'DESCRIPTION': 'A welcoming space for students.',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: data,
              showFullInfo: true,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final line in <String>[
        'Category: Campus Centers',
        'Description: A welcoming space for students.',
      ]) {
        final text = tester.widget<Text>(find.text(line));
        final span = text.textSpan! as TextSpan;
        final label = span.children!.first as TextSpan;
        final value = span.children!.last as TextSpan;

        expect(label.style?.fontWeight, FontWeight.w700, reason: line);
        expect(value.style?.fontWeight, FontWeight.w400, reason: line);
      }
    });
  });

  group('location contact links', () {
    test('builds dialable phone and email URIs', () {
      expect(phoneLaunchUri('(916) 278-2655').toString(), 'tel:9162782655');
      expect(
        phoneLaunchUri(' +1 (916) 278-2655 ').toString(),
        'tel:+19162782655',
      );
      expect(
        emailLaunchUri(' pride-center@csus.edu ').toString(),
        'mailto:pride-center@csus.edu',
      );
    });

    Future<void> pumpExpandedCard(WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              data: _contactLocationData(),
              showFullInfo: true,
              onClose: () {},
              onShowMore: () {},
              onShowLess: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tapping call opens the dialer with a clean number', (
      tester,
    ) async {
      await pumpExpandedCard(tester);

      final callButton = find.text('Call (916) 278-1234');
      await tester.ensureVisible(callButton);
      await tester.tap(callButton);
      await tester.pumpAndSettle();

      expect(launcher.launchCount, 1);
      expect(launcher.launchedUrl, 'tel:9162781234');
      expect(launcher.launchedMode, PreferredLaunchMode.externalApplication);
      expect(find.text('Could not open the phone app.'), findsNothing);
    });

    testWidgets('tapping email opens the mail app', (tester) async {
      await pumpExpandedCard(tester);

      final emailButton = find.text('Email pride-center@csus.edu');
      await tester.ensureVisible(emailButton);
      await tester.tap(emailButton);
      await tester.pumpAndSettle();

      expect(launcher.launchCount, 1);
      expect(launcher.launchedUrl, 'mailto:pride-center@csus.edu');
      expect(find.text('Could not open the email app.'), findsNothing);
    });

    testWidgets('tapping the website still opens it', (tester) async {
      await pumpExpandedCard(tester);

      final websiteButton = find.text('Open website');
      await tester.ensureVisible(websiteButton);
      await tester.tap(websiteButton);
      await tester.pumpAndSettle();

      expect(launcher.launchedUrl, 'https://www.csus.edu/pride-center/');
    });

    testWidgets('does not gate launching on canLaunchUrl', (tester) async {
      // The fake reports that no app can handle any URL, which is what
      // Android 11+ and iOS do for undeclared tel:/mailto: schemes. The card
      // must still hand the URI to the platform.
      await pumpExpandedCard(tester);

      final callButton = find.text('Call (916) 278-1234');
      await tester.ensureVisible(callButton);
      await tester.tap(callButton);
      await tester.pumpAndSettle();

      expect(launcher.launchCount, 1);
      expect(launcher.launchedUrl, 'tel:9162781234');
    });

    testWidgets('tells the user when no phone app is available', (
      tester,
    ) async {
      launcher.result = false;
      await pumpExpandedCard(tester);

      final callButton = find.text('Call (916) 278-1234');
      await tester.ensureVisible(callButton);
      await tester.tap(callButton);
      await tester.pump();
      await tester.pump();

      expect(find.text('Could not open the phone app.'), findsOneWidget);
    });

    testWidgets('reports a thrown platform error instead of crashing', (
      tester,
    ) async {
      launcher.error = PlatformException(code: 'ACTIVITY_NOT_FOUND');
      await pumpExpandedCard(tester);

      final emailButton = find.text('Email pride-center@csus.edu');
      await tester.ensureVisible(emailButton);
      await tester.tap(emailButton);
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Could not open the email app.'), findsOneWidget);
    });
  });
}

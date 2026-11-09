import 'package:belonging_maps_app/widgets/full_screen_image_viewer.dart';
import 'package:belonging_maps_app/widgets/location_info_card.dart';
import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
LocationInfoData _centerLocationData({BoxFit? orgLogoFit}) {
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
  );
}

void main() {
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
}

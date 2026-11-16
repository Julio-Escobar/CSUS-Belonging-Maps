import 'package:belonging_maps_app/models/somos_campus_center.dart';
import 'package:belonging_maps_app/models/ummah_campus_center.dart';
import 'package:belonging_maps_app/services/campus_map_card_logo.dart';
import 'package:belonging_maps_app/services/somos_campus_centers.dart';
import 'package:belonging_maps_app/services/ubuntu_campus_centers.dart';
import 'package:belonging_maps_app/services/ummah_campus_centers.dart';
import 'package:belonging_maps_app/widgets/location_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _somosMapLogo = 'assets/somos_logo_temp.png';
const String _ubuntuMapLogo = 'assets/ubuntu_logo_temp.png';
const String _ummahMapLogo = 'assets/ummah_logo_temp.png';
const String _foodIcon = 'assets/map_icons/food/HF11px.png';
const String _publicArtIcon =
    'assets/map_icons/public-art/PublicArtAndArtists.png';

/// Mirrors the token-to-color mapping used by the campus map markers.
Color? _backgroundFor(String token) {
  switch (token.trim()) {
    case 'darkGreen':
      return mapInfoCardColor;
    case 'white':
      return Colors.white;
    default:
      return null;
  }
}

/// Resolves the card logo for a bundled center the same way the campus maps do.
CampusMapCardLogo _centerCardLogo({
  required String centerIconAsset,
  required String background,
  required String mapLogoAsset,
}) {
  return campusMapCardLogo(
    centerIconAsset: centerIconAsset,
    mapLogoAsset: mapLogoAsset,
    centerBackgroundColor: _backgroundFor(background),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('campusMapCardLogo', () {
    test('a center with its own icon uses it in a fitted box', () {
      final logo = campusMapCardLogo(
        centerIconAsset: '${somosCampusCenterIconDirectory}HSI.png',
        mapLogoAsset: _somosMapLogo,
        centerBackgroundColor: mapInfoCardColor,
      );

      expect(logo.asset, '${somosCampusCenterIconDirectory}HSI.png');
      expect(logo.fit, BoxFit.contain);
      expect(logo.backgroundColor, mapInfoCardColor);
    });

    test('a center logo without a configured background stays white', () {
      final logo = campusMapCardLogo(
        centerIconAsset: '${somosCampusCenterIconDirectory}HSI.png',
        mapLogoAsset: _somosMapLogo,
      );

      expect(logo.backgroundColor, isNull);
    });

    test('a center without its own logo uses the shared location icon', () {
      final logo = campusMapCardLogo(
        centerIconAsset: SomosCampusCenter.placeholderIconAsset,
        mapLogoAsset: _somosMapLogo,
        centerBackgroundColor: mapInfoCardColor,
      );

      expect(logo.asset, SomosCampusCenter.placeholderIconAsset);
      expect(logo.fit, BoxFit.contain);
      expect(logo.backgroundColor, mapInfoCardColor);
    });

    test('a non-center location keeps the map logo', () {
      final logo = campusMapCardLogo(
        centerIconAsset: null,
        mapLogoAsset: _ubuntuMapLogo,
        centerBackgroundColor: mapInfoCardColor,
      );

      expect(logo.asset, _ubuntuMapLogo);
      expect(logo.fit, isNull);
      expect(logo.backgroundColor, isNull);
    });

    test('blank icon values keep the map logo', () {
      final logo = campusMapCardLogo(
        centerIconAsset: '   ',
        mapLogoAsset: _ubuntuMapLogo,
        centerBackgroundColor: Colors.white,
      );

      expect(logo.asset, _ubuntuMapLogo);
      expect(logo.fit, isNull);
      expect(logo.backgroundColor, isNull);
    });

    test('a center logo wins over an override asset', () {
      final logo = campusMapCardLogo(
        centerIconAsset: '${somosCampusCenterIconDirectory}HSI.png',
        mapLogoAsset: _somosMapLogo,
        overrideAsset: _publicArtIcon,
        iconAsset: _foodIcon,
        resourceNumber: '7',
      );

      expect(logo.asset, '${somosCampusCenterIconDirectory}HSI.png');
      expect(logo.label, isNull);
      expect(logo.fit, BoxFit.contain);
    });

    test('an explicit override uses the override icon', () {
      final logo = campusMapCardLogo(
        centerIconAsset: null,
        mapLogoAsset: _somosMapLogo,
        overrideAsset: _publicArtIcon,
        iconAsset: _foodIcon,
        resourceNumber: '7',
      );

      expect(logo.asset, _publicArtIcon);
      expect(logo.label, isNull);
      expect(logo.fit, isNull);
      expect(logo.backgroundColor, isNull);
    });

    test('a location icon asset uses the circular avatar', () {
      final logo = campusMapCardLogo(
        centerIconAsset: null,
        mapLogoAsset: _somosMapLogo,
        iconAsset: _foodIcon,
        resourceNumber: '7',
      );

      expect(logo.asset, _foodIcon);
      expect(logo.label, isNull);
      expect(logo.fit, isNull);
      expect(logo.backgroundColor, isNull);
    });

    test('a numbered marker uses its number and marker color', () {
      final logo = campusMapCardLogo(
        centerIconAsset: null,
        mapLogoAsset: _somosMapLogo,
        resourceNumber: '7',
        markerColor: mapInfoCardColor,
      );

      expect(logo.asset, isNull);
      expect(logo.label, '7');
      expect(logo.fit, isNull);
      expect(logo.backgroundColor, mapInfoCardColor);
    });
  });

  group('bundled campus centers', () {
    test('SOMOS centers use their map marker icon and background', () async {
      final source = await rootBundle.loadString(somosCampusCentersAsset);
      final centers = parseSomosCampusCenters(source);

      for (final center in centers) {
        final logo = _centerCardLogo(
          centerIconAsset: center.iconAsset,
          background: center.background,
          mapLogoAsset: _somosMapLogo,
        );

        expect(logo.asset, center.iconAsset, reason: center.name);
        expect(logo.fit, BoxFit.contain, reason: center.name);
        expect(
          logo.backgroundColor,
          _backgroundFor(center.background),
          reason: center.name,
        );
      }
    });

    test('the Career Center card uses the shared location icon', () async {
      final source = await rootBundle.loadString(somosCampusCentersAsset);
      final centers = parseSomosCampusCenters(source);
      final careerCenter = centers.firstWhere(
        (center) => center.id == 'career-center',
      );

      final logo = _centerCardLogo(
        centerIconAsset: careerCenter.iconAsset,
        background: careerCenter.background,
        mapLogoAsset: _somosMapLogo,
      );

      expect(logo.asset, SomosCampusCenter.placeholderIconAsset);
      expect(logo.asset, isNot(_somosMapLogo));
      expect(logo.fit, BoxFit.contain);
    });

    test('Ubuntu centers use their own logo and background', () async {
      final source = await rootBundle.loadString(ubuntuCampusCentersAsset);
      final centers = parseUbuntuCampusCenters(source);

      for (final center in centers) {
        final logo = _centerCardLogo(
          centerIconAsset: center.iconAsset,
          background: center.background,
          mapLogoAsset: _ubuntuMapLogo,
        );

        expect(logo.asset, center.iconAsset, reason: center.name);
        expect(logo.fit, BoxFit.contain, reason: center.name);
        expect(
          logo.backgroundColor,
          _backgroundFor(center.background),
          reason: center.name,
        );
      }
    });

    test('Ummah centers without a logo use the shared location icon', () async {
      final source = await rootBundle.loadString(ummahCampusCentersAsset);
      final centers = parseUmmahCampusCenters(source);
      final centersWithoutLogo = centers.where(
        (center) => center.icon.trim().isEmpty,
      );

      expect(centersWithoutLogo, isNotEmpty);
      for (final center in centersWithoutLogo) {
        final logo = _centerCardLogo(
          centerIconAsset: center.iconAsset,
          background: center.background,
          mapLogoAsset: _ummahMapLogo,
        );

        expect(
          logo.asset,
          UmmahCampusCenter.placeholderIconAsset,
          reason: center.name,
        );
        expect(logo.asset, isNot(_ummahMapLogo), reason: center.name);
        expect(logo.fit, BoxFit.contain, reason: center.name);
      }
    });
  });
}

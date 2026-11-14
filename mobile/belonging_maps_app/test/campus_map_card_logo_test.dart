import 'package:belonging_maps_app/models/somos_campus_center.dart';
import 'package:belonging_maps_app/services/campus_map_card_logo.dart';
import 'package:belonging_maps_app/services/somos_campus_centers.dart';
import 'package:belonging_maps_app/services/ubuntu_campus_centers.dart';
import 'package:belonging_maps_app/widgets/location_info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _somosMapLogo = 'assets/somos_logo_temp.png';
const String _ubuntuMapLogo = 'assets/ubuntu_logo_temp.png';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('campusMapCardLogo', () {
    test('a center with its own icon uses it in a fitted box', () {
      final logo = campusMapCardLogo(
        centerIcon: 'HSI.png',
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
        centerIcon: 'HSI.png',
        centerIconAsset: '${somosCampusCenterIconDirectory}HSI.png',
        mapLogoAsset: _somosMapLogo,
      );

      expect(logo.backgroundColor, isNull);
    });

    test('a center without its own icon keeps the map logo', () {
      final logo = campusMapCardLogo(
        centerIcon: '',
        centerIconAsset: SomosCampusCenter.placeholderIconAsset,
        mapLogoAsset: _somosMapLogo,
        centerBackgroundColor: mapInfoCardColor,
      );

      expect(logo.asset, _somosMapLogo);
      expect(logo.fit, isNull);
      expect(logo.backgroundColor, isNull);
    });

    test('a non-center location keeps the map logo', () {
      final logo = campusMapCardLogo(
        centerIcon: null,
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
        centerIcon: '   ',
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
        centerIcon: 'HSI.png',
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
        centerIcon: null,
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
        centerIcon: null,
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
        centerIcon: null,
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
    test('SOMOS centers use their own logo and background', () async {
      final source = await rootBundle.loadString(somosCampusCentersAsset);
      final centers = parseSomosCampusCenters(source);

      for (final center in centers) {
        final expectedBackground = _backgroundFor(center.background);
        final logo = campusMapCardLogo(
          centerIcon: center.icon,
          centerIconAsset: center.iconAsset,
          mapLogoAsset: _somosMapLogo,
          centerBackgroundColor: expectedBackground,
        );

        if (center.icon.trim().isEmpty) {
          expect(logo.asset, _somosMapLogo, reason: center.name);
          expect(logo.fit, isNull, reason: center.name);
          expect(logo.backgroundColor, isNull, reason: center.name);
        } else {
          expect(logo.asset, center.iconAsset, reason: center.name);
          expect(logo.fit, BoxFit.contain, reason: center.name);
          expect(logo.backgroundColor, expectedBackground, reason: center.name);
        }
      }
    });

    test('Ubuntu centers use their own logo and background', () async {
      final source = await rootBundle.loadString(ubuntuCampusCentersAsset);
      final centers = parseUbuntuCampusCenters(source);

      for (final center in centers) {
        final expectedBackground = _backgroundFor(center.background);
        final logo = campusMapCardLogo(
          centerIcon: center.icon,
          centerIconAsset: center.iconAsset,
          mapLogoAsset: _ubuntuMapLogo,
          centerBackgroundColor: expectedBackground,
        );

        expect(logo.asset, center.iconAsset, reason: center.name);
        expect(logo.fit, BoxFit.contain, reason: center.name);
        expect(logo.backgroundColor, expectedBackground, reason: center.name);
      }
    });
  });
}

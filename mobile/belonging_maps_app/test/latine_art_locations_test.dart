import 'package:belonging_maps_app/services/latine_art_locations.dart';
import 'package:belonging_maps_app/services/map_location_source.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// The published attributes of the "UFW Fountain" point, including the "N/A"
/// placeholders the story map's layer leaves in unused fields.
Map<String, dynamic> _ufwFountain() {
  return <String, dynamic>{
    'OBJECTID': 1,
    'Name': 'UFW Fountain',
    'Category': 'Public Art and Artists',
    'Type': 'Fountain',
    'Address': '6000 Jed Smith Dr, Sacramento, CA 95819',
    'PhoneNumber': 'N/A',
    'Email': 'N/A',
    'Website': 'N/A',
    'SocialMedia': 'N/A',
    'Comments': 'RCAF',
    'Image': 'N/A',
  };
}

MapLocation _location(
  String name, {
  Map<String, dynamic> attributes = const {},
}) {
  return MapLocation.fromAttributes(<String, dynamic>{
    'Name': name,
    ...attributes,
  }, category: latineArtCategory);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the layer URL points at the SacStateLatineArt feature layer', () {
    expect(sacStateLatineArtLayerUrl, startsWith('https://'));
    expect(
      sacStateLatineArtLayerUrl,
      endsWith('/SacStateLatineArt/FeatureServer/0'),
    );
  });

  test('the Latine art pin is bundled with the app', () async {
    final data = await rootBundle.load(latineArtIconAsset);

    expect(
      latineArtIconAsset,
      'assets/map_icons/public-art/PublicArtAndArtists.png',
    );
    expect(data.lengthInBytes, greaterThan(0));
  });

  test('the published art locations map to their bundled photos', () {
    expect(latineArtImageAssetDirectory, 'assets/somos_campus_map_art/');
    expect(
      latineArtImageAsset('UFW Fountain'),
      '${latineArtImageAssetDirectory}UFW_Fountain.jpg',
    );
    expect(
      latineArtImageAsset('  dolores huerta tree '),
      '${latineArtImageAssetDirectory}DoloresHuertaTree.jpg',
    );
    expect(
      latineArtImageAsset('Chicano Park-RCAF'),
      '${latineArtImageAssetDirectory}ChicanoPark.png',
    );
    expect(
      latineArtImageAsset('Chicano Oral Histories'),
      '${latineArtImageAssetDirectory}ChicanoOralHistoryProject.PNG',
    );
  });

  test('art locations without a bundled photo resolve to null', () {
    expect(latineArtImageAsset('Serna Plaza'), isNull);
    expect(latineArtImageAsset('Dolores Huerta Boardroom'), isNull);
    expect(latineArtImageAsset(''), isNull);
    expect(latineArtImageAsset(null), isNull);
  });

  test('every bundled art photo is included in the app bundle', () async {
    expect(latineArtImageAssets, hasLength(4));

    for (final asset in latineArtImageAssets.values) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });

  test('the card attributes of an art location carry its photo', () {
    final withPhoto = latineArtLocationAttributes(_ufwFountain());
    expect(
      withPhoto['IMAGE_ASSET'],
      '${latineArtImageAssetDirectory}UFW_Fountain.jpg',
    );

    final withoutPhoto = latineArtLocationAttributes(<String, dynamic>{
      'Name': 'Serna Plaza',
    });
    expect(withoutPhoto['IMAGE_ASSET'], isNull);
  });

  test('feature attributes are mapped to the keys used by the info card', () {
    final attributes = latineArtLocationAttributes(
      _ufwFountain(),
      latitude: 38.55960233774709,
      longitude: -121.4214664617989,
    );

    expect(attributes['NAME'], 'UFW Fountain');
    expect(attributes['ADDRESS'], '6000 Jed Smith Dr, Sacramento, CA 95819');
    expect(attributes['CATEGORY'], latineArtCategory);
    expect(attributes['TYPE'], 'Fountain');
    expect(attributes['DESCRIPTION'], 'RCAF');
    expect(attributes['LATITUDE'], 38.55960233774709);
    expect(attributes['LONGITUDE'], -121.4214664617989);
  });

  test('placeholder values are dropped and the category falls back', () {
    final attributes = latineArtLocationAttributes(<String, dynamic>{
      'Name': 'Dolores Huerta Boardroom',
      'Category': 'NULL',
      'Type': 'Meeting Space',
      'Address': 'N/A',
      'PhoneNumber': 'N/A',
      'Email': null,
      'Website': 'N/A',
      'Comments': '',
    });

    expect(attributes['NAME'], 'Dolores Huerta Boardroom');
    expect(attributes['CATEGORY'], latineArtCategory);
    expect(attributes['TYPE'], 'Meeting Space');
    expect(attributes['ADDRESS'], '');
    expect(attributes['PHONE'], '');
    expect(attributes['EMAIL'], '');
    expect(attributes['WEBSITE'], '');
    expect(attributes['DESCRIPTION'], '');
    expect(attributes['LATITUDE'], isNull);
    expect(attributes['LONGITUDE'], isNull);
  });

  test('only point geometry can be projected for the map', () {
    expect(latineArtWgs84Point(null), isNull);
  });

  test('filtering matches names and attributes case-insensitively', () {
    final locations = [
      _location('Dolores Huerta Tree'),
      _location('Serna Plaza', attributes: {'Type': 'Public Square'}),
    ];

    expect(
      filterLatineArtLocations(locations, query: 'huerta').map((l) => l.name),
      ['Dolores Huerta Tree'],
    );
    expect(
      filterLatineArtLocations(
        locations,
        query: 'public square',
      ).map((l) => l.name),
      ['Serna Plaza'],
    );
    expect(filterLatineArtLocations(locations), hasLength(2));
  });

  test('the category filter hides every art location when it is excluded', () {
    final locations = [
      _location('Dolores Huerta Tree'),
      _location('Chicano Park-RCAF'),
    ];

    expect(
      filterLatineArtLocations(locations, categories: {'Basic Needs'}),
      isEmpty,
    );
    expect(
      filterLatineArtLocations(
        locations,
        categories: {latineArtCategory},
      ).map((l) => l.name),
      ['Dolores Huerta Tree', 'Chicano Park-RCAF'],
    );
  });
}

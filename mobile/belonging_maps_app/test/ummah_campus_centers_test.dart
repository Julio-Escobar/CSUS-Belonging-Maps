import 'dart:math' as math;

import 'package:belonging_maps_app/models/ummah_campus_center.dart';
import 'package:belonging_maps_app/services/ummah_campus_centers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Straight-line distance in metres between two nearby coordinates.
double _distanceInMeters(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const double metresPerDegreeLatitude = 111320;
  final double metresPerDegreeLongitude =
      metresPerDegreeLatitude * math.cos(lat1 * math.pi / 180);
  final double dLat = (lat2 - lat1) * metresPerDegreeLatitude;
  final double dLon = (lon2 - lon1) * metresPerDegreeLongitude;
  return math.sqrt(dLat * dLat + dLon * dLon);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled campus center dataset', () {
    test('lists the seven story map centers', () async {
      final centers = await loadUmmahCampusCenters();

      expect(centers, hasLength(7));
      expect(centers.map((center) => center.id).toSet(), hasLength(7));
      expect(
        centers.map((center) => center.category).toSet(),
        {'Campus Centers'},
      );

      final names = centers.map((center) => center.name).toList();
      expect(names, contains('Southwest Asian and North African Center'));
      expect(names, contains('Iranian and Middle Eastern Studies Center'));
      expect(
        names,
        contains('Asian Pacific Islander Desi American Student Center'),
      );
      expect(names, contains('Martin Luther King Jr. Center'));
      expect(
        names,
        contains('Crisis Assistance & Resource Education Support (CARES)'),
      );
      expect(
        names,
        contains('Student Health, Counseling, & Wellness Services'),
      );
      expect(names, contains('Multi-Cultural Center'));
    });

    test('every center has a usable marker and location', () async {
      final centers = await loadUmmahCampusCenters();

      for (final center in centers) {
        expect(center.name.trim(), isNotEmpty);
        expect(center.building.trim(), isNotEmpty);
        expect(center.description.trim(), isNotEmpty);
        expect(center.website, startsWith('https://'));
        expect(center.latitude, inInclusiveRange(38.54, 38.58));
        expect(center.longitude, inInclusiveRange(-121.44, -121.40));
        // Every marker resolves either to its own bundled logo or to the shared
        // placeholder drawn for centers that are still waiting for one.
        expect(
          center.iconAsset,
          center.icon.trim().isEmpty
              ? UmmahCampusCenter.placeholderIconAsset
              : '$ummahCampusCenterIconDirectory${center.icon}',
        );
      }
    });

    test('the bundled logos are wired to their centers', () async {
      final centers = await loadUmmahCampusCenters();
      final byId = {for (final center in centers) center.id: center};

      expect(
        byId['swana-center']?.icon,
        'southwest_asian_and_north_african_center.png',
      );
      expect(
        byId['imesc']?.icon,
        'iranian_and_middle_eastern_studies_center.png',
      );
      expect(
        byId['apida-center']?.icon,
        'asian_pacific_islander_desi_american_center.jpg',
      );
      expect(byId['mlk-center']?.icon, 'martin_luther_king_jr_center.jpg');

      // The two PNG logos are transparent, so they declare a white background
      // to stay visible against the basemap.
      expect(byId['swana-center']?.background, 'white');
      expect(byId['imesc']?.background, 'white');
      // Both are wide wordmarks, so they are scaled up a little to stay legible.
      expect(byId['swana-center']?.iconScale, greaterThan(1.0));
      expect(byId['imesc']?.iconScale, greaterThan(1.0));

      // The JPG logos already ship on a white background.
      expect(byId['apida-center']?.background, '');
      expect(byId['mlk-center']?.background, '');

      // The remaining centers still use the shared placeholder marker.
      expect(byId['cares']?.iconAsset, UmmahCampusCenter.placeholderIconAsset);
      expect(byId['shcws']?.iconAsset, UmmahCampusCenter.placeholderIconAsset);
      expect(
        byId['multi-cultural-center']?.iconAsset,
        UmmahCampusCenter.placeholderIconAsset,
      );
    });

    test('every bundled center logo loads from the asset bundle', () async {
      final centers = await loadUmmahCampusCenters();

      for (final center in centers) {
        if (center.icon.trim().isEmpty) continue;
        final data = await rootBundle.load(center.iconAsset);
        expect(
          data.lengthInBytes,
          greaterThan(0),
          reason: 'Missing bundled logo for ${center.name}: ${center.iconAsset}',
        );
      }
    });

    test('the background tokens are ones the map understands', () async {
      final centers = await loadUmmahCampusCenters();

      for (final center in centers) {
        expect(center.background, anyOf('', 'white', 'darkGreen'));
      }
    });

    test('the centers keep the story map locations', () async {
      final centers = await loadUmmahCampusCenters();
      final byBuilding = <String, List<String>>{};
      for (final center in centers) {
        byBuilding.putIfAbsent(center.building, () => []).add(center.room);
      }

      expect(byBuilding['AIRC'], containsAll(<String>['1012', '1012E']));
      expect(
        byBuilding['Lassen Hall'],
        containsAll(<String>['2200', '2201']),
      );
      expect(byBuilding['The WELL'], contains('1000'));
      expect(byBuilding['University Library'], contains('1000A'));
    });

    test('same-building centers stay apart and on their building', () async {
      final centers = await loadUmmahCampusCenters();
      final byId = {for (final center in centers) center.id: center};

      // The logos are drawn as wide wordmarks, so the two centers that share a
      // building are spread across it instead of stacking on one point.
      final pairs = <List<String>>[
        ['swana-center', 'imesc'],
        ['apida-center', 'mlk-center'],
      ];
      for (final pair in pairs) {
        final first = byId[pair[0]]!;
        final second = byId[pair[1]]!;
        expect(first.building, second.building);

        final distance = _distanceInMeters(
          first.latitude,
          first.longitude,
          second.latitude,
          second.longitude,
        );
        expect(
          distance,
          greaterThanOrEqualTo(25),
          reason:
              '${first.name} and ${second.name} are only '
              '${distance.toStringAsFixed(1)} m apart',
        );
      }
    });

    test('the nudged markers stay inside their building footprint', () async {
      final centers = await loadUmmahCampusCenters();
      final byId = {for (final center in centers) center.id: center};

      // Footprints from the BuildingsV2 layer (WGS84), used to confirm the
      // spread markers still sit on the building they belong to.
      final footprints = <String, List<double>>{
        'swana-center': [38.558615, 38.559218, -121.423351, -121.422774],
        'imesc': [38.558615, 38.559218, -121.423351, -121.422774],
        'apida-center': [38.56242, 38.563027, -121.426470, -121.425566],
        'mlk-center': [38.56242, 38.563027, -121.426470, -121.425566],
      };

      footprints.forEach((id, bounds) {
        final center = byId[id]!;
        expect(
          center.latitude,
          inInclusiveRange(bounds[0], bounds[1]),
          reason: '${center.name} is outside its building to the north/south',
        );
        expect(
          center.longitude,
          inInclusiveRange(bounds[2], bounds[3]),
          reason: '${center.name} is outside its building to the east/west',
        );
      });
    });

    test('the descriptions are not padded with story map boilerplate', () async {
      final centers = await loadUmmahCampusCenters();

      for (final center in centers) {
        expect(
          center.description,
          isNot(contains('Ummah Resource Map')),
          reason: '${center.name} still points at the story map',
        );
        expect(center.description, isNot(contains('links to the center')));
      }
    });

    test('the attributes expose the fields the info card reads', () async {
      final centers = await loadUmmahCampusCenters();
      final center = centers.firstWhere(
        (center) => center.id == 'multi-cultural-center',
      );
      final attributes = center.toAttributes();

      expect(attributes['NAME'], 'Multi-Cultural Center');
      expect(attributes['ADDRESS'], 'University Library, Room 1000A');
      expect(attributes['CATEGORY'], 'Campus Centers');
      expect(
        attributes['SUPPORT_SERVICES'],
        contains('Social justice library'),
      );
      expect(attributes['ICON_ASSET'], UmmahCampusCenter.placeholderIconAsset);
      expect(attributes['LATITUDE'], center.latitude);
    });
  });

  group('parsing', () {
    test('rejects malformed JSON, empty lists, and duplicate ids', () {
      expect(
        () => parseUmmahCampusCenters('{not json'),
        throwsFormatException,
      );
      expect(() => parseUmmahCampusCenters('[]'), throwsFormatException);
      expect(
        () => parseUmmahCampusCenters(
          '[{"id":"a","name":"A","building":"B","category":"Campus Centers",'
          '"description":"D","website":"https://www.csus.edu/",'
          '"latitude":38.56,"longitude":-121.42},'
          '{"id":"a","name":"A2","building":"B","category":"Campus Centers",'
          '"description":"D","website":"https://www.csus.edu/",'
          '"latitude":38.56,"longitude":-121.42}]',
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid scaling, coordinates, and websites', () {
      final base = <String, dynamic>{
        'id': 'swana-center',
        'name': 'SWANA Center',
        'building': 'AIRC',
        'category': 'Campus Centers',
        'description': 'A center.',
        'website': 'https://www.csus.edu/',
        'latitude': 38.558926,
        'longitude': -121.423045,
      };

      expect(
        () => UmmahCampusCenter.fromJson({...base}..remove('description')),
        throwsFormatException,
      );
      expect(
        () => UmmahCampusCenter.fromJson({...base, 'iconScale': 0}),
        throwsFormatException,
      );
      expect(
        () => UmmahCampusCenter.fromJson({...base, 'latitude': 91.0}),
        throwsFormatException,
      );
      expect(
        () => UmmahCampusCenter.fromJson({...base, 'website': 'swana'}),
        throwsFormatException,
      );
    });
  });

  group('filtering', () {
    late List<UmmahCampusCenter> centers;

    setUp(() async {
      centers = await loadUmmahCampusCenters();
    });

    test('matches the name, building, and support services', () {
      expect(
        filterUmmahCampusCenters(centers, query: 'swana').single.building,
        'AIRC',
      );
      expect(filterUmmahCampusCenters(centers, query: 'lassen'), hasLength(2));
      expect(
        filterUmmahCampusCenters(
          centers,
          query: 'social justice library',
        ).single.id,
        'multi-cultural-center',
      );
      expect(
        filterUmmahCampusCenters(centers, query: 'no such center'),
        isEmpty,
      );
    });

    test('honours the category filter', () {
      expect(
        filterUmmahCampusCenters(centers, categories: {'Campus Centers'}),
        hasLength(7),
      );
      expect(
        filterUmmahCampusCenters(centers, categories: {'Halal Food'}),
        isEmpty,
      );
    });
  });
}

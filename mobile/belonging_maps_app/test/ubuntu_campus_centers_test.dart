import 'dart:convert';

import 'package:belonging_maps_app/models/ubuntu_campus_center.dart';
import 'package:belonging_maps_app/services/ubuntu_campus_centers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory bundle used to exercise the asset loader without touching the
/// real application bundle.
class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) {
      throw FlutterError('Missing asset: $key');
    }

    final bytes = utf8.encode(value);
    return ByteData.view(
      bytes.buffer,
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
  }
}

Map<String, dynamic> _centerJson({
  String id = 'test-center',
  String name = 'Test Center',
  String building = 'Lassen Hall',
  String room = '2201',
  String category = 'Cultural & Identity',
  String description = 'A test center with scholarship support.',
  String website = 'https://www.csus.edu/',
  String icon = '',
  String background = '',
  double iconScale = 1.0,
  double backgroundPadding = 0.12,
  List<String> supportServices = const ['Advising', 'Scholarships'],
  double latitude = 38.56091,
  double longitude = -121.42405,
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'building': building,
    'room': room,
    'category': category,
    'description': description,
    'website': website,
    'icon': icon,
    'background': background,
    'iconScale': iconScale,
    'backgroundPadding': backgroundPadding,
    'supportServices': supportServices,
    'latitude': latitude,
    'longitude': longitude,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled dataset contains 8 valid centers', () async {
    final source = await rootBundle.loadString(ubuntuCampusCentersAsset);
    final centers = parseUbuntuCampusCenters(source);

    expect(centers, hasLength(8));
    expect(
      centers.map((center) => center.name),
      containsAll(<String>[
        'Black Honors College',
        'Black Student Union',
        'Martin Luther King Jr. Center',
        'Cooper-Woodson College Enhancement Program',
        'Center on Race, Immigration, and Social Justice',
        'UNIQUE Programs',
        'Crisis Assistance & Resource Education Support (CARES)',
        'Student Health, Counseling, & Wellness Services',
      ]),
    );
    expect(
      centers.map((center) => center.id).toSet(),
      hasLength(centers.length),
    );

    for (final center in centers) {
      expect(center.name.trim(), isNotEmpty);
      expect(center.building.trim(), isNotEmpty);
      expect(center.description.trim(), isNotEmpty);
      expect(center.category.trim(), isNotEmpty);
      expect(center.website, startsWith('https://'));
      expect(center.latitude, inInclusiveRange(38.54, 38.58));
      expect(center.longitude, inInclusiveRange(-121.44, -121.40));
    }
  });

  test(
    'loadUbuntuCampusCenters reads and parses the configured asset',
    () async {
      final bundle = _FakeAssetBundle({
        ubuntuCampusCentersAsset: jsonEncode([_centerJson()]),
      });

      final centers = await loadUbuntuCampusCenters(bundle: bundle);

      expect(centers, hasLength(1));
      expect(centers.single.name, 'Test Center');
      expect(centers.single.locationLabel, 'Lassen Hall, Room 2201');
    },
  );

  test('loadUbuntuCampusCenters throws when the asset is missing', () async {
    final bundle = _FakeAssetBundle({});

    await expectLater(
      loadUbuntuCampusCenters(bundle: bundle),
      throwsA(isA<FlutterError>()),
    );
  });

  test('malformed JSON throws a FormatException', () {
    expect(
      () => parseUbuntuCampusCenters('{not json'),
      throwsFormatException,
    );
  });

  test('an empty dataset throws a FormatException', () {
    expect(() => parseUbuntuCampusCenters('[]'), throwsFormatException);
  });

  test('duplicate center ids throw a FormatException', () {
    final source = jsonEncode([
      _centerJson(id: 'mlk-center'),
      _centerJson(id: 'mlk-center', name: 'Another Center'),
    ]);

    expect(() => parseUbuntuCampusCenters(source), throwsFormatException);
  });

  test('invalid center fields throw a FormatException', () {
    expect(
      () => UbuntuCampusCenter.fromJson(_centerJson()..remove('name')),
      throwsFormatException,
    );
    expect(
      () => UbuntuCampusCenter.fromJson(_centerJson(latitude: 200)),
      throwsFormatException,
    );
    expect(
      () => UbuntuCampusCenter.fromJson(
        _centerJson(website: 'ftp://www.csus.edu/'),
      ),
      throwsFormatException,
    );
  });

  test('filtering matches names, buildings, descriptions, and services', () {
    final centers = [
      UbuntuCampusCenter.fromJson(
        _centerJson(
          id: 'pride-center',
          name: 'The Pride Center',
          building: 'University Union',
          room: '2230',
          category: 'Cultural & Identity',
          description: 'Support for LGBTQIA students.',
          supportServices: ['Rainbow ally training'],
        ),
      ),
      UbuntuCampusCenter.fromJson(
        _centerJson(
          id: 'cares',
          name: 'CARES',
          building: 'The WELL',
          room: '1000',
          category: 'Basic Needs',
          description: 'Crisis and basic needs support.',
          supportServices: ['CalFresh Application Assistance'],
        ),
      ),
    ];

    expect(
      filterUbuntuCampusCenters(
        centers,
        query: 'union',
      ).map((center) => center.name),
      ['The Pride Center'],
    );
    expect(
      filterUbuntuCampusCenters(
        centers,
        query: 'calfresh',
      ).map((center) => center.name),
      ['CARES'],
    );
    expect(
      filterUbuntuCampusCenters(
        centers,
        categories: {'Basic Needs'},
      ).map((center) => center.name),
      ['CARES'],
    );
    expect(
      filterUbuntuCampusCenters(centers, categories: {'Campus Life'}),
      isEmpty,
    );
    expect(
      filterUbuntuCampusCenters(centers, query: 'no such center'),
      isEmpty,
    );
  });

  test('center attributes provide the fields used by the info card', () {
    final center = UbuntuCampusCenter.fromJson(_centerJson());
    final attributes = center.toAttributes();

    expect(attributes['NAME'], 'Test Center');
    expect(attributes['ADDRESS'], 'Lassen Hall, Room 2201');
    expect(attributes['CATEGORY'], 'Cultural & Identity');
    expect(attributes['DESCRIPTION'], contains('scholarship'));
    expect(attributes['WEBSITE'], 'https://www.csus.edu/');
    expect(attributes['ICON_ASSET'], UbuntuCampusCenter.placeholderIconAsset);
    expect(attributes['BACKGROUND'], '');
    expect(attributes['SUPPORT_SERVICES'], 'Advising\nScholarships');
    expect(attributes['LATITUDE'], 38.56091);
    expect(attributes['LONGITUDE'], -121.42405);
  });

  test('a center icon resolves to its bundled asset path', () {
    final center = UbuntuCampusCenter.fromJson(_centerJson(icon: 'mlk.png'));

    expect(center.iconAsset, '${ubuntuCampusCenterIconDirectory}mlk.png');
    expect(center.toAttributes()['ICON_ASSET'], center.iconAsset);

    final fallback = UbuntuCampusCenter.fromJson(_centerJson(icon: ''));
    expect(fallback.iconAsset, UbuntuCampusCenter.placeholderIconAsset);
  });

  test('every bundled center icon loads from the asset bundle', () async {
    final source = await rootBundle.loadString(ubuntuCampusCentersAsset);
    final centers = parseUbuntuCampusCenters(source);

    for (final center in centers) {
      final data = await rootBundle.load(center.iconAsset);
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: 'Missing bundled icon for ${center.name}: ${center.iconAsset}',
      );
    }
  });

  test('banner logos are scaled up and the WELL logo has a dark background',
      () async {
    final source = await rootBundle.loadString(ubuntuCampusCentersAsset);
    final centers = parseUbuntuCampusCenters(source);
    final byId = {for (final center in centers) center.id: center};

    // Wide banner logos render short at the default size, so they carry an
    // iconScale above 1.0 to match the square logos.
    for (final id in [
      'black-honors-college',
      'black-student-union',
      'mlk-center',
      'unique',
    ]) {
      expect(
        byId[id]!.iconScale,
        greaterThan(1.0),
        reason: '$id should be scaled up',
      );
    }

    // The Student Health (The WELL) logo is white on transparent, so it needs
    // the dark green background to stay visible on the light basemap.
    expect(
      byId['student-health-counseling-wellness']!.background,
      'darkGreen',
    );
  });
}

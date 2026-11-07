import 'dart:convert';

import 'package:belonging_maps_app/models/somos_campus_center.dart';
import 'package:belonging_maps_app/services/somos_campus_centers.dart';
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
  String room = '3003',
  String category = 'Campus Centers',
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

  test('the bundled dataset contains 9 valid centers', () async {
    final source = await rootBundle.loadString(somosCampusCentersAsset);
    final centers = parseSomosCampusCenters(source);

    expect(centers, hasLength(9));
    expect(centers.map((center) => center.name), contains('PRIDE Center'));
    expect(
      centers.map((center) => center.name),
      containsAll(<String>[
        'Center for Science and Math Success',
        'Career Center',
        'MESA',
        'The Well',
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
    'loadSomosCampusCenters reads and parses the configured asset',
    () async {
      final bundle = _FakeAssetBundle({
        somosCampusCentersAsset: jsonEncode([_centerJson()]),
      });

      final centers = await loadSomosCampusCenters(bundle: bundle);

      expect(centers, hasLength(1));
      expect(centers.single.name, 'Test Center');
      expect(centers.single.locationLabel, 'Lassen Hall, Room 3003');
      expect(centers.single.supportServices, ['Advising', 'Scholarships']);
    },
  );

  test('loadSomosCampusCenters throws when the asset is missing', () async {
    final bundle = _FakeAssetBundle({});

    await expectLater(
      loadSomosCampusCenters(bundle: bundle),
      throwsA(isA<FlutterError>()),
    );
  });

  test('malformed JSON throws a FormatException', () {
    expect(() => parseSomosCampusCenters('{not json'), throwsFormatException);
  });

  test('an empty dataset throws a FormatException', () {
    expect(() => parseSomosCampusCenters('[]'), throwsFormatException);
  });

  test('duplicate center ids throw a FormatException', () {
    final source = jsonEncode([
      _centerJson(id: 'same-id'),
      _centerJson(id: 'same-id', name: 'Another Center'),
    ]);

    expect(() => parseSomosCampusCenters(source), throwsFormatException);
  });

  test('invalid center fields throw a FormatException', () {
    expect(
      () => SomosCampusCenter.fromJson(_centerJson()..remove('name')),
      throwsFormatException,
    );
    expect(
      () => SomosCampusCenter.fromJson(_centerJson(latitude: 200)),
      throwsFormatException,
    );
    expect(
      () => SomosCampusCenter.fromJson(
        _centerJson(website: 'ftp://www.csus.edu/'),
      ),
      throwsFormatException,
    );
    expect(
      () => SomosCampusCenter.fromJson(
        _centerJson()..['supportServices'] = <dynamic>[1, 2],
      ),
      throwsFormatException,
    );
  });

  test('filtering matches names, buildings, services, and categories', () {
    final centers = [
      SomosCampusCenter.fromJson(
        _centerJson(
          id: 'pride',
          name: 'PRIDE Center',
          building: 'University Union',
          room: '2230',
          category: 'Campus Centers',
          description: 'A community space.',
          supportServices: ['Rainbow ally training'],
        ),
      ),
      SomosCampusCenter.fromJson(
        _centerJson(
          id: 'drc',
          name: 'Dreamer Resource Center',
          building: 'Lassen Hall',
          room: '3003',
          category: 'Campus Centers',
          description: 'Support for undocumented students.',
          supportServices: ['Free Immigration Legal Services'],
        ),
      ),
    ];

    expect(
      filterSomosCampusCenters(
        centers,
        query: 'union',
      ).map((center) => center.name),
      ['PRIDE Center'],
    );
    expect(
      filterSomosCampusCenters(
        centers,
        query: 'immigration',
      ).map((center) => center.name),
      ['Dreamer Resource Center'],
    );
    expect(
      filterSomosCampusCenters(
        centers,
        categories: {'Campus Centers'},
      ).map((center) => center.name),
      ['PRIDE Center', 'Dreamer Resource Center'],
    );
    expect(
      filterSomosCampusCenters(centers, categories: {'Basic Needs'}),
      isEmpty,
    );
    expect(
      filterSomosCampusCenters(centers, query: 'no such center'),
      isEmpty,
    );
  });

  test('center attributes provide the fields used by the info card', () {
    final center = SomosCampusCenter.fromJson(_centerJson());
    final attributes = center.toAttributes();

    expect(attributes['NAME'], 'Test Center');
    expect(attributes['ADDRESS'], 'Lassen Hall, Room 3003');
    expect(attributes['CATEGORY'], 'Campus Centers');
    expect(attributes['DESCRIPTION'], contains('scholarship'));
    expect(attributes['WEBSITE'], 'https://www.csus.edu/');
    expect(attributes['ICON_ASSET'], SomosCampusCenter.placeholderIconAsset);
    expect(attributes['BACKGROUND'], '');
    expect(attributes['SUPPORT_SERVICES'], 'Advising\nScholarships');
    expect(attributes['LATITUDE'], 38.56091);
    expect(attributes['LONGITUDE'], -121.42405);
  });

  test('a center icon resolves to its bundled asset path', () {
    final center = SomosCampusCenter.fromJson(_centerJson(icon: 'HSI.png'));

    expect(center.iconAsset, '${somosCampusCenterIconDirectory}HSI.png');
    expect(center.toAttributes()['ICON_ASSET'], center.iconAsset);

    final fallback = SomosCampusCenter.fromJson(_centerJson(icon: ''));
    expect(fallback.iconAsset, SomosCampusCenter.placeholderIconAsset);
  });

  test('every bundled center icon loads from the asset bundle', () async {
    final source = await rootBundle.loadString(somosCampusCentersAsset);
    final centers = parseSomosCampusCenters(source);

    for (final center in centers) {
      final data = await rootBundle.load(center.iconAsset);
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason: 'Missing bundled icon for ${center.name}: ${center.iconAsset}',
      );
    }
  });

  test('the bundled centers declare their solid backgrounds', () async {
    final source = await rootBundle.loadString(somosCampusCentersAsset);
    final centers = parseSomosCampusCenters(source);
    final byName = {for (final center in centers) center.name: center};

    expect(byName['El Centro Serna']?.background, 'darkGreen');
    expect(byName['El Centro Serna']?.backgroundPadding, 0.08);
    expect(byName['MESA']?.background, 'white');
    expect(byName['MESA']?.iconScale, 1.15);
    expect(byName['Dreamer Resource Center']?.background, '');
    expect(byName['Dreamer Resource Center']?.iconScale, 1.15);
    expect(byName['The Well']?.background, 'darkGreen');
  });
}


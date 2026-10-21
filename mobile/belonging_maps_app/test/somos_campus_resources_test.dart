import 'dart:convert';

import 'package:belonging_maps_app/models/somos_campus_resource.dart';
import 'package:belonging_maps_app/services/somos_campus_resources.dart';
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

Map<String, dynamic> _resourceJson({
  int number = 1,
  String name = 'Test Resource',
  String building = 'Lassen Hall',
  String room = '2201',
  String category = 'Academic & Accessibility',
  String description = 'A test resource with tutoring support.',
  String website = 'https://www.csus.edu/',
  double latitude = 38.56091,
  double longitude = -121.42405,
}) {
  return <String, dynamic>{
    'number': number,
    'name': name,
    'building': building,
    'room': room,
    'category': category,
    'description': description,
    'website': website,
    'phone': '',
    'email': '',
    'latitude': latitude,
    'longitude': longitude,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the bundled dataset contains 17 valid, uniquely numbered resources',
    () async {
      final source = await rootBundle.loadString(somosCampusResourcesAsset);
      final resources = parseSomosCampusResources(source);

      expect(resources, hasLength(17));
      expect(
        resources.map((resource) => resource.number),
        orderedEquals(List<int>.generate(17, (index) => index + 1)),
      );

      for (final resource in resources) {
        expect(resource.name.trim(), isNotEmpty);
        expect(resource.building.trim(), isNotEmpty);
        expect(resource.description.trim(), isNotEmpty);
        expect(resource.category.trim(), isNotEmpty);
        expect(resource.website, startsWith('https://'));
        expect(resource.latitude, inInclusiveRange(38.54, 38.58));
        expect(resource.longitude, inInclusiveRange(-121.44, -121.40));
      }
    },
  );

  test(
    'loadSomosCampusResources reads and parses the configured asset',
    () async {
      final bundle = _FakeAssetBundle({
        somosCampusResourcesAsset: jsonEncode([_resourceJson()]),
      });

      final resources = await loadSomosCampusResources(bundle: bundle);

      expect(resources, hasLength(1));
      expect(resources.single.name, 'Test Resource');
      expect(resources.single.locationLabel, 'Lassen Hall, Room 2201');
    },
  );

  test('loadSomosCampusResources throws when the asset is missing', () async {
    final bundle = _FakeAssetBundle({});

    await expectLater(
      loadSomosCampusResources(bundle: bundle),
      throwsA(isA<FlutterError>()),
    );
  });

  test('malformed JSON throws a FormatException', () {
    expect(() => parseSomosCampusResources('{not json'), throwsFormatException);
  });

  test('an empty dataset throws a FormatException', () {
    expect(() => parseSomosCampusResources('[]'), throwsFormatException);
  });

  test('duplicate resource numbers throw a FormatException', () {
    final source = jsonEncode([
      _resourceJson(number: 1),
      _resourceJson(number: 1, name: 'Another Resource'),
    ]);

    expect(() => parseSomosCampusResources(source), throwsFormatException);
  });

  test('invalid resource fields throw a FormatException', () {
    expect(
      () => SomosCampusResource.fromJson(_resourceJson()..remove('name')),
      throwsFormatException,
    );
    expect(
      () => SomosCampusResource.fromJson(_resourceJson(latitude: 200)),
      throwsFormatException,
    );
    expect(
      () => SomosCampusResource.fromJson(
        _resourceJson(website: 'ftp://www.csus.edu/'),
      ),
      throwsFormatException,
    );
  });

  test('filtering matches names, buildings, descriptions, and categories', () {
    final resources = [
      SomosCampusResource.fromJson(
        _resourceJson(
          number: 1,
          name: 'Peer & Academic Resource Center',
          building: 'University Library',
          room: '4026',
          category: 'Academic & Accessibility',
          description: 'Tutoring and supplemental instruction.',
        ),
      ),
      SomosCampusResource.fromJson(
        _resourceJson(
          number: 2,
          name: 'ASI Food Pantry',
          building: 'University Union',
          room: '1246',
          category: 'Basic Needs',
          description: 'Free groceries and basic necessities.',
        ),
      ),
    ];

    expect(
      filterSomosCampusResources(
        resources,
        query: 'library',
      ).map((resource) => resource.name),
      ['Peer & Academic Resource Center'],
    );
    expect(
      filterSomosCampusResources(
        resources,
        query: 'groceries',
      ).map((resource) => resource.name),
      ['ASI Food Pantry'],
    );
    expect(
      filterSomosCampusResources(
        resources,
        categories: {'Academic & Accessibility'},
      ).map((resource) => resource.name),
      ['Peer & Academic Resource Center'],
    );
    expect(
      filterSomosCampusResources(
        resources,
        query: 'groceries',
        categories: {'Basic Needs'},
      ).map((resource) => resource.name),
      ['ASI Food Pantry'],
    );
    expect(
      filterSomosCampusResources(resources, query: 'no such resource'),
      isEmpty,
    );
  });

  test('category filter expressions are parsed into category names', () {
    expect(
      parseCategoryFilterExpression(
        "CATEGORY IN ('Basic Needs', 'Campus Life')",
      ),
      {'Basic Needs', 'Campus Life'},
    );
    expect(parseCategoryFilterExpression(''), isEmpty);
  });

  test('resource attributes provide the fields used by the info card', () {
    final resource = SomosCampusResource.fromJson(_resourceJson());
    final attributes = resource.toAttributes();

    expect(attributes['NAME'], 'Test Resource');
    expect(attributes['ADDRESS'], 'Lassen Hall, Room 2201');
    expect(attributes['CATEGORY'], 'Academic & Accessibility');
    expect(attributes['DESCRIPTION'], contains('tutoring'));
    expect(attributes['WEBSITE'], 'https://www.csus.edu/');
    expect(attributes['LATITUDE'], 38.56091);
    expect(attributes['LONGITUDE'], -121.42405);
  });
}

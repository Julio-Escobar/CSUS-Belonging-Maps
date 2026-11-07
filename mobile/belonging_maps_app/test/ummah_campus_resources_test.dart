import 'dart:convert';

import 'package:belonging_maps_app/models/ummah_campus_resource.dart';
import 'package:belonging_maps_app/services/ummah_campus_resources.dart';
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
    'the bundled dataset contains 22 valid, uniquely numbered resources',
    () async {
      final source = await rootBundle.loadString(ummahCampusResourcesAsset);
      final resources = parseUmmahCampusResources(source);

      expect(resources, hasLength(22));
      expect(
        resources.map((resource) => resource.number),
        orderedEquals(List<int>.generate(22, (index) => index + 1)),
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

  test('the bundled dataset lists the story map sections', () async {
    final source = await rootBundle.loadString(ummahCampusResourcesAsset);
    final resources = parseUmmahCampusResources(source);
    final names = resources.map((resource) => resource.name).toList();

    expect(names, contains('Islamophobia Advisory Council'));
    expect(names, contains('Basic Needs Resource Center (BNRC)'));
    expect(names, contains('Muslim Student Association (MSA)'));
    expect(names, contains('Arab Student Union'));
    expect(names, contains('Iraqi Student Association'));
    expect(
      ummahCampusResourceCategories(resources),
      containsAll(<String>[
        'Academic & Accessibility',
        'Basic Needs',
        'Campus Life',
        'Career & Financial',
        'Cultural & Identity',
        'Student Organizations',
      ]),
    );
  });

  test('the student organizations keep distinct markers at the Union', () async {
    final source = await rootBundle.loadString(ummahCampusResourcesAsset);
    final organizations = parseUmmahCampusResources(source)
        .where((resource) => resource.category == 'Student Organizations')
        .toList();

    expect(organizations, hasLength(6));
    expect(
      organizations.map((resource) => resource.building).toSet(),
      {'University Union'},
    );
    // Each marker needs its own position so overlapping orgs stay tappable.
    expect(
      organizations
          .map((resource) => '${resource.latitude},${resource.longitude}')
          .toSet(),
      hasLength(organizations.length),
    );
    for (final organization in organizations) {
      expect(
        organization.website,
        startsWith('https://csus.campusgroups.com/'),
      );
    }
  });

  test(
    'loadUmmahCampusResources reads and parses the configured asset',
    () async {
      final bundle = _FakeAssetBundle({
        ummahCampusResourcesAsset: jsonEncode([_resourceJson()]),
      });

      final resources = await loadUmmahCampusResources(bundle: bundle);

      expect(resources, hasLength(1));
      expect(resources.single.name, 'Test Resource');
      expect(resources.single.locationLabel, 'Lassen Hall, Room 2201');
    },
  );

  test('loadUmmahCampusResources throws when the asset is missing', () async {
    final bundle = _FakeAssetBundle({});

    await expectLater(
      loadUmmahCampusResources(bundle: bundle),
      throwsA(isA<FlutterError>()),
    );
  });

  test('malformed JSON throws a FormatException', () {
    expect(
      () => parseUmmahCampusResources('{not json'),
      throwsFormatException,
    );
  });

  test('an empty dataset throws a FormatException', () {
    expect(() => parseUmmahCampusResources('[]'), throwsFormatException);
  });

  test('duplicate resource numbers throw a FormatException', () {
    final source = jsonEncode([
      _resourceJson(number: 1),
      _resourceJson(number: 1, name: 'Another Resource'),
    ]);

    expect(() => parseUmmahCampusResources(source), throwsFormatException);
  });

  test('invalid resource fields throw a FormatException', () {
    expect(
      () => UmmahCampusResource.fromJson(_resourceJson()..remove('name')),
      throwsFormatException,
    );
    expect(
      () => UmmahCampusResource.fromJson(_resourceJson(latitude: 200)),
      throwsFormatException,
    );
    expect(
      () => UmmahCampusResource.fromJson(
        _resourceJson(website: 'ftp://www.csus.edu/'),
      ),
      throwsFormatException,
    );
  });

  test('filtering matches names, buildings, descriptions, and categories', () {
    final resources = [
      UmmahCampusResource.fromJson(
        _resourceJson(
          number: 1,
          name: 'Muslim Student Association (MSA)',
          building: 'University Union',
          room: '',
          category: 'Student Organizations',
          description: 'A safe, inclusive space for Muslims on campus.',
        ),
      ),
      UmmahCampusResource.fromJson(
        _resourceJson(
          number: 2,
          name: 'Basic Needs Resource Center (BNRC)',
          building: 'The WELL',
          room: '1031',
          category: 'Basic Needs',
          description: 'Free groceries and basic necessities.',
        ),
      ),
    ];

    expect(
      filterUmmahCampusResources(
        resources,
        query: 'union',
      ).map((resource) => resource.name),
      ['Muslim Student Association (MSA)'],
    );
    expect(
      filterUmmahCampusResources(
        resources,
        query: 'groceries',
      ).map((resource) => resource.name),
      ['Basic Needs Resource Center (BNRC)'],
    );
    expect(
      filterUmmahCampusResources(
        resources,
        categories: {'Student Organizations'},
      ).map((resource) => resource.name),
      ['Muslim Student Association (MSA)'],
    );
    expect(
      filterUmmahCampusResources(resources, query: 'no such resource'),
      isEmpty,
    );
  });

  test('category filter expressions are parsed into category names', () {
    expect(
      parseUmmahCategoryFilterExpression(
        "CATEGORY IN ('Basic Needs', 'Student Organizations')",
      ),
      {'Basic Needs', 'Student Organizations'},
    );
    expect(parseUmmahCategoryFilterExpression(''), isEmpty);
  });

  test('resource attributes provide the fields used by the info card', () {
    final resource = UmmahCampusResource.fromJson(_resourceJson());
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

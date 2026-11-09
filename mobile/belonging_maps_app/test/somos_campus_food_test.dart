import 'dart:convert';

import 'package:belonging_maps_app/models/somos_campus_food.dart';
import 'package:belonging_maps_app/services/somos_campus_food.dart';
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

Map<String, dynamic> _foodJson({
  String id = 'test-food',
  String name = 'Test Taqueria',
  String building = 'University Union',
  String room = '',
  String category = 'Latine Food',
  String description = 'A test food option with tacos and burritos.',
  String website = 'https://www.dining.csus.edu/eateries/midtown-taqueria/',
  String icon = '',
  double latitude = 38.5597,
  double longitude = -121.4223,
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
    'latitude': latitude,
    'longitude': longitude,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the bundled dataset contains the Latine food options', () async {
    final source = await rootBundle.loadString(somosCampusFoodAsset);
    final food = parseSomosCampusFood(source);

    expect(food, hasLength(2));
    expect(
      food.map((location) => location.name),
      containsAll(<String>['Midtown Taqueria', 'Dining Commons']),
    );
    expect(food.map((location) => location.id).toSet(), hasLength(food.length));

    for (final location in food) {
      expect(location.name.trim(), isNotEmpty);
      expect(location.building.trim(), isNotEmpty);
      expect(location.description.trim(), isNotEmpty);
      expect(location.category, latineFoodCategory);
      expect(location.latitude, inInclusiveRange(38.54, 38.58));
      expect(location.longitude, inInclusiveRange(-121.44, -121.40));
    }

    final byId = {for (final location in food) location.id: location};
    expect(
      byId['midtown-taqueria']?.website,
      'https://www.dining.csus.edu/eateries/midtown-taqueria/',
    );
    expect(
      byId['dining-commons']?.website,
      'https://www.dining.csus.edu/dining-commons/',
    );
  });

  test('the food category label matches the dataset', () async {
    final source = await rootBundle.loadString(somosCampusFoodAsset);
    final food = parseSomosCampusFood(source);

    expect(latineFoodCategory, 'Latine Food');
    expect(somosCampusFoodCategories(food), {latineFoodCategory});
  });

  test('loadSomosCampusFood reads and parses the configured asset', () async {
    final bundle = _FakeAssetBundle({
      somosCampusFoodAsset: jsonEncode([_foodJson()]),
    });

    final food = await loadSomosCampusFood(bundle: bundle);

    expect(food, hasLength(1));
    expect(food.single.name, 'Test Taqueria');
    expect(food.single.locationLabel, 'University Union');
  });

  test('loadSomosCampusFood throws when the asset is missing', () async {
    final bundle = _FakeAssetBundle({});

    await expectLater(
      loadSomosCampusFood(bundle: bundle),
      throwsA(isA<FlutterError>()),
    );
  });

  test('malformed JSON throws a FormatException', () {
    expect(() => parseSomosCampusFood('{not json'), throwsFormatException);
  });

  test('an empty dataset throws a FormatException', () {
    expect(() => parseSomosCampusFood('[]'), throwsFormatException);
  });

  test('duplicate food ids throw a FormatException', () {
    final source = jsonEncode([
      _foodJson(id: 'same-id'),
      _foodJson(id: 'same-id', name: 'Another Taqueria'),
    ]);

    expect(() => parseSomosCampusFood(source), throwsFormatException);
  });

  test('invalid food fields throw a FormatException', () {
    expect(
      () => SomosCampusFood.fromJson(_foodJson()..remove('name')),
      throwsFormatException,
    );
    expect(
      () => SomosCampusFood.fromJson(_foodJson(latitude: 200)),
      throwsFormatException,
    );
    expect(
      () => SomosCampusFood.fromJson(_foodJson(website: 'ftp://www.csus.edu/')),
      throwsFormatException,
    );
  });

  test('filtering matches names, buildings, descriptions, and categories', () {
    final food = [
      SomosCampusFood.fromJson(
        _foodJson(
          id: 'midtown',
          name: 'Midtown Taqueria',
          building: 'University Union',
          description: 'Fresh tacos, burritos, and Mexican favorites.',
        ),
      ),
      SomosCampusFood.fromJson(
        _foodJson(
          id: 'commons',
          name: 'Dining Commons',
          building: 'University North',
          description: 'All-you-care-to-eat dining and meal plans.',
          icon: 'HF11px.png',
        ),
      ),
    ];

    expect(
      filterSomosCampusFood(
        food,
        query: 'burritos',
      ).map((location) => location.name),
      ['Midtown Taqueria'],
    );
    expect(
      filterSomosCampusFood(
        food,
        query: 'university north',
      ).map((location) => location.name),
      ['Dining Commons'],
    );
    expect(
      filterSomosCampusFood(
        food,
        categories: {latineFoodCategory},
      ).map((location) => location.name),
      ['Midtown Taqueria', 'Dining Commons'],
    );
    expect(
      filterSomosCampusFood(food, categories: {'Campus Centers'}),
      isEmpty,
    );
    expect(filterSomosCampusFood(food, query: 'no such food option'), isEmpty);
  });

  test('food attributes provide the fields used by the info card', () {
    final location = SomosCampusFood.fromJson(_foodJson());
    final attributes = location.toAttributes();

    expect(attributes['NAME'], 'Test Taqueria');
    expect(attributes['ADDRESS'], 'University Union');
    expect(attributes['CATEGORY'], 'Latine Food');
    expect(attributes['DESCRIPTION'], contains('tacos'));
    expect(
      attributes['WEBSITE'],
      'https://www.dining.csus.edu/eateries/midtown-taqueria/',
    );
    expect(attributes['ICON_ASSET'], SomosCampusFood.defaultIconAsset);
    expect(attributes['LATITUDE'], 38.5597);
    expect(attributes['LONGITUDE'], -121.4223);
  });

  test('a food icon resolves to its bundled asset path', () {
    final food = SomosCampusFood.fromJson(_foodJson(icon: 'Tacos11px.png'));

    expect(food.iconAsset, '${somosCampusFoodIconDirectory}Tacos11px.png');

    final fallback = SomosCampusFood.fromJson(_foodJson(icon: ''));
    expect(fallback.iconAsset, SomosCampusFood.defaultIconAsset);
    expect(
      SomosCampusFood.defaultIconAsset,
      'assets/map_icons/food/HF11px.png',
    );
  });

  test('every bundled food icon loads from the asset bundle', () async {
    final source = await rootBundle.loadString(somosCampusFoodAsset);
    final food = parseSomosCampusFood(source);

    for (final location in food) {
      final data = await rootBundle.load(location.iconAsset);
      expect(
        data.lengthInBytes,
        greaterThan(0),
        reason:
            'Missing bundled icon for ${location.name}: '
            '${location.iconAsset}',
      );
    }
  });
}

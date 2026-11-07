import 'package:belonging_maps_app/models/ummah_campus_food.dart';
import 'package:belonging_maps_app/services/ummah_campus_food.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled halal food dataset', () {
    test('lists the two story map halal options', () async {
      final food = await loadUmmahCampusFood();

      expect(food, hasLength(2));
      expect(
        food.map((option) => option.name),
        orderedEquals(['Gyro 2 Go', 'Student Dining Hall']),
      );
      expect(
        food.map((option) => option.building).toSet(),
        {'River Front Center', 'American River Courtyard'},
      );
      expect(
        food.map((option) => option.category).toSet(),
        {ummahCampusFoodCategory},
      );
    });

    test('every option has a usable marker and location', () async {
      final food = await loadUmmahCampusFood();

      for (final option in food) {
        expect(option.id.trim(), isNotEmpty);
        expect(option.description.trim(), isNotEmpty);
        expect(option.iconAsset, UmmahCampusFood.defaultIconAsset);
        expect(option.website, startsWith('https://'));
        expect(option.latitude, inInclusiveRange(38.54, 38.58));
        expect(option.longitude, inInclusiveRange(-121.44, -121.40));
      }
    });

    test('each option links to its own dining page', () async {
      final food = await loadUmmahCampusFood();
      final byId = {for (final option in food) option.id: option};

      expect(
        byId['gyro-2-go']?.website,
        'https://www.dining.csus.edu/gyro-2-go-new/',
      );
      expect(
        byId['student-dining-hall']?.website,
        'https://www.dining.csus.edu/dining-commons/',
      );

      // Neither option should fall back to the dining home page.
      for (final option in food) {
        expect(option.website, isNot('https://www.dining.csus.edu/'));
      }
    });

    test('the attributes expose the fields the info card reads', () async {
      final food = await loadUmmahCampusFood();
      final attributes = food.first.toAttributes();

      expect(attributes['NAME'], food.first.name);
      expect(attributes['ADDRESS'], food.first.locationLabel);
      expect(attributes['CATEGORY'], ummahCampusFoodCategory);
      expect(attributes['WEBSITE'], food.first.website);
      expect(attributes['ICON_ASSET'], UmmahCampusFood.defaultIconAsset);
      expect(attributes['LONGITUDE'], food.first.longitude);
    });
  });

  group('parsing', () {
    test('rejects malformed JSON, empty lists, and duplicate ids', () {
      expect(() => parseUmmahCampusFood('{not json'), throwsFormatException);
      expect(() => parseUmmahCampusFood('[]'), throwsFormatException);
      expect(
        () => parseUmmahCampusFood(
          '[{"id":"a","name":"A","building":"B","category":"Halal Food",'
          '"description":"D","latitude":38.56,"longitude":-121.42},'
          '{"id":"a","name":"A2","building":"B","category":"Halal Food",'
          '"description":"D","latitude":38.56,"longitude":-121.42}]',
        ),
        throwsFormatException,
      );
    });

    test('rejects an invalid website and missing fields', () {
      final base = <String, dynamic>{
        'id': 'gyro-2-go',
        'name': 'Gyro 2 Go',
        'building': 'River Front Center',
        'category': 'Halal Food',
        'description': 'A halal dining option.',
        'latitude': 38.563549,
        'longitude': -121.423944,
      };

      expect(
        () => UmmahCampusFood.fromJson({...base}..remove('building')),
        throwsFormatException,
      );
      expect(
        () => UmmahCampusFood.fromJson({...base, 'website': 'ftp://x/'}),
        throwsFormatException,
      );
      expect(
        () => UmmahCampusFood.fromJson({...base, 'longitude': -300.0}),
        throwsFormatException,
      );
    });
  });

  group('filtering', () {
    late List<UmmahCampusFood> food;

    setUp(() async {
      food = await loadUmmahCampusFood();
    });

    test('matches names, buildings, and categories', () {
      expect(
        filterUmmahCampusFood(food, query: 'courtyard').single.name,
        'Student Dining Hall',
      );
      expect(
        filterUmmahCampusFood(
          food,
          categories: {ummahCampusFoodCategory},
        ),
        hasLength(2),
      );
      expect(
        filterUmmahCampusFood(food, categories: {'Basic Needs'}),
        isEmpty,
      );
      expect(filterUmmahCampusFood(food, query: 'no such food'), isEmpty);
    });
  });
}

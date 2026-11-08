import 'package:belonging_maps_app/models/ummah_campus_prayer.dart';
import 'package:belonging_maps_app/services/ummah_campus_prayer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bundled prayer room dataset', () {
    test('lists the two story map prayer rooms', () async {
      final rooms = await loadUmmahCampusPrayer();

      expect(rooms, hasLength(2));
      expect(
        rooms.map((room) => room.building),
        orderedEquals(['Folsom Hall', 'University Union']),
      );
      expect(
        rooms.map((room) => room.category).toSet(),
        {ummahCampusPrayerCategory},
      );
      expect(
        rooms.map((room) => room.floor),
        everyElement('2nd floor'),
      );
    });

    test('every room has a usable marker and location', () async {
      final rooms = await loadUmmahCampusPrayer();

      for (final room in rooms) {
        expect(room.id.trim(), isNotEmpty);
        expect(room.name.trim(), isNotEmpty);
        expect(room.description.trim(), isNotEmpty);
        expect(room.amenities, contains('Wudu stations'));
        expect(room.iconAsset, UmmahCampusPrayer.defaultIconAsset);
        expect(room.website, anyOf(isEmpty, startsWith('https://')));
        expect(room.latitude, inInclusiveRange(38.54, 38.58));
        expect(room.longitude, inInclusiveRange(-121.44, -121.40));
      }
    });

    test('the location label names the building and the floor', () async {
      final rooms = await loadUmmahCampusPrayer();
      final folsom = rooms.firstWhere(
        (room) => room.building == 'Folsom Hall',
      );

      expect(folsom.locationLabel, 'Folsom Hall, 2nd floor');
    });

    test('the descriptions are not padded with story map boilerplate', () async {
      final rooms = await loadUmmahCampusPrayer();

      for (final room in rooms) {
        expect(room.description, isNot(contains('Ummah Resource Map')));
        expect(room.description, isNot(contains('one of the two')));
      }
    });

    test('the attributes expose the fields the info card reads', () async {
      final rooms = await loadUmmahCampusPrayer();
      final attributes = rooms.first.toAttributes();

      expect(attributes['NAME'], rooms.first.name);
      expect(attributes['ADDRESS'], rooms.first.locationLabel);
      expect(attributes['CATEGORY'], ummahCampusPrayerCategory);
      expect(attributes['AMENITIES'], contains('Prayer space'));
      expect(attributes['ICON_ASSET'], UmmahCampusPrayer.defaultIconAsset);
      expect(attributes['LATITUDE'], rooms.first.latitude);
    });
  });

  group('parsing', () {
    test('rejects malformed JSON, empty lists, and duplicate ids', () {
      expect(() => parseUmmahCampusPrayer('{not json'), throwsFormatException);
      expect(() => parseUmmahCampusPrayer('[]'), throwsFormatException);
      expect(
        () => parseUmmahCampusPrayer(
          '[{"id":"a","name":"A","building":"B","category":"C",'
          '"description":"D","latitude":38.56,"longitude":-121.42},'
          '{"id":"a","name":"A2","building":"B","category":"C",'
          '"description":"D","latitude":38.56,"longitude":-121.42}]',
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid coordinates and websites', () {
      final base = <String, dynamic>{
        'id': 'a',
        'name': 'Prayer Room',
        'building': 'Folsom Hall',
        'category': 'Prayer & Wudu',
        'description': 'A prayer room.',
        'latitude': 38.551412,
        'longitude': -121.414278,
      };

      expect(
        () => UmmahCampusPrayer.fromJson({...base}..remove('name')),
        throwsFormatException,
      );
      expect(
        () => UmmahCampusPrayer.fromJson({...base, 'latitude': 200.0}),
        throwsFormatException,
      );
      expect(
        () => UmmahCampusPrayer.fromJson(
          {...base, 'website': 'not a website'},
        ),
        throwsFormatException,
      );
    });
  });

  group('filtering', () {
    late List<UmmahCampusPrayer> rooms;

    setUp(() async {
      rooms = await loadUmmahCampusPrayer();
    });

    test('matches the building, the floor, and the amenities', () {
      expect(
        filterUmmahCampusPrayer(rooms, query: 'folsom').single.building,
        'Folsom Hall',
      );
      expect(
        filterUmmahCampusPrayer(rooms, query: 'wudu'),
        hasLength(2),
      );
      expect(
        filterUmmahCampusPrayer(rooms, query: 'no such room'),
        isEmpty,
      );
    });

    test('honours the category filter', () {
      expect(
        filterUmmahCampusPrayer(
          rooms,
          categories: {ummahCampusPrayerCategory},
        ),
        hasLength(2),
      );
      expect(
        filterUmmahCampusPrayer(rooms, categories: {'Halal Food'}),
        isEmpty,
      );
    });
  });
}

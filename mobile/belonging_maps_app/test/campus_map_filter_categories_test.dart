import 'package:belonging_maps_app/models/somos_campus_center.dart';
import 'package:belonging_maps_app/models/somos_campus_food.dart';
import 'package:belonging_maps_app/models/somos_campus_resource.dart';
import 'package:belonging_maps_app/models/ubuntu_campus_center.dart';
import 'package:belonging_maps_app/models/ubuntu_campus_resource.dart';
import 'package:belonging_maps_app/models/ummah_campus_center.dart';
import 'package:belonging_maps_app/models/ummah_campus_food.dart';
import 'package:belonging_maps_app/models/ummah_campus_prayer.dart';
import 'package:belonging_maps_app/models/ummah_campus_resource.dart';
import 'package:belonging_maps_app/screens/somos_campus_map.dart';
import 'package:belonging_maps_app/screens/ubuntu_campus_map.dart';
import 'package:belonging_maps_app/screens/ummah_campus_map.dart';
import 'package:belonging_maps_app/services/latine_art_locations.dart';
import 'package:belonging_maps_app/services/map_location_source.dart';
import 'package:belonging_maps_app/services/somos_campus_centers.dart';
import 'package:belonging_maps_app/services/somos_campus_food.dart';
import 'package:belonging_maps_app/services/somos_campus_resources.dart';
import 'package:belonging_maps_app/services/ubuntu_campus_centers.dart';
import 'package:belonging_maps_app/services/ubuntu_campus_resources.dart';
import 'package:belonging_maps_app/services/ummah_campus_centers.dart';
import 'package:belonging_maps_app/services/ummah_campus_food.dart';
import 'package:belonging_maps_app/services/ummah_campus_prayer.dart';
import 'package:belonging_maps_app/services/ummah_campus_resources.dart';
import 'package:flutter_test/flutter_test.dart';

UmmahCampusResource _ummahResource() => const UmmahCampusResource(
  number: 1,
  name: 'Test Resource',
  building: 'Lassen Hall',
  category: 'Basic Needs',
  description: 'A test resource.',
  website: 'https://www.csus.edu/',
  latitude: 38.56091,
  longitude: -121.42405,
);

UmmahCampusCenter _ummahCenter() => const UmmahCampusCenter(
  id: 'test-center',
  name: 'Test Center',
  building: 'Lassen Hall',
  category: 'Campus Centers',
  description: 'A test center.',
  website: 'https://www.csus.edu/',
  latitude: 38.56091,
  longitude: -121.42405,
);

UmmahCampusFood _ummahFood() => const UmmahCampusFood(
  id: 'test-food',
  name: 'Test Food',
  building: 'River Front Center',
  category: 'Halal Food',
  description: 'A test food option.',
  latitude: 38.56091,
  longitude: -121.42405,
);

UmmahCampusPrayer _ummahPrayer() => const UmmahCampusPrayer(
  id: 'test-prayer',
  name: 'Test Prayer Room',
  building: 'Folsom Hall',
  category: 'Prayer & Wudu',
  description: 'A test prayer room.',
  latitude: 38.56091,
  longitude: -121.42405,
);

SomosCampusResource _somosResource() => const SomosCampusResource(
  number: 1,
  name: 'Test Resource',
  building: 'Lassen Hall',
  category: 'Basic Needs',
  description: 'A test resource.',
  website: 'https://www.csus.edu/',
  latitude: 38.56091,
  longitude: -121.42405,
);

SomosCampusCenter _somosCenter() => const SomosCampusCenter(
  id: 'test-center',
  name: 'Test Center',
  building: 'Lassen Hall',
  category: 'Campus Centers',
  description: 'A test center.',
  website: 'https://www.csus.edu/',
  latitude: 38.56091,
  longitude: -121.42405,
);

SomosCampusFood _somosFood() => const SomosCampusFood(
  id: 'test-food',
  name: 'Test Food',
  building: 'River Front Center',
  category: 'Latine Food',
  description: 'A test food option.',
  latitude: 38.56091,
  longitude: -121.42405,
);

MapLocation _latineArtLocation() => MapLocation(
  name: 'Test Art',
  category: latineArtCategory,
  attributes: <String, dynamic>{},
);

UbuntuCampusResource _ubuntuResource() => const UbuntuCampusResource(
  number: 1,
  name: 'Test Resource',
  building: 'Lassen Hall',
  category: 'Academic Support',
  description: 'A test resource.',
  website: 'https://www.csus.edu/',
  latitude: 38.56091,
  longitude: -121.42405,
);

UbuntuCampusCenter _ubuntuCenter() => const UbuntuCampusCenter(
  id: 'test-center',
  name: 'Test Center',
  building: 'Lassen Hall',
  category: 'Cultural & Identity',
  description: 'A test center.',
  website: 'https://www.csus.edu/',
  latitude: 38.56091,
  longitude: -121.42405,
);

void main() {
  group('Ummah campus map filter categories', () {
    test('mirrors the Browse locations sections', () {
      expect(
        ummahCampusFilterCategories(
          resources: [_ummahResource()],
          centers: [_ummahCenter()],
          food: [_ummahFood()],
          prayers: [_ummahPrayer()],
        ),
        {
          ummahCampusPrayerCategory,
          ummahCampusFoodCategory,
          ummahCampusCentersCategory,
          ummahCampusResourcesCategory,
        },
      );
    });

    test('leaves out sections without locations', () {
      expect(
        ummahCampusFilterCategories(
          resources: [_ummahResource()],
          centers: const [],
          food: const [],
          prayers: const [],
        ),
        {ummahCampusResourcesCategory},
      );
      expect(
        ummahCampusFilterCategories(
          resources: const [],
          centers: const [],
          food: const [],
          prayers: const [],
        ),
        isEmpty,
      );
    });
  });

  group('SOMOS campus map filter categories', () {
    test('mirrors the Browse locations sections', () {
      expect(
        somosCampusFilterCategories(
          resources: [_somosResource()],
          centers: [_somosCenter()],
          food: [_somosFood()],
          latineArtLocations: [_latineArtLocation()],
        ),
        {
          latineArtCategory,
          latineFoodCategory,
          somosCampusCentersCategory,
          somosCampusResourcesCategory,
        },
      );
    });

    test('leaves out the art section when the layer has no locations', () {
      expect(
        somosCampusFilterCategories(
          resources: [_somosResource()],
          centers: const [],
          food: const [],
          latineArtLocations: const [],
        ),
        {somosCampusResourcesCategory},
      );
    });
  });

  group('Ubuntu campus map filter categories', () {
    test('mirrors the Browse locations sections', () {
      expect(
        ubuntuCampusFilterCategories(
          resources: [_ubuntuResource()],
          centers: [_ubuntuCenter()],
        ),
        {ubuntuCampusCentersCategory, ubuntuCampusResourcesCategory},
      );
    });

    test('leaves out sections without locations', () {
      expect(
        ubuntuCampusFilterCategories(
          resources: const [],
          centers: [_ubuntuCenter()],
        ),
        {ubuntuCampusCentersCategory},
      );
    });
  });
}

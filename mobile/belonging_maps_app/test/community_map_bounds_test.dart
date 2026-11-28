import 'package:belonging_maps_app/services/community_map_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coordinates measured from the live feature services on 2026-11-27. Each
/// entry names the place the box must keep reachable, so a future edit that
/// shrinks the box fails with something readable instead of an anonymous
/// number.
const Map<String, (double latitude, double longitude)> _insideListings = {
  'Sacramento State': (38.56091, -121.42405),
  'Woodland': (38.67852, -121.77330),
  'Davis': (38.54491, -121.74052),
  'Folsom': (38.67796, -121.17606),
  'Auburn': (38.89657, -121.07689),
  'El Dorado Hills': (38.68574, -121.08217),
  'Granite Bay': (38.76324, -121.16384),
};

/// The listings that sit outside the region. They stay available through Browse
/// and search, but the map should not pan to them, so they must stay outside.
const Map<String, (double latitude, double longitude)> _outsideListings = {
  'San Francisco': (37.77493, -122.41942),
  'Visalia': (36.33023, -119.29206),
  'Orange': (33.78779, -117.85311),
  'Southern California religious place': (33.86652, -118.09271),
  'Illinois community service': (41.87811, -87.62980),
};

void main() {
  group('community map extent', () {
    test('is an ordered, plausible WGS84 box', () {
      expect(communityMapExtentXMin, lessThan(communityMapExtentXMax));
      expect(communityMapExtentYMin, lessThan(communityMapExtentYMax));
      expect(communityMapExtentXMin, greaterThanOrEqualTo(-180));
      expect(communityMapExtentXMax, lessThanOrEqualTo(180));
      expect(communityMapExtentYMin, greaterThanOrEqualTo(-90));
      expect(communityMapExtentYMax, lessThanOrEqualTo(90));
      expect(
        communityMapExtentXMax - communityMapExtentXMin,
        lessThan(10),
        reason: 'A wider box would stop constraining panning and tile usage',
      );
    });

    test('contains campus and the nearby-city listings', () {
      _insideListings.forEach((place, coordinates) {
        expect(
          _contains(coordinates.$1, coordinates.$2),
          isTrue,
          reason: '$place must stay reachable on the panning map',
        );
      });
    });

    test('excludes the known out-of-region listings', () {
      _outsideListings.forEach((place, coordinates) {
        expect(
          _contains(coordinates.$1, coordinates.$2),
          isFalse,
          reason: '$place should only be reachable through Browse and search',
        );
      });
    });
  });
}

bool _contains(double latitude, double longitude) =>
    longitude >= communityMapExtentXMin &&
    longitude <= communityMapExtentXMax &&
    latitude >= communityMapExtentYMin &&
    latitude <= communityMapExtentYMax;

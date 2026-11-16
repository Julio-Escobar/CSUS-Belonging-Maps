import 'package:belonging_maps_app/services/map_tap_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapIconTapTolerance', () {
    test('covers the icon plus a little slop', () {
      expect(mapIconTapTolerance(40), 24);
      expect(mapIconTapTolerance(56), 32);
    });

    test('never shrinks below the recommended finger radius', () {
      expect(mapIconTapTolerance(10), minimumMapTapTolerance);
      expect(mapIconTapTolerance(28), minimumMapTapTolerance);
    });

    test('is capped at the SDK maximum', () {
      expect(mapIconTapTolerance(400), maximumMapTapTolerance);
    });

    test('falls back to the finger radius for invalid sizes', () {
      expect(mapIconTapTolerance(double.nan), minimumMapTapTolerance);
      expect(mapIconTapTolerance(-40), minimumMapTapTolerance);
    });
  });

  group('nearestMapTapCandidate', () {
    test('chooses the nearest icon regardless of list order', () {
      const candidates = [
        MapTapCandidate(
          value: 'far',
          screenPoint: Offset(0, 100),
          tolerance: 30,
        ),
        MapTapCandidate(
          value: 'near',
          screenPoint: Offset(0, 10),
          tolerance: 30,
        ),
        MapTapCandidate(
          value: 'middle',
          screenPoint: Offset(0, 50),
          tolerance: 30,
        ),
      ];

      expect(nearestMapTapCandidate(candidates, Offset.zero), 'near');
    });

    test('ignores icons whose own target does not contain the tap', () {
      const candidates = [
        MapTapCandidate(
          value: 'small',
          screenPoint: Offset(0, 5),
          tolerance: 4,
        ),
        MapTapCandidate(
          value: 'large',
          screenPoint: Offset(0, 18),
          tolerance: 24,
        ),
      ];

      expect(nearestMapTapCandidate(candidates, Offset.zero), 'large');
    });

    test('prefers the first (top-most) icon when distances tie', () {
      const candidates = [
        MapTapCandidate(value: 'top', screenPoint: Offset(4, 0), tolerance: 22),
        MapTapCandidate(
          value: 'bottom',
          screenPoint: Offset(4, 0),
          tolerance: 22,
        ),
      ];

      expect(nearestMapTapCandidate(candidates, Offset.zero), 'top');
    });

    test('returns null when the tap misses every icon', () {
      const candidates = [
        MapTapCandidate(
          value: 'far',
          screenPoint: Offset(0, 50),
          tolerance: 10,
        ),
      ];

      expect(nearestMapTapCandidate(candidates, Offset.zero), isNull);
    });
  });
}

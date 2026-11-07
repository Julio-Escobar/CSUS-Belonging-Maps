import 'package:belonging_maps_app/models/ummah_campus_center.dart';
import 'package:belonging_maps_app/screens/ummah_campus_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// The placeholder the map draws for centers that have no logo of their own.
const String _placeholder = UmmahCampusCenter.placeholderIconAsset;

/// A bundled center logo, drawn larger than the placeholder.
const String _swanaLogo =
    'assets/ummah_campus_map_assets/'
    'southwest_asian_and_north_african_center.png';

const double _placeholderSize = 40;
const double _logoSize = 56;

void main() {
  group('ummahCenterMarkerBaseSize', () {
    test('centers with their own logo use the larger size', () {
      expect(
        ummahCenterMarkerBaseSize(
          iconAsset: _swanaLogo,
          loadedAssets: const [_placeholder, _swanaLogo],
        ),
        _logoSize,
      );
    });

    test('the shared placeholder keeps the standard marker size', () {
      // UmmahCampusCenter.iconAsset falls back to the placeholder path, so the
      // centers without a logo arrive here with exactly this asset.
      expect(
        ummahCenterMarkerBaseSize(
          iconAsset: _placeholder,
          loadedAssets: const [_placeholder, _swanaLogo],
        ),
        _placeholderSize,
      );
    });

    test('a missing or unloaded logo keeps the standard marker size', () {
      expect(
        ummahCenterMarkerBaseSize(
          iconAsset: null,
          loadedAssets: const [_placeholder],
        ),
        _placeholderSize,
      );
      expect(
        ummahCenterMarkerBaseSize(
          iconAsset: '   ',
          loadedAssets: const [_placeholder],
        ),
        _placeholderSize,
      );
      // The logo file failed to load, so the marker falls back to the
      // placeholder image and the standard size.
      expect(
        ummahCenterMarkerBaseSize(
          iconAsset: _swanaLogo,
          loadedAssets: const [_placeholder],
        ),
        _placeholderSize,
      );
    });

    test('the selected sizes scale every marker the same way', () {
      expect(
        ummahCenterMarkerBaseSize(
          iconAsset: _swanaLogo,
          loadedAssets: const [_placeholder, _swanaLogo],
          size: 56,
          logoSize: 80,
        ),
        80,
      );
      expect(
        ummahCenterMarkerBaseSize(
          iconAsset: _placeholder,
          loadedAssets: const [_placeholder, _swanaLogo],
          size: 56,
          logoSize: 80,
        ),
        56,
      );
    });
  });

  group('bundled centers pick the right marker size', () {
    test('centers without a logo keep the placeholder marker size', () {
      // The three centers that are still waiting for their own logo.
      for (final id in ['cares', 'shcws', 'multi-cultural-center']) {
        final center = UmmahCampusCenter(
          id: id,
          name: id,
          building: 'The WELL',
          category: 'Campus Centers',
          description: 'A center.',
          website: 'https://www.csus.edu/',
          latitude: 38.556793,
          longitude: -121.423732,
        );

        expect(center.iconAsset, _placeholder);
        expect(
          ummahCenterMarkerBaseSize(
            iconAsset: center.iconAsset,
            loadedAssets: const [
              _placeholder,
              _swanaLogo,
              'assets/ummah_campus_map_assets/iranian_and_middle_eastern_studies_center.png',
            ],
          ),
          _placeholderSize,
        );
      }
    });

    test('a center with an icon gets the larger marker', () {
      final center = UmmahCampusCenter.fromJson(const {
        'id': 'swana-center',
        'name': 'Southwest Asian and North African Center',
        'building': 'AIRC',
        'category': 'Campus Centers',
        'description': 'A center.',
        'website': 'https://www.csus.edu/',
        'icon': 'southwest_asian_and_north_african_center.png',
        'latitude': 38.55904,
        'longitude': -121.42295,
      });

      expect(center.iconAsset, _swanaLogo);
      expect(
        ummahCenterMarkerBaseSize(
          iconAsset: center.iconAsset,
          loadedAssets: [_placeholder, center.iconAsset],
        ),
        _logoSize,
      );
    });
  });
}

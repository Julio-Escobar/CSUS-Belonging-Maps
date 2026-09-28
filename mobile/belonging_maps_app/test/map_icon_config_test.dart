import 'package:belonging_maps_app/constants/map_icon_config.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const communities = {
    'Ummah': ummahLayerIcons,
    'Somos': somosLayerIcons,
    'Ubuntu': ubuntuLayerIcons,
  };

  group('mapIconAssetPath', () {
    test('converts a relative svg path to a bundled png asset', () {
      expect(
        mapIconAssetPath('food/HF11px.svg'),
        'assets/map_icons/food/HF11px.png',
      );
    });
  });

  group('layer icon configurations', () {
    test('configure every layer of each community map', () {
      expect(
        ummahLayerIcons.keys,
        containsAll(<String>[
          'businessServices',
          'communityServices',
          'halalFoods',
          'religiousCultural',
          'education',
        ]),
      );
      expect(
        somosLayerIcons.keys,
        containsAll(<String>[
          'businesses',
          'religion',
          'food',
          'publicArts',
          'communityServices',
          'education',
        ]),
      );
      expect(
        ubuntuLayerIcons.keys,
        containsAll(<String>[
          'businesses',
          'communityServices',
          'religious',
          'education',
        ]),
      );
    });

    test('every referenced icon is bundled in the app assets', () async {
      for (final community in communities.entries) {
        for (final layer in community.value.entries) {
          expect(
            layer.value.fallback,
            isNotEmpty,
            reason: '${community.key}/${layer.key} needs a fallback icon',
          );

          for (final icon in layer.value.referencedIcons) {
            final assetPath = mapIconAssetPath(icon);
            final data = await rootBundle.load(assetPath);
            expect(
              data.lengthInBytes,
              greaterThan(0),
              reason:
                  '${community.key}/${layer.key} references $assetPath, '
                  'which is missing or empty',
            );
          }
        }
      }
    });
    test('maps corrected type values to the right icons', () {
      expect(
        somosLayerIcons['publicArts']!.byType['Sculpture'],
        'public-art/Sculptures.svg',
      );
      expect(
        somosLayerIcons['publicArts']!.byType['Mural'],
        'public-art/Murals11px.svg',
      );
      expect(
        somosLayerIcons['education']!.byType['Preschool and Childcare'],
        'edcuation/PreKindergarten.svg',
      );
      expect(
        ubuntuLayerIcons['education']!.byType['Extra-Curricular'],
        'edcuation/ExtraCurricular11px.svg',
      );
    });
  });
}

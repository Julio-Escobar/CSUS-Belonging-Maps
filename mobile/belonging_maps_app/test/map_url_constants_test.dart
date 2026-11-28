import 'package:belonging_maps_app/constants/campus_map_urls.dart';
import 'package:belonging_maps_app/constants/community_layer_urls.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every community map layer URL paired with the ArcGIS service it must point
/// at. A copy/paste mistake during a refactor fails this test instead of
/// silently drawing the wrong dataset on a map.
const Map<String, String> _communityLayerServices = {
  somosBusinessesLayerUrl: 'SOMOS_Businesses_Admin',
  somosReligionLayerUrl: 'SOMOS_Religion_Admin',
  somosFoodLayerUrl: 'SOMOS_Food_Admin',
  somosPublicArtsLayerUrl: 'SOMOS_PublicArtArtists_Admin',
  somosCommunityServicesLayerUrl: 'SOMOS_CommunityServices_Admin',
  somosEducationLayerUrl: 'SOMOS_Education_Admin',
  ummahBusinessServicesLayerUrl: 'Ummah_BusinessServices_Admin',
  ummahCommunityServicesLayerUrl: 'Ummah_CommunityServices_Admin',
  ummahHalalFoodsLayerUrl: 'Ummah_HalalFoods_Admin',
  ummahReligiousCulturalLayerUrl: 'Ummah_ReligiousCultural_Admin',
  ummahEducationLayerUrl: 'Ummah_Education_Admin',
  ubuntuBusinessesLayerUrl: 'Ubuntu_Businesses_Admin',
  ubuntuCommunityServicesLayerUrl: 'Ubuntu_CommunityServices_Admin',
  ubuntuReligiousLayerUrl: 'Ubuntu_Religious_Admin',
  ubuntuEducationLayerUrl: 'Ubuntu_Education_Admin',
};

void main() {
  group('community layer URLs', () {
    test('are public FeatureServer layers on the Belonging Maps org', () {
      for (final url in _communityLayerServices.keys) {
        expect(
          url,
          startsWith(
            'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/'
            'services/',
          ),
          reason: url,
        );
        expect(
          RegExp(r'/FeatureServer/\d+$').hasMatch(url),
          isTrue,
          reason: url,
        );
      }
    });

    test('each layer points at the service its map draws', () {
      _communityLayerServices.forEach((url, service) {
        expect(url, contains('/$service/FeatureServer/'), reason: url);
      });
    });

    test('no two layers share a URL', () {
      expect(
        _communityLayerServices.keys.toSet(),
        hasLength(_communityLayerServices.length),
      );
    });
  });

  group('campus map URLs', () {
    test('the basemap is the shared CampusBasemapv3 vector tile service', () {
      expect(
        campusBasemapUrl,
        'https://vectortileservices5.arcgis.com/nXNRC1vdZsFxBgaG/arcgis/rest/'
        'services/CampusBasemapv3/VectorTileServer',
      );
    });

    test('the labels style is the Light Gray Reference root.json', () {
      expect(
        campusLabelsStyleUrl,
        'https://www.arcgis.com/sharing/rest/content/items/'
        'a8416e7b45034be7b748071e10dde506/resources/styles/root.json',
      );
    });
  });
}

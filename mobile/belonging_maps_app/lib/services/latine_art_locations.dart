import 'package:arcgis_maps/arcgis_maps.dart';

import '../models/location_attributes.dart';
import 'map_location_source.dart';

/// Point locations of Latine art and artists across the Sacramento State
/// campus, published for the HSI Story Map.
const String sacStateLatineArtLayerUrl =
    'https://services5.arcgis.com/nXNRC1vdZsFxBgaG/arcgis/rest/services/'
    'SacStateLatineArt/FeatureServer/0';

/// Bundled pin drawn for every Latine art location on the SOMOS campus map.
///
/// The `public-art/` folder is registered in `pubspec.yaml`, and the icon is
/// the same rasterized marker the SOMOS community map uses for public art.
const String latineArtIconAsset =
    'assets/map_icons/public-art/PublicArtAndArtists.png';

/// The label used for the Latine art locations in the category filter, the
/// Browse locations list, and the location card. It mirrors the layer's most
/// common `Category` value.
const String latineArtCategory = 'Public Art and Artists';

/// Bundled photos drawn inside the location card of the art locations.
///
/// They are bundled instead of read from the layer because the `Image` field of
/// `SacStateLatineArt` points at ArcGIS item data pages rather than at images.
/// Photos are downscaled to a 1440 px longest side before being committed, for
/// example with `ffmpeg -i photo.png -vf "scale=1080:-2:flags=lanczos"
/// photo.png`, so the app bundle and the image cache stay small.
const String latineArtImageAssetDirectory = 'assets/somos_campus_map_art/';

/// The photo for each published art location, keyed by the location name
/// lowercased and trimmed. Locations without a bundled photo (for example
/// `Serna Plaza` and `Dolores Huerta Boardroom`) simply are not listed.
const Map<String, String> latineArtImageAssets = <String, String>{
  'ufw fountain': '${latineArtImageAssetDirectory}UFW_Fountain.jpg',
  'dolores huerta tree': '${latineArtImageAssetDirectory}DoloresHuertaTree.jpg',
  'chicano park-rcaf': '${latineArtImageAssetDirectory}ChicanoPark.png',
  'chicano oral histories':
      '${latineArtImageAssetDirectory}ChicanoOralHistoryProject.PNG',
};

/// Returns the bundled photo for the art location called [name], or null when
/// the location has no bundled photo.
String? latineArtImageAsset(dynamic name) {
  final key = name?.toString().trim().toLowerCase() ?? '';
  if (key.isEmpty) return null;
  return latineArtImageAssets[key];
}

/// Converts a `SacStateLatineArt` feature's attributes into the uppercase keys
/// read by `LocationInfoData` and the SOMOS campus map's location card.
///
/// Values the service fills in as "N/A" or "NULL" are dropped, and the category
/// falls back to [latineArtCategory] because one published feature leaves it
/// blank. Pass the feature's projected [latitude]/[longitude] so the card can
/// offer "Open in Maps".
Map<String, dynamic> latineArtLocationAttributes(
  Map<String, dynamic> attributes, {
  double? latitude,
  double? longitude,
}) {
  final category = cleanLocationAttribute(attributes['Category']);
  final name = cleanLocationAttribute(attributes['Name']);

  return <String, dynamic>{
    'NAME': name,
    'ADDRESS': cleanLocationAttribute(attributes['Address']),
    'CATEGORY': category.isEmpty ? latineArtCategory : category,
    'TYPE': cleanLocationAttribute(attributes['Type']),
    'DESCRIPTION': cleanLocationAttribute(attributes['Comments']),
    'WEBSITE': cleanLocationAttribute(attributes['Website']),
    'PHONE': cleanLocationAttribute(attributes['PhoneNumber']),
    'EMAIL': cleanLocationAttribute(attributes['Email']),
    'IMAGE_ASSET': latineArtImageAsset(name),
    'LATITUDE': latitude,
    'LONGITUDE': longitude,
  };
}

/// Projects [geometry] to WGS84 so it can be drawn in a graphics overlay and
/// used to recenter the map. Returns null for non-point geometry.
ArcGISPoint? latineArtWgs84Point(Geometry? geometry) {
  if (geometry is! ArcGISPoint) return null;

  if (geometry.spatialReference?.wkid == 4326) return geometry;

  return GeometryEngine.project(
        geometry,
        outputSpatialReference: SpatialReference.wgs84,
      )
      as ArcGISPoint?;
}

/// Returns the cached Latine art locations matching [query] and the selected
/// [categories], using the same rules as `filterSomosCampusResources`: a blank
/// query keeps every location, and a category filter that does not include
/// [latineArtCategory] hides them all.
List<MapLocation> filterLatineArtLocations(
  List<MapLocation> locations, {
  String query = '',
  Set<String> categories = const <String>{},
}) {
  if (categories.isNotEmpty && !categories.contains(latineArtCategory)) {
    return const <MapLocation>[];
  }

  final normalizedQuery = query.trim();
  if (normalizedQuery.isEmpty) {
    return List<MapLocation>.unmodifiable(locations);
  }

  return locations
      .where((location) => mapLocationMatches(location, normalizedQuery))
      .toList(growable: false);
}

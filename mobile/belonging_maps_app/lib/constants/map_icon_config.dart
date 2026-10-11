/// Community map icon configuration.
///
/// Mirrors the symbology described in the provided `Guide_To_Usage.json`.
/// Each community map has one configuration per feature layer; the renderer
/// uses the layer's `Type` attribute to pick an icon, falling back to a
/// category default for anything unmapped (the guide's "Other"/"ALL" case).
///
/// The icons live in `assets/map_icons/<category>/`. The original `.svg`
/// sources are rasterized to `.png` (see `tool/svg_to_png.mjs`) because ArcGIS
/// picture-marker symbols can only load raster images (BMP/GIF/ICO/JPEG/PNG).
library;

/// Icon setup for a single community-map feature layer.
class LayerIconConfig {
  const LayerIconConfig({required this.byType, required this.fallback});

  /// Maps a feature's `Type` value to an icon, expressed as a path relative to
  /// `assets/map_icons` using the original `.svg` filename. The renderer
  /// converts these to the rasterized `.png` asset paths via
  /// [mapIconAssetPath].
  final Map<String, String> byType;

  /// Icon used for `Type` values with no explicit entry in [byType].
  final String fallback;

  /// Every distinct icon referenced by this configuration, including the
  /// fallback, as relative `.svg` paths.
  Set<String> get referencedIcons => {...byType.values, fallback};
}

/// Converts a relative `.svg` icon path from the guide into the bundled
/// `.png` asset path (e.g. `food/HF11px.svg` -> `assets/map_icons/food/HF11px.png`).
String mapIconAssetPath(String relativeSvgPath) =>
    'assets/map_icons/${relativeSvgPath.replaceAll('.svg', '.png')}';

/// Resolves the bundled asset path for the icon a feature whose `Type` value
/// is [typeValue] uses within [config], falling back to the config's default
/// icon when the value is unmapped, blank, or null.
String iconAssetPathForType(LayerIconConfig config, dynamic typeValue) {
  final key = typeValue?.toString().trim();
  final relative =
      (key != null && key.isNotEmpty && config.byType.containsKey(key))
          ? config.byType[key]!
          : config.fallback;
  return mapIconAssetPath(relative);
}

/// Ummah community map icons, keyed by layer id.
const Map<String, LayerIconConfig> ummahLayerIcons = {
  'businessServices': LayerIconConfig(
    fallback: 'business/BS11px.svg',
    byType: {
      // Expanded types (the guide's "ALL" is only used as a fallback here).
      'Grocery': 'business/Grocery11px.svg',
      'Supermarket': 'business/Grocery11px.svg',
      'Automotive': 'business/Automotive11px.svg',
      'Clothing': 'business/Clothing11px.svg',
      'Furniture': 'business/Furniture11px.svg',
      'Event & Catering': 'business/Events11px.svg',
      'Real Estate': 'business/RealEstateAndMortgage11px.svg',
      'Salon (Women Only)': 'business/HairDryer11px.svg',
      'Consultation': 'business/Professional11px.svg',
      'Financial': 'business/Professional11px.svg',
      'Jeweler': 'business/Jewelers11px.svg',
      'Jewelry': 'business/Jewelers11px.svg',
      'Technology': 'business/PhoneService11px.svg',
      'Cell Service': 'business/PhoneService11px.svg',
      // Remaining "Other" types (Specialty, Fabric, Marketing, Media,
      // Miscellaneous) intentionally use the BS11px.svg fallback.
    },
  ),
  'communityServices': LayerIconConfig(
    fallback: 'community-service/SS11px.svg',
    byType: {
      'Medical/Mental Health': 'community-service/Medical11px.svg',
      'Legal': 'community-service/Legal11px.svg',
      'Dental': 'community-service/Dental11px.svg',
      'Government': 'community-service/Government11px.svg',
      'Disability Services': 'community-service/Disability11px.svg',
      // The guide notes "Disibility Services" is a typo of "Disability
      // Services"; both spellings map to the disability icon.
      'Disibility Services': 'community-service/Disability11px.svg',
      // Remaining "Other" types intentionally use the SS11px.svg fallback.
    },
  ),
  'halalFoods': LayerIconConfig(
    fallback: 'food/HF11px.svg',
    byType: {
      'Restaurant': 'food/HF11px.svg',
      'Café': 'food/Cafes11px.svg',
      'Food Truck': 'food/HF11px.svg',
      'Deli': 'food/Deli11px.svg',
      // The guide allows Bakery to use the dedicated bakery icon.
      'Bakery': 'food/Bakery11px.svg',
      // Remaining "Other" types (Catering, Food Stand) use the HF11px.svg
      // fallback.
    },
  ),
  'religiousCultural': LayerIconConfig(
    // The whole layer is intentionally represented by one symbol.
    fallback: 'religious/MIC11px.svg',
    byType: {},
  ),
  'education': LayerIconConfig(
    fallback: 'edcuation/ED11px.svg',
    byType: {
      'Library': 'edcuation/ED11px.svg',
      'Post-Secondary': 'edcuation/PostSecondary.svg',
      'Post Secondary Education': 'edcuation/PostSecondary.svg',
      'Islamic Education': 'edcuation/IslamicEducation11px.svg',
      // Misspelled variant that currently exists in the source data.
      'Islamic Eduation': 'edcuation/IslamicEducation11px.svg',
      'Preschool & Childcare': 'edcuation/PreKindergarten.svg',
      // Remaining "Other" types (Education Administration, K-12 Education,
      // Language School, Skillbuilding Workshop) use the ED11px.svg fallback.
    },
  ),
};

/// SOMOS community map icons, keyed by layer id.
const Map<String, LayerIconConfig> somosLayerIcons = {
  'businesses': LayerIconConfig(
    fallback: 'business/BS11px.svg',
    byType: {
      'Supermarket': 'business/Grocery11px.svg',
      'Market': 'business/Grocery11px.svg',
      'Salon': 'business/HairDryer11px.svg',
      'Real Estate & Mortgage': 'business/RealEstateAndMortgage11px.svg',
      'Clothing': 'business/Clothing11px.svg',
      'Consultation': 'business/Professional11px.svg',
      'Insurance': 'business/Professional11px.svg',
      'Automotive': 'business/Automotive11px.svg',
      'Technology': 'business/PhoneService11px.svg',
      'Event & Entertainment': 'business/Events11px.svg',
      'Jewelry': 'business/Jewelers11px.svg',
      // Remaining "Other" types (Specialty, Construction, Marketing,
      // Architectural & Design, Cleaning, Arborist, Auctions, Drones,
      // Flea Market, Gym) use the BS11px.svg fallback.
    },
  ),
  'religion': LayerIconConfig(
    fallback: 'religious/GeneralReligion11px.svg',
    byType: {
      'Church': 'religious/Churches11px.svg',
      'Mosque': 'religious/MIC11px.svg',
      'Synagogue': 'religious/Synagogues11px.svg',
    },
  ),
  'food': LayerIconConfig(
    fallback: 'food/HF11px.svg',
    byType: {
      'Restaurant': 'food/HF11px.svg',
      'Taqueria': 'food/Tacos11px.svg',
      'Bakery': 'food/Bakery11px.svg',
      'Café': 'food/Cafes11px.svg',
      // The guide notes "Café" is duplicated on AGOL due to a unicode bug that
      // rendered it as "CafŽ"; map that variant to the same icon.
      'CafŽ': 'food/Cafes11px.svg',
      // The guide allows these "Other" types to use their dedicated icons.
      'Taco Truck': 'food/Tacos11px.svg',
      'Deli': 'food/Deli11px.svg',
      // Remaining "Other" types (Catering, Ice Cream Shop, Bar/Winery,
      // Market, Food Truck) use the HF11px.svg fallback.
    },
  ),
  'publicArts': LayerIconConfig(
    fallback: 'public-art/PublicArtAndArtists.svg',
    byType: {
      // The live data uses the singular "Mural"; "Murals" is kept for safety.
      'Mural': 'public-art/Murals11px.svg',
      'Murals': 'public-art/Murals11px.svg',
      'Sculpture': 'public-art/Sculptures.svg',
      'Museums and Galleries': 'public-art/Museums.svg',
      'Event & Entertainment': 'public-art/Events-Art11px.svg',
      // Remaining "Other" types (Architectural & Design, Fountain, Memorial,
      // Photography, Printing, Public Square, Tree) use the fallback.
    },
  ),
  'communityServices': LayerIconConfig(
    fallback: 'community-service/SS11px.svg',
    byType: {
      'Medical/Mental Health': 'community-service/Medical11px.svg',
      'Legal': 'community-service/Legal11px.svg',
      'Government': 'community-service/Government11px.svg',
      'Accounting': 'community-service/Accounting11px.svg',
      'Dental': 'community-service/Dental11px.svg',
      'Disability Services': 'community-service/Disability11px.svg',
      'Disibility Services': 'community-service/Disability11px.svg',
      // Remaining "Other" types intentionally use the SS11px.svg fallback.
    },
  ),
  'education': LayerIconConfig(
    fallback: 'edcuation/ED11px.svg',
    byType: {
      'Library': 'edcuation/ED11px.svg',
      'Post-Secondary': 'edcuation/PostSecondary.svg',
      // The live data uses "Preschool and Childcare" (no space before "care").
      'Preschool and Childcare': 'edcuation/PreKindergarten.svg',
      'Preschool and Child Care': 'edcuation/PreKindergarten.svg',
      'Extra-Curricular': 'edcuation/ExtraCurricular11px.svg',
      'Museum': 'edcuation/Museums-edu.svg',
      // The guide allows "Language & Cultural" to use its dedicated icon.
      'Language & Cultural': 'edcuation/Language-Cultural11px.svg',
      // Remaining "Other" types (Education Administration, K-12 Education,
      // Radio, Skillbuilding) use the ED11px.svg fallback.
    },
  ),
};

/// Ubuntu community map icons, keyed by layer id.
const Map<String, LayerIconConfig> ubuntuLayerIcons = {
  'businesses': LayerIconConfig(
    // Ubuntu merges the food and business layers; the fallback is the generic
    // business icon, and unmapped food types fall through to it.
    fallback: 'business/BS11px.svg',
    byType: {
      'Restaurant': 'business/BSI-Special-Food-Icons/HF11px-red.svg',
      'Other Food': 'business/BSI-Special-Food-Icons/HF11px-red.svg',
      'Café': 'business/BSI-Special-Food-Icons/Cafes11px-red.svg',
      'Bakery': 'business/BSI-Special-Food-Icons/Bakery11px-red.svg',
      'Salon': 'business/HairDryer11px.svg',
      'Clothing': 'business/Clothing11px.svg',
      'Automotive': 'business/Automotive11px.svg',
      'Event Space': 'business/Events11px.svg',
      // Remaining "Other" types (Specialty, Bookstore, Janitorial Services,
      // Excercise, Media, Non-profit, Performing Arts Center, Publisher,
      // Shopping) use the BS11px.svg fallback.
    },
  ),
  'communityServices': LayerIconConfig(
    fallback: 'community-service/SS11px.svg',
    byType: {
      'Medical/Mental Health': 'community-service/Medical11px.svg',
      'Legal': 'community-service/Legal11px.svg',
      'Government': 'community-service/Government11px.svg',
      'Dental': 'community-service/Dental11px.svg',
      'Accounting': 'community-service/Accounting11px.svg',
      'Disability Services': 'community-service/Disability11px.svg',
      'Disibility Services': 'community-service/Disability11px.svg',
      // Remaining "Other" types intentionally use the SS11px.svg fallback.
    },
  ),
  'religious': LayerIconConfig(
    fallback: 'religious/GeneralReligion11px.svg',
    byType: {
      'Church': 'religious/Churches11px.svg',
      'Mosque': 'religious/MIC11px.svg',
      'Synagogue': 'religious/Synagogues11px.svg',
    },
  ),
  'education': LayerIconConfig(
    fallback: 'edcuation/ED11px.svg',
    byType: {
      'Library': 'edcuation/ED11px.svg',
      'Post-Secondary': 'edcuation/PostSecondary.svg',
      // The live data uses the hyphenated "Extra-Curricular".
      'Extra-Curricular': 'edcuation/ExtraCurricular11px.svg',
      'Extra Curricular': 'edcuation/ExtraCurricular11px.svg',
      'Child Care': 'edcuation/PreKindergarten.svg',
      // Remaining "Other" types (Leadership, K-12 Education, Advocacy,
      // Education Administration, PreK-12 Academic Support, Schools,
      // Skill Building) use the ED11px.svg fallback.
    },
  ),
};

/// ArcGIS feature-layer endpoints drawn by the Somos, Ummah, and Ubuntu
/// community maps.
///
/// These are public service URLs, not credentials, so they live in source
/// instead of the gitignored `.env`. The screens read them through these
/// constants rather than `flutter_dotenv`, so a missing value can no longer
/// silently build an empty `Uri`.
library;

// Somos community map layers.
const String somosBusinessesLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'SOMOS_Businesses_Admin/FeatureServer/0';

const String somosReligionLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'SOMOS_Religion_Admin/FeatureServer/0';

const String somosFoodLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'SOMOS_Food_Admin/FeatureServer/0';

const String somosPublicArtsLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'SOMOS_PublicArtArtists_Admin/FeatureServer/0';

const String somosCommunityServicesLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'SOMOS_CommunityServices_Admin/FeatureServer/0';

const String somosEducationLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'SOMOS_Education_Admin/FeatureServer/0';

// Ummah community map layers.
const String ummahBusinessServicesLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'Ummah_BusinessServices_Admin/FeatureServer/30';

const String ummahCommunityServicesLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'Ummah_CommunityServices_Admin/FeatureServer/25';

const String ummahHalalFoodsLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'Ummah_HalalFoods_Admin/FeatureServer/27';

const String ummahReligiousCulturalLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'Ummah_ReligiousCultural_Admin/FeatureServer/26';

const String ummahEducationLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'Ummah_Education_Admin/FeatureServer/24';

// Ubuntu community map layers.
const String ubuntuBusinessesLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'Ubuntu_Businesses_Admin/FeatureServer/0';

const String ubuntuCommunityServicesLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'Ubuntu_CommunityServices_Admin/FeatureServer/0';

const String ubuntuReligiousLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'Ubuntu_Religious_Admin/FeatureServer/0';

const String ubuntuEducationLayerUrl =
    'https://services8.arcgis.com/W20RHyf8i4NnxSuw/arcgis/rest/services/'
    'Ubuntu_Education_Admin/FeatureServer/0';

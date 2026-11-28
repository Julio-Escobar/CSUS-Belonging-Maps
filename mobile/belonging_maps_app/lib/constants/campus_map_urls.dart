/// ArcGIS endpoints shared by the Sacramento State campus maps.
///
/// The campus vector basemap and the label-only "Light Gray Reference" style are
/// drawn by the Somos, Ummah, and Ubuntu campus maps as well as the lactation
/// room and gender neutral bathroom maps. They are declared once here so those
/// five screens cannot drift apart.
library;

/// Sacramento State campus vector basemap published by the MLRC
/// (`CampusBasemapv3`). It is drawn over the OpenStreetMap streets basemap style
/// so campus buildings and walking paths stay legible at close zoom levels while
/// the surrounding city context stays visible.
const String campusBasemapUrl =
    'https://vectortileservices5.arcgis.com/nXNRC1vdZsFxBgaG/arcgis/rest/'
    'services/CampusBasemapv3/VectorTileServer';

/// Label-only "Light Gray Reference" vector tile style (ArcGIS item
/// a8416e7b45034be7b748071e10dde506, "LightGreyReferenceEdited"). The
/// `CampusBasemapv3` style has no label layers of its own, so this is what
/// supplies the building names. It is drawn above the campus basemap tiles but
/// below each map's own markers so the names stay readable over the building
/// footprints.
const String campusLabelsStyleUrl =
    'https://www.arcgis.com/sharing/rest/content/items/'
    'a8416e7b45034be7b748071e10dde506/resources/styles/root.json';

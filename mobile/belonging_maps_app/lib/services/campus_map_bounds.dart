import 'package:arcgis_maps/arcgis_maps.dart';

/// The Sacramento State campus center that every campus map opens on.
const double campusMapLatitude = 38.56091;
const double campusMapLongitude = -121.42405;

// A single campus-wide box shared by every campus map, covering all of the
// campus markers with a roughly 40 m margin. It is tight enough that the user
// cannot pan far off campus, while still showing the whole campus and keeping
// every marker inside the bounds - including Folsom Hall on the south-east edge
// (the Ummah Resource Map's second prayer room) and the north residence halls.
const double campusMapExtentXMin = -121.4289;
const double campusMapExtentYMin = 38.5511;
const double campusMapExtentXMax = -121.4138;
const double campusMapExtentYMax = 38.5677;

/// The maximum extent that every campus map applies to
/// [ArcGISMap.maxExtent], which limits how far the user can pan and zoom out.
Envelope campusMapMaxExtent() => Envelope.fromXY(
  xMin: campusMapExtentXMin,
  yMin: campusMapExtentYMin,
  xMax: campusMapExtentXMax,
  yMax: campusMapExtentYMax,
  spatialReference: SpatialReference.wgs84,
);


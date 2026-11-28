import 'package:arcgis_maps/arcgis_maps.dart';

// A single capital-region box shared by the Somos, Ummah, and Ubuntu community
// maps. It covers all but 13 of the 1,453 listings in the live feature services
// (Visalia, San Francisco, Orange, one Southern California religious place, and
// one Illinois address in Ubuntu Community Services). Those listings remain
// reachable through Browse and search, but the camera stops at the edge of this
// box instead of panning across the state or the world.
//
// The box is deliberately region-sized rather than campus-sized: the nearby-city
// listings the communities use (Woodland, Davis, Folsom, Auburn, El Dorado
// Hills, and Granite Bay) all sit inside it. Shrinking it to campus will fail
// test/community_map_bounds_test.dart until those listings move.
const double communityMapExtentXMin = -122.6;
const double communityMapExtentYMin = 37.9;
const double communityMapExtentXMax = -119.7;
const double communityMapExtentYMax = 39.3;

/// The maximum extent that every community map applies to
/// [ArcGISMap.maxExtent].
///
/// The SDK otherwise derives the max extent from the basemap's full (world)
/// extent, which is why these maps could previously be panned and zoomed
/// anywhere. Setting it explicitly limits panning to the region and, as a side
/// effect, caps which basemap tiles the screen can request.
Envelope communityMapMaxExtent() => Envelope.fromXY(
  xMin: communityMapExtentXMin,
  yMin: communityMapExtentYMin,
  xMax: communityMapExtentXMax,
  yMax: communityMapExtentYMax,
  spatialReference: SpatialReference.wgs84,
);

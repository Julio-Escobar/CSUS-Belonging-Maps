import 'dart:async';

import 'package:arcgis_maps/arcgis_maps.dart';

/// Centers the map camera on [geometry] without changing the current zoom
/// level, the same camera move a tapped Latine art pin makes on the SOMOS map.
///
/// Non-point geometry is ignored, so a tap on anything that is not a location
/// marker leaves the camera where it is.
void centerMapOnLocation(
  ArcGISMapViewController mapController,
  Geometry? geometry,
) {
  if (geometry is! ArcGISPoint) return;
  unawaited(mapController.setViewpointCenter(geometry));
}

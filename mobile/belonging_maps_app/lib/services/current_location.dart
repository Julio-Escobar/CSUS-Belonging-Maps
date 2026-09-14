import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:geolocator/geolocator.dart';

Future<void> showCurrentLocation(
  ArcGISMapViewController mapController,
  GraphicsOverlay userOverlay,
) async {
  final permission = await Geolocator.requestPermission();

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return;
  }

  final position = await Geolocator.getCurrentPosition();

  final point = ArcGISPoint(
    x: position.longitude,
    y: position.latitude,
    spatialReference: SpatialReference.wgs84,
  );

  final outerCircle = SimpleMarkerSymbol(
    style: SimpleMarkerSymbolStyle.circle,
    color: Colors.blue.withOpacity(0.2),
    size: 28,
  );

  final innerCircle = SimpleMarkerSymbol(
    style: SimpleMarkerSymbolStyle.circle,
    color: Colors.blue,
    size: 14,
  )
    ..outline = SimpleLineSymbol(
      style: SimpleLineSymbolStyle.solid,
      color: Colors.white,
      width: 3,
    );

  final outerGraphic = Graphic(geometry: point, symbol: outerCircle);
  final innerGraphic = Graphic(geometry: point, symbol: innerCircle);

  userOverlay.graphics.clear();
  userOverlay.graphics.addAll([outerGraphic, innerGraphic]);

  await mapController.setViewpointCenter(point, scale: 5000);
}

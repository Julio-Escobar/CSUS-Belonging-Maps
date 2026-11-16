import 'dart:math' as math;
import 'dart:ui';

import 'package:arcgis_maps/arcgis_maps.dart';

/// Extra space, in device-independent pixels (DIP), added around a map icon so
/// taps that land just outside its artwork still select it.
const double mapTapSlop = 4;

/// The smallest tap radius used for a map icon, in DIP.
///
/// The ArcGIS Maps SDK for Flutter recommends a 22 DIP tolerance to cover an
/// average finger tap, so a small icon never gets a smaller target than that.
const double minimumMapTapTolerance = 22;

/// The largest tolerance the ArcGIS identify methods accept, in DIP.
const double maximumMapTapTolerance = 100;

/// The radius, in DIP, of a circular tap target that covers an icon drawn
/// [iconSize] DIP wide (plus a little slop on every side).
///
/// The ArcGIS identify methods treat their tolerance as the radius of a circle
/// centred on the feature's point, not as the icon's bounds, so this has to be
/// applied explicitly for taps to line up with what the user sees.
double mapIconTapTolerance(double iconSize) {
  final radius = iconSize.isFinite && iconSize > 0 ? iconSize / 2 : 0.0;
  final tolerance = math.max(minimumMapTapTolerance, radius + mapTapSlop);
  return math.min(maximumMapTapTolerance, tolerance);
}

/// The largest on-screen dimension of [symbol]'s artwork, in DIP.
///
/// Returns 0 when the size cannot be determined. Composite symbols report the
/// largest size of their members.
double mapSymbolTapSize(ArcGISSymbol? symbol) {
  if (symbol == null) return 0;

  if (symbol is PictureMarkerSymbol) {
    return math.max(_validSize(symbol.width), _validSize(symbol.height));
  }
  if (symbol is SimpleMarkerSymbol) return _validSize(symbol.size);
  if (symbol is TextSymbol) return _validSize(symbol.size);
  if (symbol is CompositeSymbol) {
    return symbol.symbols.map(mapSymbolTapSize).fold<double>(0, math.max);
  }
  return 0;
}

/// The radius, in DIP, of a circular tap target that covers [symbol]'s artwork.
double mapSymbolTapTolerance(ArcGISSymbol? symbol) =>
    mapIconTapTolerance(mapSymbolTapSize(symbol));

/// The largest tap tolerance needed to identify any graphic in [overlays].
///
/// A single tolerance is passed to `identifyGraphicsOverlays`; each returned
/// graphic is then filtered by its own [mapSymbolTapTolerance], so a large
/// centre logo does not make every small marker around it easier to tap.
double mapOverlaysTapSearchTolerance(Iterable<GraphicsOverlay> overlays) {
  var tolerance = minimumMapTapTolerance;
  for (final overlay in overlays) {
    for (final graphic in overlay.graphics) {
      tolerance = math.max(tolerance, mapSymbolTapTolerance(graphic.symbol));
    }
  }
  return math.min(maximumMapTapTolerance, tolerance);
}

/// Converts [geometry]'s point to screen coordinates, projecting it to the map
/// view's spatial reference first when necessary.
///
/// Returns null for non-point geometry, for points that cannot be projected,
/// and when the map view cannot convert the location (for example before its
/// first frame has been drawn).
Offset? mapGeometryScreenPoint(
  ArcGISMapViewController mapController,
  Geometry? geometry,
) {
  if (geometry is! ArcGISPoint) return null;

  try {
    var point = geometry;
    final mapReference = mapController.spatialReference;
    final pointReference = point.spatialReference;
    if (mapReference != null &&
        (pointReference == null || pointReference.wkid != mapReference.wkid)) {
      final projected = GeometryEngine.project(
        point,
        outputSpatialReference: mapReference,
      );
      if (projected is! ArcGISPoint) return null;
      point = projected;
    }

    final screen = mapController.locationToScreen(mapPoint: point);
    if (!screen.dx.isFinite || !screen.dy.isFinite) return null;
    return screen;
  } catch (_) {
    return null;
  }
}

/// A map icon that the user may have tapped, together with the screen position
/// of its centre and the radius of its own tap target.
class MapTapCandidate<T> {
  const MapTapCandidate({
    required this.value,
    required this.screenPoint,
    required this.tolerance,
  });

  /// The action (or other value) associated with the icon.
  final T value;

  /// Where the icon's centre is drawn, in screen coordinates.
  final Offset screenPoint;

  /// The radius, in DIP, of the icon's own tap target.
  final double tolerance;
}

/// Returns the value of the candidate nearest to [tapPoint] whose own tap
/// radius contains [tapPoint], or null when the tap did not land on an icon.
///
/// Candidates must be ordered top-most first: when two icons are equally close
/// (for example because they share a location), the one drawn on top wins.
T? nearestMapTapCandidate<T>(
  Iterable<MapTapCandidate<T>> candidates,
  Offset tapPoint,
) {
  T? nearest;
  var nearestDistance = double.infinity;

  for (final candidate in candidates) {
    final distance = (candidate.screenPoint - tapPoint).distance;
    if (!distance.isFinite || distance > candidate.tolerance) continue;
    if (distance < nearestDistance) {
      nearestDistance = distance;
      nearest = candidate.value;
    }
  }

  return nearest;
}

double _validSize(double size) => size.isFinite && size > 0 ? size : 0;

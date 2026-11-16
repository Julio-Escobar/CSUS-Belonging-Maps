import 'package:flutter/widgets.dart';

/// The icon shown at the top-left of a campus-map location card.
typedef CampusMapCardLogo = ({
  String? asset,
  String? label,
  BoxFit? fit,
  Color? backgroundColor,
});

/// Resolves the icon shown at the top-left of a campus-map location card.
///
/// The icon is chosen in this order:
///
/// 1. The campus center's bundled marker icon, fitted inside the card's rounded
///    logo box. Centers without a logo of their own resolve to the shared
///    placeholder location icon, which is the same icon drawn for their map
///    marker.
/// 2. An explicit [overrideAsset], used by the SOMOS Latine art locations.
/// 3. The selected location's [iconAsset] (prayer rooms, food options, and
///    other markers that bundle an icon).
/// 4. A numbered badge for [resourceNumber], matching the numbered map marker.
/// 5. The map's [mapLogoAsset] when no location-specific icon exists.
///
/// [centerBackgroundColor] and [markerColor] keep light icons visible against
/// the solid backgrounds drawn for them on the map.
CampusMapCardLogo campusMapCardLogo({
  required String? centerIconAsset,
  required String mapLogoAsset,
  Color? centerBackgroundColor,
  String? iconAsset,
  String? resourceNumber,
  Color? markerColor,
  String? overrideAsset,
}) {
  final centerAsset = centerIconAsset?.trim() ?? '';
  if (centerAsset.isNotEmpty) {
    return (
      asset: centerAsset,
      label: null,
      fit: BoxFit.contain,
      backgroundColor: centerBackgroundColor,
    );
  }

  final override = overrideAsset?.trim() ?? '';
  final icon = override.isNotEmpty ? override : (iconAsset?.trim() ?? '');
  if (icon.isNotEmpty) {
    return (asset: icon, label: null, fit: null, backgroundColor: null);
  }

  final number = resourceNumber?.trim() ?? '';
  if (number.isNotEmpty) {
    return (
      asset: null,
      label: number,
      fit: null,
      backgroundColor: markerColor,
    );
  }

  return (asset: mapLogoAsset, label: null, fit: null, backgroundColor: null);
}

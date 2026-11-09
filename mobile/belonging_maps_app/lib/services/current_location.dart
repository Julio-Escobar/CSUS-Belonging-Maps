import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';
import 'package:geolocator/geolocator.dart';

/// Result of trying to use the person's location (P1-325).
enum LocationAccess {
  /// Permission is granted; we can read the position.
  granted,

  /// The person said no this time. Tapping the button again asks again.
  denied,

  /// The person said "don't ask again" (Android) or turned location off for
  /// the app in Settings (iOS). Only the Settings app can change it now.
  deniedForever,

  /// Location services are switched off for the whole device.
  serviceDisabled,
}

/// The pieces of geolocator that [resolveLocationAccess] needs. Tests pass
/// fakes so every permission state can be covered without a device.
class LocationPermissionApi {
  final Future<bool> Function() isServiceEnabled;
  final Future<LocationPermission> Function() checkPermission;
  final Future<LocationPermission> Function() requestPermission;

  const LocationPermissionApi({
    required this.isServiceEnabled,
    required this.checkPermission,
    required this.requestPermission,
  });

  static final geolocator = LocationPermissionApi(
    isServiceEnabled: Geolocator.isLocationServiceEnabled,
    checkPermission: Geolocator.checkPermission,
    requestPermission: Geolocator.requestPermission,
  );
}

/// Works out whether we may read the location, only showing the system
/// prompt when the person hasn't decided yet. On iOS the prompt text comes
/// from NSLocationWhenInUseUsageDescription in ios/Runner/Info.plist (P1-324).
Future<LocationAccess> resolveLocationAccess([
  LocationPermissionApi? api,
]) async {
  final permissions = api ?? LocationPermissionApi.geolocator;

  if (!await permissions.isServiceEnabled()) {
    return LocationAccess.serviceDisabled;
  }

  var permission = await permissions.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await permissions.requestPermission();
  }

  switch (permission) {
    case LocationPermission.always:
    case LocationPermission.whileInUse:
      return LocationAccess.granted;
    case LocationPermission.deniedForever:
      return LocationAccess.deniedForever;
    case LocationPermission.denied:
    case LocationPermission.unableToDetermine:
      return LocationAccess.denied;
  }
}

/// Message shown when we can't use the location, or null when access is fine.
String? locationAccessMessage(LocationAccess access) {
  switch (access) {
    case LocationAccess.granted:
      return null;
    case LocationAccess.denied:
      return 'Location permission was not given. Tap the location button to '
          'try again.';
    case LocationAccess.deniedForever:
      return 'Location is turned off for Belonging Maps. You can turn it on '
          'in Settings.';
    case LocationAccess.serviceDisabled:
      return 'Location services are off on this device. Turn them on to see '
          'where you are.';
  }
}

/// Shows a short message explaining why the map didn't move, with a button
/// to open Settings when that's the only way to fix it. The map itself stays
/// usable either way.
void showLocationAccessMessage(BuildContext context, LocationAccess access) {
  final message = locationAccessMessage(access);
  if (message == null) return;

  final SnackBarAction? action;
  if (access == LocationAccess.deniedForever) {
    action = SnackBarAction(
      label: 'Settings',
      onPressed: () => Geolocator.openAppSettings(),
    );
  } else if (access == LocationAccess.serviceDisabled) {
    action = SnackBarAction(
      label: 'Settings',
      onPressed: () => Geolocator.openLocationSettings(),
    );
  } else {
    action = null;
  }

  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

Future<void> showCurrentLocation(
  ArcGISMapViewController mapController,
  GraphicsOverlay userOverlay, {
  BuildContext? context,
}) async {
  final access = await resolveLocationAccess();
  if (access != LocationAccess.granted) {
    if (context != null && context.mounted) {
      showLocationAccessMessage(context, access);
    }
    return;
  }

  final Position position;
  try {
    position = await Geolocator.getCurrentPosition();
  } catch (_) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text("Couldn't find your location. Try again in a moment."),
        ),
      );
    }
    return;
  }

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

  final innerCircle =
      SimpleMarkerSymbol(
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

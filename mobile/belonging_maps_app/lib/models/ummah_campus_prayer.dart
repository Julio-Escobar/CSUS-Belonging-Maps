/// A prayer room and wudu (ablution) station on the Sacramento State campus
/// shown on the Ummah campus map.
///
/// Prayer rooms are kept separate from the other Ummah markers: the dataset is
/// loaded from `assets/data/ummah_campus_prayer.json` and each entry is drawn
/// with a mosque icon. The story map's "Prayer Rooms and Wudu Stations"
/// section lists these locations.
const String ummahCampusPrayerIconDirectory = 'assets/map_icons/religious/';

class UmmahCampusPrayer {
  const UmmahCampusPrayer({
    required this.id,
    required this.name,
    required this.building,
    this.room = '',
    this.floor = '',
    required this.category,
    required this.description,
    this.website = '',
    this.icon = '',
    this.amenities = const <String>[],
    required this.latitude,
    required this.longitude,
  });

  /// The mosque icon drawn when an entry does not name its own icon. It reuses
  /// the rasterized community map mosque icon that is already registered in
  /// `pubspec.yaml`.
  static const String defaultIconAsset =
      '${ummahCampusPrayerIconDirectory}MIC11px.png';

  /// A stable identifier used to keep entries unique within the dataset.
  final String id;

  /// The name of the prayer room, such as "Folsom Hall Prayer Room".
  final String name;

  /// The building that houses the prayer room.
  final String building;

  /// The room number, when known. Empty when only the building is known.
  final String room;

  /// The floor the prayer room is on, such as "2nd floor". Empty when unknown.
  final String floor;

  /// The resource group used by the map's category filter.
  final String category;

  /// A description of the prayer room and its wudu stations.
  final String description;

  /// An official website for the space. Empty when there is none.
  final String website;

  /// The icon filename within [ummahCampusPrayerIconDirectory]. Empty when the
  /// entry uses [defaultIconAsset].
  final String icon;

  /// What the location offers, such as "Prayer space" and "Wudu stations".
  final List<String> amenities;

  final double latitude;
  final double longitude;

  /// A human-readable location, such as "Folsom Hall, 2nd floor".
  String get locationLabel {
    final parts = <String>[building];
    if (room.trim().isNotEmpty) parts.add('Room ${room.trim()}');
    if (floor.trim().isNotEmpty) parts.add(floor.trim());
    return parts.join(', ');
  }

  /// The bundled asset path for this prayer room's marker, falling back to the
  /// shared mosque icon when no icon is configured.
  String get iconAsset => icon.trim().isEmpty
      ? defaultIconAsset
      : '$ummahCampusPrayerIconDirectory${icon.trim()}';

  /// Converts the prayer room into the attribute keys understood by
  /// `LocationInfoData` and `LocationInfoCard`.
  Map<String, dynamic> toAttributes() {
    return <String, dynamic>{
      'ID': id,
      'NAME': name,
      'BUILDING': building,
      'ROOM': room,
      'FLOOR': floor,
      'ADDRESS': locationLabel,
      'CATEGORY': category,
      'DESCRIPTION': description,
      'WEBSITE': website,
      'AMENITIES': amenities.join('\n'),
      'ICON_ASSET': iconAsset,
      'LATITUDE': latitude,
      'LONGITUDE': longitude,
    };
  }

  /// Parses and validates a prayer room entry from the bundled dataset.
  ///
  /// Throws a [FormatException] when required data is missing or invalid so
  /// the map can log the failure instead of drawing a broken marker.
  factory UmmahCampusPrayer.fromJson(Map<String, dynamic> json) {
    final website = _optionalString(json, 'website');
    if (website.isNotEmpty) {
      final uri = Uri.tryParse(website);
      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw FormatException('Invalid prayer room website: $website');
      }
    }

    final latitude = _requiredDouble(json, 'latitude');
    if (latitude < -90 || latitude > 90) {
      throw FormatException('Invalid latitude: $latitude');
    }

    final longitude = _requiredDouble(json, 'longitude');
    if (longitude < -180 || longitude > 180) {
      throw FormatException('Invalid longitude: $longitude');
    }

    return UmmahCampusPrayer(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      building: _requiredString(json, 'building'),
      room: _optionalString(json, 'room'),
      floor: _optionalString(json, 'floor'),
      category: _requiredString(json, 'category'),
      description: _requiredString(json, 'description'),
      website: website,
      icon: _optionalString(json, 'icon'),
      amenities: _optionalStringList(json, 'amenities'),
      latitude: latitude,
      longitude: longitude,
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing or invalid "$key" value.');
    }
    return value.trim();
  }

  static String _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return '';
    if (value is! String) {
      throw FormatException('Expected a string for "$key".');
    }
    return value.trim();
  }

  static List<String> _optionalStringList(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) return const <String>[];
    if (value is! List) {
      throw FormatException('Expected a list for "$key".');
    }

    return List<String>.unmodifiable(
      value.map((entry) {
        if (entry is! String) {
          throw FormatException('Expected a string in "$key".');
        }
        return entry.trim();
      }).where((entry) => entry.isNotEmpty),
    );
  }

  static double _requiredDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    throw FormatException('Missing or invalid "$key" value.');
  }
}

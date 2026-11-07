/// A Latine food option on the Sacramento State campus shown on the SOMOS
/// campus map.
///
/// Food options are kept separate from the numbered [SomosCampusResource]
/// markers and the campus center logos: the dataset is loaded from
/// `assets/data/somos_campus_food.json` and each entry is drawn with a food
/// icon instead of a numbered circle. The story map's "Latine Food Options on
/// Campus" section lists these locations.
const String somosCampusFoodIconDirectory = 'assets/map_icons/food/';

class SomosCampusFood {
  const SomosCampusFood({
    required this.id,
    required this.name,
    required this.building,
    this.room = '',
    required this.category,
    required this.description,
    this.website = '',
    this.icon = '',
    required this.latitude,
    required this.longitude,
  });

  /// The food icon drawn when an entry does not name its own icon. It reuses
  /// the rasterized community map food icon that is already registered in
  /// `pubspec.yaml`.
  static const String defaultIconAsset =
      '${somosCampusFoodIconDirectory}HF11px.png';

  /// A stable identifier used to keep entries unique within the dataset.
  final String id;

  /// The name of the food option, such as "Midtown Taqueria".
  final String name;

  /// The building that houses the food option.
  final String building;

  /// The room number, when known. Empty when only the building is known.
  final String room;

  /// The resource group used by the map's category filter.
  final String category;

  /// A description of the food option and what it offers.
  final String description;

  /// The food option's official website. Empty when there is none.
  final String website;

  /// The icon filename within [somosCampusFoodIconDirectory]. Empty when the
  /// entry uses [defaultIconAsset].
  final String icon;

  final double latitude;
  final double longitude;

  /// A human-readable location, such as "University Union".
  String get locationLabel =>
      room.trim().isEmpty ? building : '$building, Room $room';

  /// The bundled asset path for this food option's marker, falling back to the
  /// shared food icon when no icon is configured.
  String get iconAsset => icon.trim().isEmpty
      ? defaultIconAsset
      : '$somosCampusFoodIconDirectory${icon.trim()}';

  /// Converts the food option into the attribute keys understood by
  /// `LocationInfoData` and `LocationInfoCard`.
  Map<String, dynamic> toAttributes() {
    return <String, dynamic>{
      'ID': id,
      'NAME': name,
      'BUILDING': building,
      'ROOM': room,
      'ADDRESS': locationLabel,
      'CATEGORY': category,
      'DESCRIPTION': description,
      'WEBSITE': website,
      'ICON_ASSET': iconAsset,
      'LATITUDE': latitude,
      'LONGITUDE': longitude,
    };
  }

  /// Parses and validates a food entry from the bundled dataset.
  ///
  /// Throws a [FormatException] when required data is missing or invalid so
  /// the map can log the failure instead of drawing a broken marker.
  factory SomosCampusFood.fromJson(Map<String, dynamic> json) {
    final website = _optionalString(json, 'website');
    if (website.isNotEmpty) {
      final uri = Uri.tryParse(website);
      if (uri == null ||
          !uri.hasScheme ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        throw FormatException('Invalid food option website: $website');
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

    return SomosCampusFood(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      building: _requiredString(json, 'building'),
      room: _optionalString(json, 'room'),
      category: _requiredString(json, 'category'),
      description: _requiredString(json, 'description'),
      website: website,
      icon: _optionalString(json, 'icon'),
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

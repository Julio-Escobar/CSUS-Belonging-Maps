/// A Sacramento State center, program, or office shown on the Ummah campus map.
///
/// Centers are kept separate from the numbered [UmmahCampusResource] markers:
/// the dataset is loaded from `assets/data/ummah_campus_centers.json` and each
/// entry is drawn with its own logo instead of a numbered circle. Entries
/// without an `icon` fall back to a shared placeholder marker until their logo
/// is bundled with the app.
///
/// The logos live in [ummahCampusCenterIconDirectory], which is registered in
/// the `assets:` section of `pubspec.yaml`. To add one, drop the file into that
/// folder and set the `icon` filename of the entry. Transparent logos also set
/// `background` to `white` or `darkGreen` so they stay visible on the basemap,
/// and wide wordmarks can raise `iconScale` to stay legible.
const String ummahCampusCenterIconDirectory =
    'assets/ummah_campus_map_assets/';

class UmmahCampusCenter {
  const UmmahCampusCenter({
    required this.id,
    required this.name,
    required this.building,
    this.room = '',
    required this.category,
    required this.description,
    required this.website,
    this.icon = '',
    this.background = '',
    this.iconScale = 1.0,
    this.backgroundPadding = 0.12,
    this.supportServices = const <String>[],
    required this.latitude,
    required this.longitude,
  });

  /// The bundled placeholder marker drawn for centers without their own icon.
  /// It reuses the rasterized generic community-service icon that is already
  /// registered in `pubspec.yaml`, so the map works before the center logos
  /// are dropped into [ummahCampusCenterIconDirectory].
  static const String placeholderIconAsset =
      'assets/map_icons/community-service/SS11px.png';

  /// A stable identifier used to keep entries unique within the dataset.
  final String id;

  /// The icon filename within [ummahCampusCenterIconDirectory]. Empty when the
  /// center has no dedicated icon yet.
  final String icon;

  /// A solid background drawn behind the icon so low-contrast logos stay
  /// visible. Supported tokens are `darkGreen` and `white`; empty means none.
  final String background;

  /// Multiplier applied to the icon's drawn size, so individual logos can be
  /// nudged larger or smaller (1.0 keeps the default size).
  final double iconScale;

  /// Padding around the logo inside its solid background, as a fraction of the
  /// marker size. Smaller values make the background hug the logo more tightly.
  final double backgroundPadding;

  /// The name of the center, program, or office.
  final String name;

  /// The building that houses the center.
  final String building;

  /// The room number, when known. Empty when only the building is known.
  final String room;

  /// The resource group used by the map's category filter.
  final String category;

  /// A description of the center and the services it offers.
  final String description;

  /// The center's official website (the story map's "Link card").
  final String website;

  /// The individual support services the center offers.
  final List<String> supportServices;

  final double latitude;
  final double longitude;

  /// A human-readable location, such as "AIRC, Room 1012".
  String get locationLabel =>
      room.trim().isEmpty ? building : '$building, Room $room';

  /// The bundled asset path for this center's marker, falling back to the
  /// shared placeholder when no icon is configured.
  String get iconAsset => icon.trim().isEmpty
      ? placeholderIconAsset
      : '$ummahCampusCenterIconDirectory${icon.trim()}';

  /// Converts the center into the attribute keys understood by
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
      'SUPPORT_SERVICES': supportServices.join('\n'),
      'ICON_ASSET': iconAsset,
      'BACKGROUND': background,
      'ICON_SCALE': iconScale,
      'BACKGROUND_PADDING': backgroundPadding,
      'LATITUDE': latitude,
      'LONGITUDE': longitude,
    };
  }

  /// Parses and validates a center entry from the bundled dataset.
  ///
  /// Throws a [FormatException] when required data is missing or invalid so
  /// the map can log the failure instead of drawing a broken marker.
  factory UmmahCampusCenter.fromJson(Map<String, dynamic> json) {
    final website = _requiredString(json, 'website');
    final uri = Uri.tryParse(website);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw FormatException('Invalid center website: $website');
    }

    final latitude = _requiredDouble(json, 'latitude');
    if (latitude < -90 || latitude > 90) {
      throw FormatException('Invalid latitude: $latitude');
    }

    final longitude = _requiredDouble(json, 'longitude');
    if (longitude < -180 || longitude > 180) {
      throw FormatException('Invalid longitude: $longitude');
    }

    final iconScale = _optionalDouble(json, 'iconScale', 1.0);
    if (iconScale <= 0) {
      throw FormatException('Invalid iconScale: $iconScale');
    }

    final backgroundPadding = _optionalDouble(json, 'backgroundPadding', 0.12);
    if (backgroundPadding < 0) {
      throw FormatException('Invalid backgroundPadding: $backgroundPadding');
    }

    return UmmahCampusCenter(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      building: _requiredString(json, 'building'),
      room: _optionalString(json, 'room'),
      category: _requiredString(json, 'category'),
      description: _requiredString(json, 'description'),
      website: website,
      icon: _optionalString(json, 'icon'),
      background: _optionalString(json, 'background'),
      iconScale: iconScale,
      backgroundPadding: backgroundPadding,
      supportServices: _optionalStringList(json, 'supportServices'),
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

  static double _optionalDouble(
    Map<String, dynamic> json,
    String key,
    double fallback,
  ) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    throw FormatException('Expected a number for "$key".');
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

/// A Sacramento State campus resource shown on the SOMOS campus map.
///
/// Resource data is loaded from `assets/data/somos_campus_resources.json`.
/// The story map's "Other Campus Resources and their Locations" section lists
/// these services, and the coordinates mirror its numbered map markers.
class SomosCampusResource {
  const SomosCampusResource({
    required this.number,
    required this.name,
    required this.building,
    this.room = '',
    required this.category,
    required this.description,
    required this.website,
    this.phone = '',
    this.email = '',
    required this.latitude,
    required this.longitude,
  });

  /// The number displayed inside the resource's map marker.
  final int number;

  /// The name of the office, center, or program.
  final String name;

  /// The building that houses the resource.
  final String building;

  /// The room number, when known. Empty when only the building is known.
  final String room;

  /// The resource group used by the map's category filter.
  final String category;

  /// A description of the resource and the services it offers.
  final String description;

  /// The resource's official website.
  final String website;

  final String phone;
  final String email;

  final double latitude;
  final double longitude;

  /// A human-readable location, such as "Lassen Hall, Room 2201".
  String get locationLabel =>
      room.trim().isEmpty ? building : '$building, Room $room';

  /// Converts the resource into the attribute keys understood by
  /// `LocationInfoData` and `LocationInfoCard`.
  Map<String, dynamic> toAttributes() {
    return <String, dynamic>{
      'NUMBER': number,
      'NAME': name,
      'BUILDING': building,
      'ROOM': room,
      'ADDRESS': locationLabel,
      'CATEGORY': category,
      'DESCRIPTION': description,
      'WEBSITE': website,
      'PHONE': phone,
      'EMAIL': email,
      'LATITUDE': latitude,
      'LONGITUDE': longitude,
    };
  }

  /// Parses and validates a resource entry from the bundled dataset.
  ///
  /// Throws a [FormatException] when required data is missing or invalid so
  /// the map can show its error state instead of a partially broken map.
  factory SomosCampusResource.fromJson(Map<String, dynamic> json) {
    final number = _requiredInt(json, 'number');
    if (number <= 0) {
      throw const FormatException(
        'Resource numbers must be greater than zero.',
      );
    }

    final website = _requiredString(json, 'website');
    final uri = Uri.tryParse(website);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw FormatException('Invalid resource website: $website');
    }

    final latitude = _requiredDouble(json, 'latitude');
    if (latitude < -90 || latitude > 90) {
      throw FormatException('Invalid latitude: $latitude');
    }

    final longitude = _requiredDouble(json, 'longitude');
    if (longitude < -180 || longitude > 180) {
      throw FormatException('Invalid longitude: $longitude');
    }

    return SomosCampusResource(
      number: number,
      name: _requiredString(json, 'name'),
      building: _requiredString(json, 'building'),
      room: _optionalString(json, 'room'),
      category: _requiredString(json, 'category'),
      description: _requiredString(json, 'description'),
      website: website,
      phone: _optionalString(json, 'phone'),
      email: _optionalString(json, 'email'),
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

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num && value == value.roundToDouble()) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    throw FormatException('Missing or invalid "$key" value.');
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

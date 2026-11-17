import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/location_attributes.dart';
import '../services/accessibility_theme.dart';
import '../services/favorites_store.dart';
import 'favorite_toggle_button.dart';
import 'full_screen_image_viewer.dart';
import 'location_card_style.dart';

// Color constants
const Color mapInfoCardColor = Color.fromARGB(255, 47, 95, 62);
const Color mapInfoPrimaryTextColor = Colors.white;
const Color mapInfoSecondaryTextColor = Colors.white70;
const Color mapInfoDividerColor = Colors.white24;
const Color mapInfoFallbackImageColor = Colors.white12;

/// Resolves the location-card colors from the active accessibility palette.
///
/// The normal palette deliberately resolves to the original green-and-white
/// treatment, while color-safe and high-contrast palettes update the entire
/// card as one readable unit.
class _LocationCardPalette {
  const _LocationCardPalette({
    required this.background,
    required this.foreground,
    required this.secondaryForeground,
    required this.divider,
    required this.fallbackImage,
    required this.surface,
  });

  final Color background;
  final Color foreground;
  final Color secondaryForeground;
  final Color divider;
  final Color fallbackImage;
  final Color surface;

  factory _LocationCardPalette.of(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    return _LocationCardPalette(
      background: colors.primary,
      foreground: colors.onPrimary,
      secondaryForeground: colors.onPrimary.withValues(alpha: 0.7),
      divider: colors.onPrimary.withValues(alpha: 0.24),
      fallbackImage: colors.onPrimary.withValues(alpha: 0.12),
      surface: colors.cardBackground,
    );
  }
}

/// Identifies the photo drawn inside a location card, so widget tests can find
/// it without depending on the image provider.
const Key locationInfoImageKey = ValueKey<String>('location-info-image');

/// Identifies the box drawn around an organization logo, so widget tests can
/// verify the background color it uses.
const Key locationInfoLogoBoxKey = ValueKey<String>('location-info-logo-box');

/// Height of the photo in the compact location card.
const double _previewImageHeight = 150;

/// Gap between the compact card's content and its photo.
const double _previewImageGap = 12;

/// Height of the compact location card when it has no photo.
const double _previewCardHeight = 300;

class LocationInfoData {
  final String cardTitle;
  final String address;
  final String category;
  final String type;

  /// Who owns or runs a community business (for example "Muslim Owned").
  /// Empty when the location has no ownership information.
  final String owned;

  final String website;
  final String phone;
  final String email;
  final String description;

  /// The services a campus center or program offers, such as advising or
  /// scholarships. Empty when the location lists none.
  final List<String> supportServices;

  /// What a space offers, such as "Prayer space" or "Wudu stations". Empty
  /// when the location lists none.
  final List<String> amenities;

  final String? imageUrl;
  final String? imageAsset;
  final Map<String, String> socialLinks;
  final double? locationLat;
  final double? locationLng;
  final String? orgLogo;
  final String? id;

  /// How the organization logo is fitted inside the card's logo box. When null
  /// the logo keeps the original circular avatar and is cropped to fill it,
  /// which suits square crests. Wide wordmarks pass [BoxFit.contain] so the
  /// whole logo stays visible inside a rounded logo box.
  final BoxFit? orgLogoFit;

  /// The solid color drawn behind the organization logo in the card's logo
  /// box. Null keeps the default white box. Center logos that need a colored
  /// marker background on the map pass that color so light logos stay visible.
  final Color? orgLogoBackgroundColor;

  /// The number drawn for a numbered marker that has no icon asset.
  final String? orgLogoLabel;

  const LocationInfoData({
    required this.cardTitle,
    required this.address,
    required this.category,
    required this.type,
    this.owned = '',
    required this.website,
    required this.phone,
    required this.email,
    required this.description,
    this.supportServices = const <String>[],
    this.amenities = const <String>[],
    required this.imageUrl,
    this.imageAsset,
    required this.socialLinks,
    this.locationLat,
    this.locationLng,
    this.orgLogo,
    this.orgLogoFit,
    this.orgLogoBackgroundColor,
    this.orgLogoLabel,
    this.id,
  });

  String get stableFavoriteId {
    final explicitId = cleanField(id);
    if (explicitId.isNotEmpty) return explicitId;
    return '${category.trim().toLowerCase()}::${cardTitle.trim().toLowerCase()}';
  }

  FavoriteEntry get favoriteEntry => FavoriteEntry(
    type: FavoriteType.location,
    id: stableFavoriteId,
    title: cardTitle,
    data: toFavoriteJson(),
  );

  /// Whether the card has a leading icon, either an asset or a number label.
  bool get hasOrgLogo =>
      cleanField(orgLogo).isNotEmpty || cleanField(orgLogoLabel).isNotEmpty;

  Map<String, dynamic> toFavoriteJson() => {
    'id': id,
    'cardTitle': cardTitle,
    'address': address,
    'category': category,
    'type': type,
    'owned': owned,
    'website': website,
    'phone': phone,
    'email': email,
    'description': description,
    'supportServices': supportServices,
    'amenities': amenities,
    'imageUrl': imageUrl,
    'imageAsset': imageAsset,
    'socialLinks': socialLinks,
    'locationLat': locationLat,
    'locationLng': locationLng,
    'orgLogo': orgLogo,
    'orgLogoFit': orgLogoFit?.name,
    'orgLogoBackgroundColor': orgLogoBackgroundColor?.toARGB32(),
    'orgLogoLabel': orgLogoLabel,
  };

  factory LocationInfoData.fromFavoriteJson(Map<String, dynamic> json) {
    final title = json['cardTitle'];
    if (title is! String || title.isEmpty) {
      throw const FormatException('Saved location has no title.');
    }
    final socialLinks = json['socialLinks'];
    final fitName = json['orgLogoFit'];
    final logoBackground = json['orgLogoBackgroundColor'];
    return LocationInfoData(
      id: json['id'] as String?,
      cardTitle: title,
      address: json['address'] as String? ?? '',
      category: json['category'] as String? ?? '',
      type: json['type'] as String? ?? '',
      owned: json['owned'] as String? ?? '',
      website: json['website'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      description: json['description'] as String? ?? '',
      supportServices: _stringList(json['supportServices']),
      amenities: _stringList(json['amenities']),
      imageUrl: json['imageUrl'] as String?,
      imageAsset: json['imageAsset'] as String?,
      socialLinks: socialLinks is Map
          ? Map<String, String>.from(socialLinks)
          : const {},
      locationLat: (json['locationLat'] as num?)?.toDouble(),
      locationLng: (json['locationLng'] as num?)?.toDouble(),
      orgLogo: json['orgLogo'] as String?,
      orgLogoFit: BoxFit.values.where((fit) => fit.name == fitName).firstOrNull,
      orgLogoBackgroundColor: logoBackground is int
          ? Color(logoBackground)
          : null,
      orgLogoLabel: json['orgLogoLabel'] as String?,
    );
  }

  /// Whether the card has a photo to show, either bundled with the app or
  /// served from the network.
  bool get hasImage => hasBundledImage || cleanField(imageUrl).isNotEmpty;

  /// Whether the card has a photo bundled with the app. Only the Latine art
  /// locations bundle one, and only those photos are shown in the compact card.
  bool get hasBundledImage => cleanField(imageAsset).isNotEmpty;

  static String cleanField(dynamic value) {
    return cleanLocationAttribute(value);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  /// Parses a saved list of text values, dropping blanks and duplicates.
  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    final result = <String>[];
    for (final entry in value) {
      final text = cleanField(entry);
      if (text.isEmpty) continue;
      if (result.any((item) => item.toLowerCase() == text.toLowerCase())) {
        continue;
      }
      result.add(text);
    }
    return List<String>.unmodifiable(result);
  }

  /// The first non-empty value among [keys], matched without regard to case so
  /// the uppercase campus datasets and the mixed-case ArcGIS community layers
  /// both resolve.
  static dynamic _attributeValue(
    Map<String, dynamic>? attributes,
    List<String> keys,
  ) {
    if (attributes == null || attributes.isEmpty) return null;

    bool hasValue(dynamic value) {
      if (value is List) return value.isNotEmpty;
      if (value is Map) return value.isNotEmpty;
      return cleanField(value).isNotEmpty;
    }

    for (final key in keys) {
      final value = attributes[key];
      if (hasValue(value)) return value;
    }

    final lowerCaseKeys = <String, String>{
      for (final key in attributes.keys) key.toLowerCase(): key,
    };
    for (final key in keys) {
      final actualKey = lowerCaseKeys[key.toLowerCase()];
      if (actualKey == null) continue;
      final value = attributes[actualKey];
      if (hasValue(value)) return value;
    }
    return null;
  }

  static String _attributeText(
    Map<String, dynamic>? attributes,
    List<String> keys,
  ) => cleanField(_attributeValue(attributes, keys));

  /// Reads a bullet-separated list or newline-separated string of values.
  static List<String> _attributeList(
    Map<String, dynamic>? attributes,
    List<String> keys,
  ) {
    final raw = _attributeValue(attributes, keys);
    if (raw == null) return const <String>[];

    final Iterable<dynamic> entries = raw is List
        ? raw
        : raw.toString().split(RegExp(r'\r?\n'));
    final result = <String>[];
    for (final entry in entries) {
      final text = cleanField(
        entry,
      ).replaceFirst(RegExp(r'^[-\u2022*]\s*'), '').trim();
      if (text.isEmpty) continue;
      if (result.any((item) => item.toLowerCase() == text.toLowerCase())) {
        continue;
      }
      result.add(text);
    }
    return List<String>.unmodifiable(result);
  }

  /// Builds one address line from the separate street, city, state, and ZIP
  /// fields the community layers publish, without repeating parts already
  /// present in the street address.
  static String _composeAddress(
    Map<String, dynamic>? attributes, {
    required String primary,
  }) {
    final parts = <String>[];
    void addPart(String value) {
      final text = value.trim();
      if (text.isEmpty) return;
      final joined = parts.join(', ').toLowerCase();
      if (joined.contains(text.toLowerCase())) return;
      parts.add(text);
    }

    addPart(primary);
    addPart(
      _attributeText(attributes, const [
        'ADDRESS_LINE_2',
        'AddressLine2',
        'AddresLine2',
      ]),
    );

    final city = _attributeText(attributes, const ['CITY', 'City']);
    final state = _attributeText(attributes, const ['STATE', 'State']);
    final zip = _attributeText(attributes, const [
      'ZIP_CODE',
      'ZIP_Code',
      'ZIP',
    ]);
    addPart(
      [
        [city, state].where((value) => value.isNotEmpty).join(', '),
        zip,
      ].where((value) => value.isNotEmpty).join(' '),
    );

    return parts.join(', ');
  }

  /// Removes an inline "Support Services:" bullet list from a description when
  /// the same services are also published as their own field (as on some SOMOS
  /// campus centers), so the card never prints the list twice.
  static String _withoutInlineServices(
    String description,
    List<String> services,
  ) {
    if (description.isEmpty || services.isEmpty) return description;

    final serviceNames = services
        .map((service) => service.trim().toLowerCase())
        .toSet();
    final kept = <String>[];
    var dropping = false;
    for (final line in description.split(RegExp(r'\r?\n'))) {
      final trimmed = line.trim();
      final bullet = trimmed
          .replaceFirst(RegExp(r'^[-\u2022*]\s*'), '')
          .trim()
          .toLowerCase();

      if (dropping && trimmed.startsWith(RegExp(r'[-•*]'))) continue;
      if (serviceNames.contains(bullet)) {
        dropping = true;
        continue;
      }
      dropping = false;
      kept.add(line);
    }

    return kept
        .join('\n')
        .replaceFirst(
          RegExp(
            r'(\r?\n)*[^\r\n]*\b(support services|benefits and services)\b\s*:?\s*$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  factory LocationInfoData.fromAttributes(
    Map<String, dynamic>? attributes, {
    String? fallbackCategory,
    String? fallbackTitle,
    double? locationLat,
    double? locationLng,
    String? orgLogo,
    BoxFit? orgLogoFit,
    Color? orgLogoBackgroundColor,
    String? orgLogoLabel,
  }) {
    final category = _attributeText(attributes, const ['CATEGORY', 'Category']);
    final primaryAddress = _attributeText(attributes, const [
      'ADDRESS',
      'Address',
      'LOCATION',
      'Location',
    ]);
    final address = _composeAddress(attributes, primary: primaryAddress);

    final description = _attributeText(attributes, const [
      'DESCRIPTION',
      'Description',
      'DETAILS',
      'Details',
    ]);
    final supportServices = _attributeList(attributes, const [
      'SUPPORT_SERVICES',
      'SupportServices',
      'supportServices',
    ]);
    final amenities = _attributeList(attributes, const [
      'AMENITIES',
      'Amenities',
      'amenities',
    ]);

    final imageUrlField = _attributeText(attributes, const [
      'IMAGE_URL',
      'ImageUrl',
    ]);
    final imageAssetField = _attributeText(attributes, const [
      'IMAGE_ASSET',
      'ImageAsset',
    ]);
    final sharedImage = _attributeText(attributes, const [
      'IMAGES',
      'Images',
      'IMAGE',
      'Image',
    ]);
    var imageUrl = imageUrlField;
    if (imageUrl.isEmpty && sharedImage.startsWith(RegExp(r'https?://'))) {
      imageUrl = sharedImage;
    }

    return LocationInfoData(
      cardTitle: locationTitleFromAttributes(
        attributes,
        fallback: fallbackTitle ?? 'Unnamed location',
      ),
      id: _attributeText(attributes, const [
        'ID',
        'OBJECTID',
        'ObjectId',
        'GLOBALID',
        'GlobalID',
      ]),
      address: address,
      category: category.isNotEmpty ? category : cleanField(fallbackCategory),
      type: _attributeText(attributes, const [
        'TYPE',
        'Type',
        'FIELD_SIMPLIFIED',
        'Field_Simplified',
      ]),
      owned: _attributeText(attributes, const ['OWNED', 'Owned', 'OWNERSHIP']),
      website: _attributeText(attributes, const [
        'WEBSITE',
        'Website',
        'URL',
        'Url',
      ]),
      phone: _attributeText(attributes, const [
        'PHONE',
        'Phone',
        'PHONE_NUMBER',
        'PhoneNumber',
        'Phone_Number',
      ]),
      email: _attributeText(attributes, const ['EMAIL', 'Email']),
      description: _withoutInlineServices(description, supportServices),
      supportServices: supportServices,
      amenities: amenities,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      imageAsset: imageAssetField.startsWith('assets/')
          ? imageAssetField
          : null,
      socialLinks: <String, String>{
        'Instagram': _attributeText(attributes, const [
          'INSTAGRAM',
          'Instagram',
        ]),
        'Facebook': _attributeText(attributes, const ['FACEBOOK', 'Facebook']),
        'Twitter_X': _attributeText(attributes, const [
          'TWITTER_X',
          'Twitter_X',
          'TwitterX',
          'Twitter',
        ]),
        'TikTok': _attributeText(attributes, const ['TIKTOK', 'TikTok']),
        'LinkedIn': _attributeText(attributes, const ['LINKEDIN', 'LinkedIn']),
      },
      locationLat:
          locationLat ??
          _toDouble(
            _attributeValue(attributes, const ['LATITUDE', 'Latitude', 'LAT']),
          ),
      locationLng:
          locationLng ??
          _toDouble(
            _attributeValue(attributes, const [
              'LONGITUDE',
              'Longitude',
              'LNG',
              'LON',
            ]),
          ),
      orgLogo: orgLogo,
      orgLogoFit: orgLogoFit,
      orgLogoBackgroundColor: orgLogoBackgroundColor,
      orgLogoLabel: orgLogoLabel,
    );
  }
}

/// Formats the useful fields of a location for the platform share sheet.
/// Optional address and website values are omitted instead of leaving blank
/// lines in the shared content.
String buildLocationShareText(LocationInfoData data) {
  String optionalValue(String value) {
    final normalized = LocationInfoData.cleanField(value);
    return normalized.toLowerCase() == 'n/a' ||
            normalized.toLowerCase() == 'null'
        ? ''
        : normalized;
  }

  final fields = <String>[data.cardTitle.trim()];
  final address = optionalValue(data.address);
  final website = optionalValue(data.website);
  if (address.isNotEmpty) fields.add(address);
  if (website.isNotEmpty) fields.add(website);
  return fields.join('\n');
}

/// Builds the `tel:` URI used by the card's call button.
///
/// The stored numbers are written for people to read, for example
/// "(916) 278-2655". Phone dialers and iOS `URL(string:)` reject the spaces
/// and parentheses, so only a leading "+" and the digits are kept.
Uri phoneLaunchUri(String phone) {
  final trimmed = phone.trim();
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  final dialable = trimmed.startsWith('+') && digits.isNotEmpty
      ? '+$digits'
      : digits;
  return Uri(scheme: 'tel', path: dialable);
}

/// Builds the `mailto:` URI used by the card's email button.
///
/// Building the URI from its parts lets `Uri` encode any character the stored
/// address contains instead of relying on string interpolation.
Uri emailLaunchUri(String email) {
  return Uri(scheme: 'mailto', path: email.trim());
}

class LocationInfoCard extends StatelessWidget {
  final LocationInfoData data;
  final bool showFullInfo;

  /// Renders a fixed card that shows only the photo, the title, the type, and
  /// the address. Used by the SOMOS campus map for the Latine art locations.
  final bool summaryOnly;

  final VoidCallback onClose;
  final VoidCallback onShowMore;
  final VoidCallback onShowLess;
  final Future<void> Function(String text)? onShare;

  const LocationInfoCard({
    super.key,
    required this.data,
    required this.showFullInfo,
    this.summaryOnly = false,
    required this.onClose,
    required this.onShowMore,
    required this.onShowLess,
    this.onShare,
  });

  bool _hasValue(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed.toLowerCase() != 'n/a' &&
        trimmed.toLowerCase() != 'null';
  }

  /// Hands [uri] to the platform.
  ///
  /// The card deliberately does not ask [canLaunchUrl] first: on Android 11+
  /// and iOS that check returns false for `tel:` and `mailto:` unless the app
  /// declares the schemes, which silently swallowed every call and email tap.
  /// Launching directly is also what the url_launcher documentation
  /// recommends. Platforms either return false or throw when no app can handle
  /// the URI, so both are treated as a failed launch.
  Future<bool> _launchUri(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
      debugPrint('Could not launch $uri');
    } catch (error) {
      debugPrint('Could not launch $uri: $error');
    }
    return false;
  }

  Future<void> _shareLocation(BuildContext originContext) async {
    final text = buildLocationShareText(data);
    try {
      if (onShare != null) {
        await onShare!(text);
        return;
      }

      final box = originContext.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          title: data.cardTitle,
          subject: data.cardTitle,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (error) {
      debugPrint('Could not share ${data.cardTitle}: $error');
    }
  }

  bool get _canOpenMaps {
    return _hasValue(data.address) ||
        (data.locationLat != null && data.locationLng != null);
  }

  /// Opens the location in the platform's map app and reports whether it
  /// worked, so the card can tell the user when no map app is available.
  Future<bool> _openInMaps() async {
    final String destination = data.address.trim();
    final bool hasAddress = _hasValue(destination);
    final bool hasCoordinates =
        data.locationLat != null && data.locationLng != null;

    if (!hasAddress && !hasCoordinates) return false;

    try {
      if (hasAddress) {
        final String encodedDestination = Uri.encodeComponent(destination);
        final String encodedLabel = Uri.encodeComponent(data.cardTitle);

        Uri primaryUri;
        Uri fallbackUri;

        if (Platform.isIOS) {
          primaryUri = Uri.parse(
            'https://maps.apple.com/?daddr=$encodedDestination&dirflg=d&q=$encodedLabel',
          );
          fallbackUri = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$encodedDestination',
          );
        } else {
          primaryUri = Uri.parse('geo:0,0?q=$encodedDestination');
          fallbackUri = Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$encodedDestination&travelmode=driving',
          );
        }

        if (await _launchUri(primaryUri)) return true;
        if (await _launchUri(fallbackUri)) return true;
      }

      if (hasCoordinates) {
        final double lat = data.locationLat!;
        final double lng = data.locationLng!;
        final String label = Uri.encodeComponent(data.cardTitle);

        Uri primaryUri;
        Uri fallbackUri;

        if (Platform.isIOS) {
          primaryUri = Uri.parse(
            'https://maps.apple.com/?ll=$lat,$lng&q=$label',
          );
          fallbackUri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
          );
        } else {
          primaryUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
          fallbackUri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
          );
        }

        if (await _launchUri(primaryUri)) return true;
        if (await _launchUri(fallbackUri)) return true;
      }

      debugPrint('Could not launch maps for ${data.cardTitle}');
    } catch (e) {
      debugPrint('Error launching maps: $e');
    }
    return false;
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.trim().toLowerCase()) {
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'facebook':
        return FontAwesomeIcons.facebookF;
      case 'twitter_x':
        return FontAwesomeIcons.xTwitter;
      case 'tiktok':
        return FontAwesomeIcons.tiktok;
      case 'linkedin':
        return FontAwesomeIcons.linkedinIn;
      default:
        return FontAwesomeIcons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final palette = _LocationCardPalette.of(context);

    if (summaryOnly) {
      return _buildSummaryCard(context, mediaQuery);
    }

    final double expandedHeight = mediaQuery.size.height * 0.72;

    // The bundled photo is part of the compact card, so the card grows to make
    // room for it, while staying within the screen on small devices (the card
    // content also scrolls).
    final double collapsedHeight = data.hasBundledImage
        ? math.min(
            _previewCardHeight + _previewImageHeight + _previewImageGap,
            math.max(mediaQuery.size.height - 24, _previewCardHeight),
          )
        : _previewCardHeight;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: showFullInfo ? expandedHeight : collapsedHeight,
        margin: const EdgeInsets.all(12),
        child: Card(
          color: palette.background,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: showFullInfo
              ? _ExpandedLocationInfoCard(
                  data: data,
                  canOpenMaps: _canOpenMaps,
                  onClose: onClose,
                  onShowLess: onShowLess,
                  onOpenInMaps: _openInMaps,
                  onShare: _shareLocation,
                  launchUrl: _launchUri,
                  getSocialIcon: _getSocialIcon,
                )
              : _PreviewLocationInfoCard(
                  data: data,
                  cardTitle: data.cardTitle,
                  orgLogo: data.orgLogo,
                  orgLogoFit: data.orgLogoFit,
                  orgLogoBackgroundColor: data.orgLogoBackgroundColor,
                  orgLogoLabel: data.orgLogoLabel,
                  category: data.category,
                  imageAsset: data.imageAsset,
                  onClose: onClose,
                  onShowMore: onShowMore,
                  onShare: _shareLocation,
                ),
        ),
      ),
    );
  }

  /// Builds the fixed card used for the Latine art locations. It never expands
  /// and only shows the photo, the title, the type, and the address.
  Widget _buildSummaryCard(BuildContext context, MediaQueryData mediaQuery) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.8),
        child: Card(
          color: _LocationCardPalette.of(context).background,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: _SummaryLocationInfoCard(
            data: data,
            onClose: onClose,
            onShare: _shareLocation,
          ),
        ),
      ),
    );
  }
}

class _SummaryLocationInfoCard extends StatelessWidget {
  final LocationInfoData data;
  final VoidCallback onClose;
  final Future<void> Function(BuildContext) onShare;

  const _SummaryLocationInfoCard({
    required this.data,
    required this.onClose,
    required this.onShare,
  });

  bool _hasValue(String value) => LocationInfoData.cleanField(value).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final palette = _LocationCardPalette.of(context);
    final bool hasType = _hasValue(data.type);
    final bool hasAddress = _hasValue(data.address);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.hasOrgLogo) ...[
                  _OrgLogoAvatar(
                    logo: data.orgLogo,
                    label: data.orgLogoLabel,
                    fit: data.orgLogoFit,
                    backgroundColor: data.orgLogoBackgroundColor,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      data.cardTitle,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: LocationCardText.title(palette.foreground),
                    ),
                  ),
                ),
                FavoriteToggleButton(
                  favorite: data.favoriteEntry,
                  iconColor: palette.foreground,
                  iconSize: 28,
                ),
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Close location details',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: Icon(Icons.close, color: palette.foreground),
                ),
              ],
            ),
          ),
          if (hasType)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Text(
                data.type,
                style: LocationCardText.subtitle(palette.foreground),
              ),
            ),
          if (hasAddress)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on,
                      color: palette.foreground.withValues(alpha: 0.8),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.address,
                      style: LocationCardText.detail(palette.foreground),
                    ),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: _LocationShareButton(
              title: data.cardTitle,
              foreground: palette.foreground,
              onShare: onShare,
            ),
          ),
          if (data.hasImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: _LocationInfoImage(
                assetPath: data.imageAsset,
                url: data.imageUrl,
                height: 240,
                semanticsLabel: 'Photo of ${data.cardTitle}',
                expandOnTap: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationShareButton extends StatelessWidget {
  const _LocationShareButton({
    required this.title,
    required this.foreground,
    required this.onShare,
  });

  final String title;
  final Color foreground;
  final Future<void> Function(BuildContext) onShare;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Share $title',
      hint: 'Opens the device share sheet.',
      onTap: () => onShare(context),
      child: ExcludeSemantics(
        child: TextButton.icon(
          onPressed: () => onShare(context),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: foreground,
          ),
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
      ),
    );
  }
}

class _PreviewLocationInfoCard extends StatelessWidget {
  final LocationInfoData data;
  final String cardTitle;
  final String? orgLogo;
  final BoxFit? orgLogoFit;
  final Color? orgLogoBackgroundColor;
  final String? orgLogoLabel;
  final String category;
  final String? imageAsset;
  final VoidCallback onClose;
  final VoidCallback onShowMore;
  final Future<void> Function(BuildContext) onShare;

  const _PreviewLocationInfoCard({
    required this.data,
    required this.cardTitle,
    this.orgLogo,
    this.orgLogoFit,
    this.orgLogoBackgroundColor,
    this.orgLogoLabel,
    required this.category,
    this.imageAsset,
    required this.onClose,
    required this.onShowMore,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _LocationCardPalette.of(context);
    final bool hasCategory = category.trim().isNotEmpty;

    return LocationCardScrollArea(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((orgLogo?.trim().isNotEmpty ?? false) ||
                    (orgLogoLabel?.trim().isNotEmpty ?? false)) ...[
                  _OrgLogoAvatar(
                    logo: orgLogo,
                    label: orgLogoLabel,
                    fit: orgLogoFit,
                    backgroundColor: orgLogoBackgroundColor,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      cardTitle,
                      maxLines: hasCategory ? 3 : 4,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: LocationCardText.title(palette.foreground),
                    ),
                  ),
                ),
                FavoriteToggleButton(
                  favorite: data.favoriteEntry,
                  iconColor: palette.foreground,
                  iconSize: 28,
                ),
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Close location details',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: Icon(Icons.close, color: palette.foreground),
                ),
              ],
            ),
            if (hasCategory) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LocationCardText.subtitle(palette.foreground),
                ),
              ),
            ],
            if (data.address.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on,
                      color: palette.foreground.withValues(alpha: 0.8),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LocationCardText.body(palette.foreground),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onShowMore,
                style: LocationCardText.linkButtonStyle(),
                child: Text(
                  'More information',
                  style: LocationCardText.link(palette.foreground),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: _LocationShareButton(
                title: cardTitle,
                foreground: palette.foreground,
                onShare: onShare,
              ),
            ),
            if (_LocationInfoImage.hasAsset(imageAsset)) ...[
              const SizedBox(height: _previewImageGap),
              _LocationInfoImage(
                assetPath: imageAsset,
                height: _previewImageHeight,
                semanticsLabel: 'Photo of $cardTitle',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Draws a card field as a bold label followed by its regular-weight value,
/// e.g. "Category: Campus Centers".
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.value,
    required this.color,
    this.valueStyle,
  });

  final String label;
  final String value;
  final Color color;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: ', style: LocationCardText.fieldLabel(color)),
          TextSpan(
            text: value,
            style: valueStyle ?? LocationCardText.fieldValue(color),
          ),
        ],
      ),
    );
  }
}

class _ExpandedLocationInfoCard extends StatelessWidget {
  final LocationInfoData data;
  final bool canOpenMaps;
  final VoidCallback onClose;
  final VoidCallback onShowLess;

  /// Opens the location in a maps app and resolves to whether it launched,
  /// so the card can surface a message when no map app is available.
  final Future<bool> Function() onOpenInMaps;
  final Future<void> Function(BuildContext) onShare;
  final Future<bool> Function(Uri) launchUrl;
  final IconData Function(String) getSocialIcon;

  const _ExpandedLocationInfoCard({
    required this.data,
    required this.canOpenMaps,
    required this.onClose,
    required this.onShowLess,
    required this.onOpenInMaps,
    required this.onShare,
    required this.launchUrl,
    required this.getSocialIcon,
  });

  /// Runs [open] and tells the user why nothing happened when it fails.
  ///
  /// Handing a `tel:` or `mailto:` URI to the platform can fail on devices
  /// without a dialer or a configured mail account (and always fails in the
  /// iOS Simulator), so the tap would otherwise look broken.
  Future<void> _openAndReport(
    BuildContext context,
    Future<bool> Function() open,
    String failureMessage,
  ) async {
    final launched = await open();
    if (!launched && context.mounted) {
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  /// Opens [uri] and reports failure with [failureMessage].
  Future<void> _openLink(BuildContext context, Uri uri, String failureMessage) {
    return _openAndReport(context, () => launchUrl(uri), failureMessage);
  }

  /// Parses [url] and opens it, reporting unparseable values as failures.
  Future<void> _openUrl(
    BuildContext context,
    String url,
    String failureMessage,
  ) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      return _openAndReport(context, () async => false, failureMessage);
    }
    return _openLink(context, uri, failureMessage);
  }

  bool _hasValue(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed.toLowerCase() != 'n/a' &&
        trimmed.toLowerCase() != 'null';
  }

  /// The description shown in the card. The old placeholder text is hidden so
  /// a location that only has other details never shows a filler sentence.
  String get _description {
    final text = data.description.trim();
    return text.toLowerCase() == 'no description available.' ? '' : text;
  }

  bool _isValidSocialUrl(String value) {
    final trimmed = value.trim();

    if (!_hasValue(trimmed)) return false;

    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;

    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Map<String, String> _filteredSocialLinks() {
    if (data.socialLinks.isEmpty) return {};

    return Map<String, String>.fromEntries(
      data.socialLinks.entries.where(
        (entry) => _hasValue(entry.key) && _isValidSocialUrl(entry.value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _LocationCardPalette.of(context);
    final validSocialLinks = _filteredSocialLinks();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.hasOrgLogo) ...[
                _OrgLogoAvatar(
                  logo: data.orgLogo,
                  label: data.orgLogoLabel,
                  fit: data.orgLogoFit,
                  backgroundColor: data.orgLogoBackgroundColor,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    data.cardTitle,
                    softWrap: true,
                    style: LocationCardText.title(palette.foreground),
                  ),
                ),
              ),
              FavoriteToggleButton(
                favorite: data.favoriteEntry,
                iconColor: palette.foreground,
                iconSize: 28,
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'Close location details',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: Icon(Icons.close, color: palette.foreground),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: palette.divider),
        Expanded(
          child: LocationCardScrollArea(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location first, together with the option to open it in a
                // maps app.
                if (_hasValue(data.address)) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.location_on,
                          color: palette.foreground.withValues(alpha: 0.8),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.address,
                          style: LocationCardText.detail(palette.foreground),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (canOpenMaps) ...[
                  OutlinedButton.icon(
                    onPressed: () => _openAndReport(
                      context,
                      onOpenInMaps,
                      'Could not open the maps app.',
                    ),
                    icon: Icon(Icons.directions, color: palette.foreground),
                    label: Text(
                      'Open in Maps',
                      style: LocationCardText.detail(palette.foreground),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_hasValue(data.category)) ...[
                  _LabeledField(
                    label: 'Category',
                    value: data.category,
                    color: palette.foreground,
                  ),
                  const SizedBox(height: 4),
                ],
                if (_hasValue(data.type)) ...[
                  _LabeledField(
                    label: 'Type',
                    value: data.type,
                    color: palette.foreground,
                  ),
                  const SizedBox(height: 4),
                ],
                if (_hasValue(data.owned)) ...[
                  _LabeledField(
                    label: 'Ownership',
                    value: data.owned,
                    color: palette.foreground,
                  ),
                  const SizedBox(height: 4),
                ],
                if (_hasValue(data.category) ||
                    _hasValue(data.type) ||
                    _hasValue(data.owned))
                  const SizedBox(height: 12),
                if (_hasValue(_description)) ...[
                  _LabeledField(
                    label: 'Description',
                    value: _description,
                    color: palette.foreground,
                    valueStyle: LocationCardText.body(palette.foreground),
                  ),
                  const SizedBox(height: 16),
                ],
                if (data.supportServices.isNotEmpty) ...[
                  Text(
                    'Support Services',
                    style: LocationCardText.sectionHeader(palette.foreground),
                  ),
                  const SizedBox(height: 6),
                  ...data.supportServices.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '\u2022 $service',
                        style: LocationCardText.body(palette.foreground),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (data.amenities.isNotEmpty) ...[
                  Text(
                    'Amenities',
                    style: LocationCardText.sectionHeader(palette.foreground),
                  ),
                  const SizedBox(height: 6),
                  ...data.amenities.map(
                    (amenity) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '\u2022 $amenity',
                        style: LocationCardText.body(palette.foreground),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_hasValue(data.website)) ...[
                  TextButton(
                    onPressed: () => _openUrl(
                      context,
                      data.website,
                      'Could not open the website.',
                    ),
                    style: LocationCardText.linkButtonStyle(),
                    child: Text(
                      'Open website',
                      style: LocationCardText.link(palette.foreground),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_hasValue(data.phone)) ...[
                  TextButton(
                    onPressed: () => _openLink(
                      context,
                      phoneLaunchUri(data.phone),
                      'Could not open the phone app.',
                    ),
                    style: LocationCardText.linkButtonStyle(),
                    child: Text(
                      'Call ${data.phone}',
                      style: LocationCardText.link(palette.foreground),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (_hasValue(data.email)) ...[
                  TextButton(
                    onPressed: () => _openLink(
                      context,
                      emailLaunchUri(data.email),
                      'Could not open the email app.',
                    ),
                    style: LocationCardText.linkButtonStyle(),
                    child: Text(
                      'Email ${data.email}',
                      style: LocationCardText.link(palette.foreground),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (validSocialLinks.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.share,
                        color: palette.foreground.withValues(alpha: 0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Follow Us',
                        style: LocationCardText.sectionHeader(
                          palette.foreground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 16,
                    runSpacing: 15,
                    children: validSocialLinks.entries.map((entry) {
                      return IconButton.filled(
                        onPressed: () => _openUrl(
                          context,
                          entry.value,
                          'Could not open ${entry.key}.',
                        ),
                        tooltip: 'Open ${entry.key}',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AccessibilityColors.of(
                            context,
                          ).primary,
                        ),
                        icon: Icon(getSocialIcon(entry.key)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (data.hasImage) ...[
                  _LocationInfoImage(
                    assetPath: data.imageAsset,
                    url: data.imageUrl,
                    height: 240,
                    semanticsLabel: 'Photo of ${data.cardTitle}',
                    expandOnTap: true,
                  ),
                  const SizedBox(height: 16),
                ],
                _LocationShareButton(
                  title: data.cardTitle,
                  foreground: palette.foreground,
                  onShare: onShare,
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onShowLess,
                    style: LocationCardText.linkButtonStyle(),
                    child: Text(
                      'Show less',
                      style: LocationCardText.link(palette.foreground),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Scrollable body of a location card with a visible scrollbar (P1-335).
///
/// The thumb only paints when the content is taller than the card, so short
/// cards look the same as before. It sits in a gutter on the right edge so it
/// never covers text or buttons, follows the scroll position, and can be
/// dragged as well as touch-scrolled. Screen readers get a labelled scroll
/// region with the usual scroll actions.
class LocationCardScrollArea extends StatefulWidget {
  /// Width kept clear on the right for the scrollbar thumb.
  static const double scrollbarGutter = 10;

  final EdgeInsetsGeometry padding;
  final Widget child;

  const LocationCardScrollArea({
    super.key,
    required this.padding,
    required this.child,
  });

  @override
  State<LocationCardScrollArea> createState() => _LocationCardScrollAreaState();
}

class _LocationCardScrollAreaState extends State<LocationCardScrollArea> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Location details',
      child: RawScrollbar(
        key: const Key('locationCardScrollbar'),
        controller: _controller,
        thumbVisibility: true,
        thickness: 5,
        radius: const Radius.circular(4),
        thumbColor: mapInfoSecondaryTextColor,
        mainAxisMargin: 8,
        crossAxisMargin: 3,
        child: SingleChildScrollView(
          controller: _controller,
          padding: widget.padding.add(
            const EdgeInsets.only(
              right: LocationCardScrollArea.scrollbarGutter,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Shows the photo of a location card without cropping it, so the whole image
/// stays visible.
///
/// The bundled asset wins when one is available, so the Latine art photos work
/// offline, and network images are still supported for the other map screens.
class _LocationInfoImage extends StatelessWidget {
  final String? assetPath;
  final String? url;
  final double height;
  final String semanticsLabel;

  /// Whether tapping the photo opens it full screen. Only the Latine art cards
  /// enable this, so the other location cards keep their photos inert.
  final bool expandOnTap;

  const _LocationInfoImage({
    this.assetPath,
    this.url,
    this.height = 240,
    required this.semanticsLabel,
    this.expandOnTap = false,
  });

  /// The widest the photo is decoded at. The bundled art photos are high
  /// resolution phone photos, so decoding them at full size would waste memory
  /// for an image that is drawn at card width.
  static const int _maxDecodeWidth = 1080;

  /// Whether the whole photo must stay visible instead of being cropped.
  static const BoxFit _imageFit = BoxFit.contain;

  static bool hasAsset(String? assetPath) => _clean(assetPath) != null;

  static String? _clean(String? value) {
    final text = cleanLocationAttribute(value);
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _LocationCardPalette.of(context);
    final String? asset = _clean(assetPath);
    final String? networkUrl = _clean(url);

    final Widget image;
    if (asset != null) {
      image = Image.asset(
        asset,
        key: locationInfoImageKey,
        height: height,
        width: double.infinity,
        fit: _imageFit,
        cacheWidth: _maxDecodeWidth,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => _buildFallback(palette),
      );
    } else if (networkUrl != null) {
      image = Image.network(
        networkUrl,
        key: locationInfoImageKey,
        height: height,
        width: double.infinity,
        fit: _imageFit,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => _buildFallback(palette),
      );
    } else {
      return const SizedBox.shrink();
    }

    final Widget photo = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: image,
    );

    if (!expandOnTap) {
      return Semantics(
        image: true,
        label: semanticsLabel,
        excludeSemantics: true,
        child: photo,
      );
    }

    void openFullScreen() {
      FullScreenImageViewer.show(
        context,
        assetPath: asset,
        url: networkUrl,
        semanticsLabel: semanticsLabel,
      );
    }

    return Semantics(
      button: true,
      image: true,
      label: semanticsLabel,
      hint: 'Opens the photo full screen',
      onTap: openFullScreen,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: openFullScreen,
        child: photo,
      ),
    );
  }

  Widget _buildFallback(_LocationCardPalette palette) {
    return Container(
      height: height,
      width: double.infinity,
      color: palette.fallbackImage,
      alignment: Alignment.center,
      child: Text(
        'Image unavailable',
        style: TextStyle(color: palette.secondaryForeground),
      ),
    );
  }
}

/// Draws the icon shown beside the location card title.
///
/// Icons with a [fit] (the campus center logos) are scaled down inside a
/// rounded box; icons without one keep the circular avatar. A numbered marker
/// with no icon asset passes a [label] and is drawn as a marker-colored circle
/// with a white border. [backgroundColor] keeps light icons visible when their
/// marker needs a solid backdrop on the map.
class _OrgLogoAvatar extends StatelessWidget {
  const _OrgLogoAvatar({
    this.logo,
    this.label,
    this.fit,
    this.backgroundColor,
  });

  /// The logo box, sized to keep the height of the 40 px circular avatar it
  /// replaced while giving wide wordmarks some extra width.
  static const double _boxWidth = 48;
  static const double _boxHeight = 40;

  /// The bundled asset path of the icon.
  final String? logo;

  /// The number drawn for a numbered marker that has no icon asset.
  final String? label;

  /// How the icon is fitted inside its box. Null keeps the circular, cropped
  /// avatar used by markers with their own icon.
  final BoxFit? fit;

  /// The solid color behind the icon. Null keeps the original white background.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final String boxLabel = label?.trim() ?? '';
    final Color boxColor = backgroundColor ??
        (boxLabel.isNotEmpty ? mapInfoCardColor : Colors.white);
    if (boxLabel.isNotEmpty) {
      return Container(
        key: locationInfoLogoBoxKey,
        width: _boxHeight,
        height: _boxHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: boxColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            boxLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    final String asset = logo?.trim() ?? '';
    if (asset.isEmpty) return const SizedBox.shrink();

    final BoxFit? boxFit = fit;
    if (boxFit == null) {
      return CircleAvatar(
        radius: _boxHeight / 2,
        backgroundColor: boxColor,
        backgroundImage: AssetImage(asset),
      );
    }

    return Container(
      key: locationInfoLogoBoxKey,
      width: _boxWidth,
      height: _boxHeight,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(
        asset,
        fit: boxFit,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

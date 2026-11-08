import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:belonging_maps_app/services/accessibility_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/location_attributes.dart';
import 'full_screen_image_viewer.dart';

import '../services/accessibility_settings.dart';

// Color constants
const Color mapInfoCardColor = Color.fromARGB(255, 47, 95, 62);
const Color mapInfoPrimaryTextColor = Colors.white;
const Color mapInfoSecondaryTextColor = Colors.white70;
const Color mapInfoDividerColor = Colors.white24;
const Color mapInfoFallbackImageColor = Colors.white12;

/// Identifies the photo drawn inside a location card, so widget tests can find
/// it without depending on the image provider.
const Key locationInfoImageKey = ValueKey<String>('location-info-image');

/// Height of the photo in the compact location card.
const double _previewImageHeight = 150;

/// Gap between the compact card's content and its photo.
const double _previewImageGap = 12;

/// Height of the compact location card when it has no photo.
const double _previewCardHeight = 260;

class LocationInfoData {
  final String cardTitle;
  final String address;
  final String category;
  final String type;
  final String website;
  final String phone;
  final String email;
  final String description;
  final String? imageUrl;
  final String? imageAsset;
  final Map<String, String> socialLinks;
  final double? locationLat;
  final double? locationLng;
  final String? orgLogo;

  const LocationInfoData({
    required this.cardTitle,
    required this.address,
    required this.category,
    required this.type,
    required this.website,
    required this.phone,
    required this.email,
    required this.description,
    required this.imageUrl,
    this.imageAsset,
    required this.socialLinks,
    this.locationLat,
    this.locationLng,
    this.orgLogo,
  });

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

  factory LocationInfoData.fromAttributes(
    Map<String, dynamic>? attributes, {
    String? fallbackCategory,
  }) {
    final String categoryField = cleanField(attributes?['CATEGORY']);

    final String addressField = cleanField(attributes?['ADDRESS']);
    final String locationField = cleanField(attributes?['LOCATION']);

    final String descriptionField = cleanField(attributes?['DESCRIPTION']);
    final String detailsField = cleanField(attributes?['DETAILS']);

    final String websiteField = cleanField(attributes?['WEBSITE']);
    final String urlField = cleanField(attributes?['URL']);

    final String imageField = cleanField(attributes?['IMAGE_URL']);
    final String imageAssetField = cleanField(attributes?['IMAGE_ASSET']);

    return LocationInfoData(
      cardTitle: locationTitleFromAttributes(attributes),
      address: addressField.isNotEmpty
          ? addressField
          : locationField.isNotEmpty
          ? locationField
          : '',
      category: categoryField.isNotEmpty
          ? categoryField
          : cleanField(fallbackCategory),
      type: cleanField(attributes?['TYPE']),
      website: websiteField.isNotEmpty ? websiteField : urlField,
      phone: cleanField(attributes?['PHONE']),
      email: cleanField(attributes?['EMAIL']),
      description: descriptionField.isNotEmpty
          ? descriptionField
          : detailsField.isNotEmpty
          ? detailsField
          : 'No description available.',
      imageUrl: imageField.isNotEmpty ? imageField : null,
      imageAsset: imageAssetField.isNotEmpty ? imageAssetField : null,
      socialLinks: {
        'Instagram': cleanField(attributes?['Instagram']),
        'Facebook': cleanField(attributes?['Facebook']),
        'Twitter_X': cleanField(attributes?['Twitter_X']),
        'TikTok': cleanField(attributes?['TikTok']),
        'LinkedIn': cleanField(attributes?['LinkedIn']),
      },
      locationLat: _toDouble(
        attributes?['LATITUDE'] ??
            attributes?['Latitude'] ??
            attributes?['LAT'],
      ),
      locationLng: _toDouble(
        attributes?['LONGITUDE'] ??
            attributes?['Longitude'] ??
            attributes?['LNG'] ??
            attributes?['LON'],
      ),
    );
  }
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

  const LocationInfoCard({
    super.key,
    required this.data,
    required this.showFullInfo,
    this.summaryOnly = false,
    required this.onClose,
    required this.onShowMore,
    required this.onShowLess,
  });

  bool _hasValue(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed.toLowerCase() != 'n/a' &&
        trimmed.toLowerCase() != 'null';
  }

  Future<void> _launchUrl(String url) async {
    final String normalizedUrl = url.trim();
    final Uri uri = Uri.parse(normalizedUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $normalizedUrl');
    }
  }

  bool get _canOpenMaps {
    return _hasValue(data.address) ||
        (data.locationLat != null && data.locationLng != null);
  }

  Future<void> _openInMaps() async {
    final String destination = data.address.trim();
    final bool hasAddress = _hasValue(destination);
    final bool hasCoordinates =
        data.locationLat != null && data.locationLng != null;

    if (!hasAddress && !hasCoordinates) return;

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

        if (await canLaunchUrl(primaryUri)) {
          await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
          return;
        }

        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          return;
        }
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

        if (await canLaunchUrl(primaryUri)) {
          await launchUrl(primaryUri, mode: LaunchMode.externalApplication);
          return;
        }

        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      debugPrint('Could not launch maps for ${data.cardTitle}');
    } catch (e) {
      debugPrint('Error launching maps: $e');
    }
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
          color: AccessibilityColors.of(context).primary,
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
                  launchUrl: _launchUrl,
                  getSocialIcon: _getSocialIcon,
                )
              : _PreviewLocationInfoCard(
                  cardTitle: data.cardTitle,
                  orgLogo: data.orgLogo,
                  category: data.category,
                  imageAsset: data.imageAsset,
                  onClose: onClose,
                  onShowMore: onShowMore,
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
          color: AccessibilityColors.of(context).primary,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: _SummaryLocationInfoCard(data: data, onClose: onClose),
        ),
      ),
    );
  }
}

class _SummaryLocationInfoCard extends StatelessWidget {
  final LocationInfoData data;
  final VoidCallback onClose;

  const _SummaryLocationInfoCard({required this.data, required this.onClose});

  bool _hasValue(String value) => LocationInfoData.cleanField(value).isNotEmpty;

  @override
  Widget build(BuildContext context) {
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
                if (data.orgLogo != null) ...[
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(data.orgLogo!),
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
                      style: const TextStyle(
                        color: mapInfoPrimaryTextColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Close location details',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.close, color: mapInfoPrimaryTextColor),
                ),
              ],
            ),
          ),
          if (hasType)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Text(
                data.type,
                style: const TextStyle(
                  color: mapInfoPrimaryTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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
                      color: mapInfoPrimaryTextColor.withValues(alpha: 0.8),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.address,
                      style: const TextStyle(
                        color: mapInfoPrimaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
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

class _PreviewLocationInfoCard extends StatelessWidget {
  final String cardTitle;
  final String? orgLogo;
  final String category;
  final String? imageAsset;
  final VoidCallback onClose;
  final VoidCallback onShowMore;

  const _PreviewLocationInfoCard({
    required this.cardTitle,
    this.orgLogo,
    required this.category,
    this.imageAsset,
    required this.onClose,
    required this.onShowMore,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasCategory = category.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (orgLogo != null) ...[
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(orgLogo!),
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
                      style: const TextStyle(
                        color: mapInfoPrimaryTextColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Close location details',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.close, color: mapInfoPrimaryTextColor),
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
                  style: const TextStyle(
                    color: mapInfoSecondaryTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onShowMore,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(
                  'More information',
                  style: TextStyle(
                    color: mapInfoPrimaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
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

class _ExpandedLocationInfoCard extends StatelessWidget {
  final LocationInfoData data;
  final bool canOpenMaps;
  final VoidCallback onClose;
  final VoidCallback onShowLess;
  final VoidCallback onOpenInMaps;
  final Future<void> Function(String) launchUrl;
  final IconData Function(String) getSocialIcon;

  const _ExpandedLocationInfoCard({
    required this.data,
    required this.canOpenMaps,
    required this.onClose,
    required this.onShowLess,
    required this.onOpenInMaps,
    required this.launchUrl,
    required this.getSocialIcon,
  });

  bool _hasValue(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed.toLowerCase() != 'n/a' &&
        trimmed.toLowerCase() != 'null';
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
    final validSocialLinks = _filteredSocialLinks();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.orgLogo != null) ...[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage(data.orgLogo!),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    data.cardTitle,
                    softWrap: true,
                    style: const TextStyle(
                      color: mapInfoPrimaryTextColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                tooltip: 'Close location details',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.close, color: mapInfoPrimaryTextColor),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: mapInfoDividerColor),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasValue(data.address)) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.location_on,
                          color: mapInfoPrimaryTextColor.withOpacity(0.8),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data.address,
                          style: const TextStyle(
                            color: mapInfoPrimaryTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                if (_hasValue(data.category)) ...[
                  Text(
                    'Category: ${data.category}',
                    style: const TextStyle(
                      color: mapInfoPrimaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (_hasValue(data.type)) ...[
                  Text(
                    'Type: ${data.type}',
                    style: const TextStyle(
                      color: mapInfoPrimaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                if (_hasValue(data.website)) ...[
                  TextButton(
                    onPressed: () => launchUrl(data.website),
                    child: const Text(
                      'Open website',
                      style: TextStyle(color: mapInfoPrimaryTextColor),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                if (_hasValue(data.phone)) ...[
                  TextButton(
                    onPressed: () => launchUrl('tel:${data.phone}'),
                    child: Text(
                      'Call ${data.phone}',
                      style: const TextStyle(
                        color: mapInfoPrimaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (_hasValue(data.email)) ...[
                  TextButton(
                    onPressed: () => launchUrl('mailto:${data.email}'),
                    child: Text(
                      'Email ${data.email}',
                      style: const TextStyle(
                        color: mapInfoPrimaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                if (_hasValue(data.description)) ...[
                  Text(
                    data.description,
                    style: const TextStyle(
                      color: mapInfoPrimaryTextColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                if (validSocialLinks.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.share,
                        color: mapInfoPrimaryTextColor.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Follow Us',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: mapInfoPrimaryTextColor,
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
                        onPressed: () => launchUrl(entry.value),
                        tooltip: 'Open ${entry.key}',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AccessibilityColors.of(context).primary,
                        ),
                        icon: Icon(getSocialIcon(entry.key)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),
                ],
                const SizedBox(height: 18),
                if (canOpenMaps) ...[
                  OutlinedButton.icon(
                    onPressed: onOpenInMaps,
                    icon: const Icon(
                      Icons.directions,
                      color: mapInfoPrimaryTextColor,
                    ),
                    label: const Text(
                      'Open in Maps',
                      style: TextStyle(color: mapInfoPrimaryTextColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: mapInfoDividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onShowLess,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Show less',
                      style: TextStyle(
                        color: mapInfoPrimaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                if (data.hasImage) ...[
                  const SizedBox(height: 18),
                  _LocationInfoImage(
                    assetPath: data.imageAsset,
                    url: data.imageUrl,
                    height: 240,
                    semanticsLabel: 'Photo of ${data.cardTitle}',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
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
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else if (networkUrl != null) {
      image = Image.network(
        networkUrl,
        key: locationInfoImageKey,
        height: height,
        width: double.infinity,
        fit: _imageFit,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
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

  Widget _buildFallback() {
    return Container(
      height: height,
      width: double.infinity,
      color: mapInfoFallbackImageColor,
      alignment: Alignment.center,
      child: const Text(
        'Image unavailable',
        style: TextStyle(color: mapInfoSecondaryTextColor),
      ),
    );
  }
}

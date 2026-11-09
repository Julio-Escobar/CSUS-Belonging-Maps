import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/location_attributes.dart';
import '../services/accessibility_theme.dart';
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

  /// How the organization logo is fitted inside the card's logo box. When null
  /// the logo keeps the original circular avatar and is cropped to fill it,
  /// which suits square crests. Wide wordmarks pass [BoxFit.contain] so the
  /// whole logo stays visible inside a white rounded box.
  final BoxFit? orgLogoFit;

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
    this.orgLogoFit,
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

  Future<void> _launchUrl(String url) async {
    final String normalizedUrl = url.trim();
    final Uri uri = Uri.parse(normalizedUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $normalizedUrl');
    }
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
                  launchUrl: _launchUrl,
                  getSocialIcon: _getSocialIcon,
                )
              : _PreviewLocationInfoCard(
                  cardTitle: data.cardTitle,
                  orgLogo: data.orgLogo,
                  orgLogoFit: data.orgLogoFit,
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
                if (data.orgLogo != null) ...[
                  _OrgLogoAvatar(logo: data.orgLogo!, fit: data.orgLogoFit),
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
  final String cardTitle;
  final String? orgLogo;
  final BoxFit? orgLogoFit;
  final String category;
  final String? imageAsset;
  final VoidCallback onClose;
  final VoidCallback onShowMore;
  final Future<void> Function(BuildContext) onShare;

  const _PreviewLocationInfoCard({
    required this.cardTitle,
    this.orgLogo,
    this.orgLogoFit,
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
                if (orgLogo != null) ...[
                  _OrgLogoAvatar(logo: orgLogo!, fit: orgLogoFit),
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

class _ExpandedLocationInfoCard extends StatelessWidget {
  final LocationInfoData data;
  final bool canOpenMaps;
  final VoidCallback onClose;
  final VoidCallback onShowLess;
  final VoidCallback onOpenInMaps;
  final Future<void> Function(BuildContext) onShare;
  final Future<void> Function(String) launchUrl;
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
    final palette = _LocationCardPalette.of(context);
    final validSocialLinks = _filteredSocialLinks();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.orgLogo != null) ...[
                _OrgLogoAvatar(logo: data.orgLogo!, fit: data.orgLogoFit),
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
                  const SizedBox(height: 16),
                ],
                if (_hasValue(data.category)) ...[
                  Text(
                    'Category: ${data.category}',
                    style: LocationCardText.detail(palette.foreground),
                  ),
                  const SizedBox(height: 4),
                ],
                if (_hasValue(data.type)) ...[
                  Text(
                    'Type: ${data.type}',
                    style: LocationCardText.detail(palette.foreground),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_hasValue(data.website)) ...[
                  TextButton(
                    onPressed: () => launchUrl(data.website),
                    style: LocationCardText.linkButtonStyle(),
                    child: Text(
                      'Open website',
                      style: LocationCardText.link(palette.foreground),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_hasValue(data.phone)) ...[
                  TextButton(
                    onPressed: () => launchUrl('tel:${data.phone}'),
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
                    onPressed: () => launchUrl('mailto:${data.email}'),
                    style: LocationCardText.linkButtonStyle(),
                    child: Text(
                      'Email ${data.email}',
                      style: LocationCardText.link(palette.foreground),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _LocationShareButton(
                  title: data.cardTitle,
                  foreground: palette.foreground,
                  onShare: onShare,
                ),
                const SizedBox(height: 16),
                if (_hasValue(data.description)) ...[
                  Text(
                    data.description,
                    style: LocationCardText.body(palette.foreground),
                  ),
                  const SizedBox(height: 16),
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
                        onPressed: () => launchUrl(entry.value),
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
                const SizedBox(height: 18),
                if (canOpenMaps) ...[
                  OutlinedButton.icon(
                    onPressed: onOpenInMaps,
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
                  const SizedBox(height: 18),
                ],
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

/// Draws the organization logo shown beside the location card title.
///
/// Square crests keep the original circular avatar and are cropped to fill it.
/// Wide wordmarks (the Ummah campus center logos, for example) pass a [fit] so
/// the whole logo is scaled down inside a white rounded box instead of being
/// cropped to an unreadable sliver.
class _OrgLogoAvatar extends StatelessWidget {
  const _OrgLogoAvatar({required this.logo, this.fit});

  /// The logo box, sized to keep the height of the 40 px circular avatar it
  /// replaced while giving wide wordmarks some extra width.
  static const double _boxWidth = 48;
  static const double _boxHeight = 40;

  /// The bundled asset path of the logo.
  final String logo;

  /// How the logo is fitted inside its box. Null keeps the circular, cropped
  /// avatar used by the community, SOMOS, and Ubuntu maps.
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final BoxFit? boxFit = fit;
    if (boxFit == null) {
      return CircleAvatar(
        radius: _boxHeight / 2,
        backgroundColor: Colors.white,
        backgroundImage: AssetImage(logo),
      );
    }

    return Container(
      width: _boxWidth,
      height: _boxHeight,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(
        logo,
        fit: boxFit,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}


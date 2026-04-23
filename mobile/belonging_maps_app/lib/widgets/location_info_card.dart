import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Color constants
const Color mapInfoCardColor = Color.fromARGB(255, 47, 95, 62);
const Color mapInfoPrimaryTextColor = Colors.white;
const Color mapInfoSecondaryTextColor = Colors.white70;
const Color mapInfoDividerColor = Colors.white24;
const Color mapInfoFallbackImageColor = Colors.white12;

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
  final Map<String, String> socialLinks;
  final double? locationLat;
  final double? locationLng;

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
    required this.socialLinks,
    this.locationLat,
    this.locationLng,
  });

  static String cleanField(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    if (text.toLowerCase() == 'n/a') return '';
    if (text.toLowerCase() == 'null') return '';
    return text;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  factory LocationInfoData.fromAttributes(Map<String, dynamic>? attributes) {
    final String companyName = cleanField(attributes?['Company_Name']);
    final String name = cleanField(attributes?['Name']);

    final String addressField = cleanField(attributes?['ADDRESS']);
    final String locationField = cleanField(attributes?['LOCATION']);

    final String descriptionField = cleanField(attributes?['DESCRIPTION']);
    final String detailsField = cleanField(attributes?['DETAILS']);

    final String websiteField = cleanField(attributes?['WEBSITE']);
    final String urlField = cleanField(attributes?['URL']);

    final String imageField = cleanField(attributes?['IMAGE_URL']);

    return LocationInfoData(
      cardTitle: companyName.isNotEmpty
          ? companyName
          : name.isNotEmpty
              ? name
              : 'Location Info',
      address: addressField.isNotEmpty
          ? addressField
          : locationField.isNotEmpty
              ? locationField
              : '',
      category: cleanField(attributes?['CATEGORY']),
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
  final VoidCallback onClose;
  final VoidCallback onShowMore;
  final VoidCallback onShowLess;

  const LocationInfoCard({
    super.key,
    required this.data,
    required this.showFullInfo,
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
          primaryUri = Uri.parse(
            'geo:0,0?q=$encodedDestination',
          );
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
          primaryUri = Uri.parse(
            'geo:$lat,$lng?q=$lat,$lng($label)',
          );
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
    final double expandedHeight = MediaQuery.of(context).size.height * 0.72;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: showFullInfo ? expandedHeight : 190,
        margin: const EdgeInsets.all(12),
        child: Card(
          color: mapInfoCardColor,
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
                  onClose: onClose,
                  onShowMore: onShowMore,
                ),
        ),
      ),
    );
  }
}

class _PreviewLocationInfoCard extends StatelessWidget {
  final String cardTitle;
  final VoidCallback onClose;
  final VoidCallback onShowMore;

  const _PreviewLocationInfoCard({
    required this.cardTitle,
    required this.onClose,
    required this.onShowMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    cardTitle,
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                icon: const Icon(
                  Icons.close,
                  color: mapInfoPrimaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onShowMore,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Click here for more information',
                style: TextStyle(
                  color: mapInfoPrimaryTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                icon: const Icon(
                  Icons.close,
                  color: mapInfoPrimaryTextColor,
                ),
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
                  Text(
                    data.address,
                    style: const TextStyle(
                      color: mapInfoPrimaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 22),
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
                  GestureDetector(
                    onTap: () => launchUrl(data.website),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: mapInfoPrimaryTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          TextSpan(text: 'Website: '),
                          TextSpan(
                            text: 'Click Here',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                if (_hasValue(data.phone)) ...[
                  GestureDetector(
                    onTap: () => launchUrl('tel:${data.phone}'),
                    child: Text(
                      'Phone: ${data.phone}',
                      style: const TextStyle(
                        color: mapInfoPrimaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (_hasValue(data.email)) ...[
                  GestureDetector(
                    onTap: () => launchUrl('mailto:${data.email}'),
                    child: Text(
                      'Email: ${data.email}',
                      style: const TextStyle(
                        color: mapInfoPrimaryTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
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
                  const Text(
                    'Follow Us',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: mapInfoPrimaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    children: validSocialLinks.entries.map((entry) {
                      return GestureDetector(
                        onTap: () => launchUrl(entry.value),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white,
                          child: Icon(
                            getSocialIcon(entry.key),
                            color: mapInfoCardColor,
                            size: 28,
                          ),
                        ),
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
                if (data.imageUrl != null && data.imageUrl!.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data.imageUrl!.trim(),
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          width: double.infinity,
                          color: mapInfoFallbackImageColor,
                          alignment: Alignment.center,
                          child: const Text(
                            'Image unavailable',
                            style: TextStyle(color: mapInfoSecondaryTextColor),
                          ),
                        );
                      },
                    ),
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
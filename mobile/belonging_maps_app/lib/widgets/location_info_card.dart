import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Color constants
const Color mapInfoCardColor = Color.fromARGB(255, 47, 95, 62);
const Color mapInfoPrimaryTextColor = Colors.white;
const Color mapInfoSecondaryTextColor = Colors.white70;
const Color mapInfoDividerColor = Colors.white24;
const Color mapInfoFallbackImageColor = Colors.white12;

class LocationInfoCard extends StatelessWidget {
  final String cardTitle;
  final String address;
  final String category;
  final String type;
  final String website;
  final String phone;
  final String email;
  final String description;
  final String? imageUrl;
  final bool showFullInfo;
  final VoidCallback onClose;
  final VoidCallback onShowMore;
  final VoidCallback onShowLess;
  final Map<String, String>? socialLinks;

  const LocationInfoCard({
    super.key,
    required this.cardTitle,
    required this.address,
    required this.category,
    required this.type,
    required this.website,
    required this.phone,
    required this.email,
    required this.description,
    required this.imageUrl,
    required this.showFullInfo,
    required this.onClose,
    required this.onShowMore,
    required this.onShowLess,
    this.socialLinks,
  });

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'facebook':
        return FontAwesomeIcons.facebook;
      case 'twitter':
        return FontAwesomeIcons.twitter;
      default:
        return FontAwesomeIcons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: showFullInfo
            ? MediaQuery.of(context).size.height * 0.72
            : 150,
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
                  cardTitle: cardTitle,
                  address: address,
                  category: category,
                  type: type,
                  website: website,
                  phone: phone,
                  email: email,
                  description: description,
                  imageUrl: imageUrl,
                  onClose: onClose,
                  onShowLess: onShowLess,
                  socialLinks: socialLinks,
                  launchUrl: _launchUrl,
                  getSocialIcon: _getSocialIcon,
                )
              : _PreviewLocationInfoCard(
                  cardTitle: cardTitle,
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
                child: Text(
                  cardTitle,
                  style: const TextStyle(
                    color: mapInfoPrimaryTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.close,
                  color: mapInfoPrimaryTextColor,
                ),
              ),
            ],
          ),
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
  final String cardTitle;
  final String address;
  final String category;
  final String type;
  final String website;
  final String phone;
  final String email;
  final String description;
  final String? imageUrl;
  final VoidCallback onClose;
  final VoidCallback onShowLess;
  final Map<String, String>? socialLinks;
  final Future<void> Function(String) launchUrl;
  final IconData Function(String) getSocialIcon;

  const _ExpandedLocationInfoCard({
    required this.cardTitle,
    required this.address,
    required this.category,
    required this.type,
    required this.website,
    required this.phone,
    required this.email,
    required this.description,
    required this.imageUrl,
    required this.onClose,
    required this.onShowLess,
    this.socialLinks,
    required this.launchUrl,
    required this.getSocialIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  cardTitle,
                  style: const TextStyle(
                    color: mapInfoPrimaryTextColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
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
                Text(
                  address,
                  style: const TextStyle(
                    color: mapInfoPrimaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Category: $category',
                  style: const TextStyle(
                    color: mapInfoPrimaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Type: $type',
                  style: const TextStyle(
                    color: mapInfoPrimaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: mapInfoPrimaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      const TextSpan(text: 'Website: '),
                      TextSpan(
                        text: website.isNotEmpty ? 'Click Here' : 'Not available',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Phone: $phone',
                  style: const TextStyle(
                    color: mapInfoPrimaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Email: $email',
                  style: const TextStyle(
                    color: mapInfoPrimaryTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  description,
                  style: const TextStyle(
                    color: mapInfoPrimaryTextColor,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                // Social Media Links Section
                if (socialLinks != null && socialLinks!.isNotEmpty) ...[
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
                    children: socialLinks!.entries.map((entry) {
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
                const SizedBox(height: 18),
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl!,
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
                            style: TextStyle(
                              color: mapInfoSecondaryTextColor,
                            ),
                          ),
                        );
                      },
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

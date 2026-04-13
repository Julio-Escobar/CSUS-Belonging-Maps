import 'package:flutter/material.dart';

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
  });

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
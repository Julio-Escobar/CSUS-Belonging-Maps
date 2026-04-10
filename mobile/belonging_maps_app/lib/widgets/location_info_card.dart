import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/organization.dart';

class LocationInfoCard extends StatelessWidget {
  final Organization location;

  const LocationInfoCard({super.key, required this.location});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location Name (BOLD)
          Text(
            location.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A4A2E),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            location.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Social Media Links
          const Text(
            'Follow Us',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A4A2E),
            ),
          ),
          const SizedBox(height: 12),

          // Social Links as Icon Buttons
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: location.socialLinks.entries.map((entry) {
              return GestureDetector(
                onTap: () => _launchUrl(entry.value),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF1A4A2E),
                  child: Icon(
                    _getSocialIcon(entry.key),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0E0E0),
                foregroundColor: Colors.black,
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
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
}

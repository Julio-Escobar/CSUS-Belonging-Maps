import 'package:flutter/material.dart';
import '../constants/strings.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 47, 95, 62),
        foregroundColor: Colors.white,
        title: const Text(
          'About Us',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App logo / hero area
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 47, 95, 62),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belonging Maps',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
 
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
 
            // About section
            const _SectionHeader(title: 'About'),
            const SizedBox(height: 12),
            const Text(
              AppStrings.aboutDescription,
  style: TextStyle(fontSize: 15, height: 1.6),
            
        ),
            const SizedBox(height: 32),

            // Acknowledgements section
            const _SectionHeader(title: 'Acknowledgements'),
            const SizedBox(height: 12),
            const Text(
              AppStrings.acknowledgementIntro,
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            

            // Footer
            Center(
              child: Text(

                '© 2025 CSUS Belonging Maps. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
 
class _SectionHeader extends StatelessWidget {
  final String title;
 
  const _SectionHeader({required this.title});
 
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 47, 95, 62),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 153, 144, 11),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
class _AcknowledgementTile extends StatelessWidget {
  final String text;
  const _AcknowledgementTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Icon(
              Icons.circle,
              size: 8,
              color: Color.fromARGB(255, 153, 144, 11),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
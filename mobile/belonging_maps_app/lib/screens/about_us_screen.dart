import 'package:flutter/material.dart';
import '../constants/strings.dart';
import '../services/app_version.dart';

class AboutUsScreen extends StatelessWidget {
  /// Looks up the installed version (P1-322). Tests pass a fake.
  final AppVersionLoader versionLoader;

  const AboutUsScreen({
    super.key,
    this.versionLoader = loadInstalledAppVersion,
  });

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
                  _VersionText(loader: versionLoader),
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
 
/// Shows the installed version once it loads. The line keeps its height
/// while loading so the page doesn't jump, and an error just shows
/// "Version unavailable" instead of crashing the page (P1-322).
class _VersionText extends StatefulWidget {
  final AppVersionLoader loader;

  const _VersionText({required this.loader});

  @override
  State<_VersionText> createState() => _VersionTextState();
}

class _VersionTextState extends State<_VersionText> {
  late final Future<AppVersion> _version = widget.loader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppVersion>(
      future: _version,
      builder: (context, snapshot) {
        final String text;
        if (snapshot.hasData) {
          text = snapshot.data!.label;
        } else if (snapshot.hasError) {
          text = 'Version unavailable';
        } else {
          // Placeholder with the same height as the real line.
          text = 'Version';
        }
        return Text(
          text,
          key: const Key('aboutUsVersion'),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        );
      },
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

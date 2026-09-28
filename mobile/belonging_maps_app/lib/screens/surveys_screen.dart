import 'package:flutter/material.dart';

import 'forums_screen.dart';
import '../widgets/hamburger_menu.dart';

/// Navigation destination for the Surveys menu item.
class SurveysScreen extends StatelessWidget {
  const SurveysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      title: 'Surveys',
      body: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_outlined, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Survey Center',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Survey questions and results will be added here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForumsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Go to Forums'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Placeholder for future feedback survey functionality. For addition within other tickets.
                  },
                  icon: const Icon(Icons.feedback_outlined),
                  label: const Text('Feedback Survey'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Placeholder for future "What is Missing" survey functionality.
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('What is Missing'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

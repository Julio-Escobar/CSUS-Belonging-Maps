import 'package:flutter/material.dart';

import '../widgets/hamburger_menu.dart';

/// Navigation destination for the Surveys menu item.
///
/// Survey content is intentionally left to the survey-specific sprint tickets.
class SurveysScreen extends StatelessWidget {
  const SurveysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      title: 'Surveys',
      body: const Scaffold(body: SizedBox.expand()),
    );
  }
}

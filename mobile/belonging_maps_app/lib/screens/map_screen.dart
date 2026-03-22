import 'package:flutter/material.dart';
import '../widgets/hamburger_menu.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      title: 'Belonging Maps',
      body: const Center(
        child: Text(
          'ArcGIS map will appear here',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

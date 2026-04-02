import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/hamburger_menu.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      body: Scaffold(
        drawer: AdminDrawer(),
        appBar: AppBar(title: const Text("Belonging Maps")),

        body: const Center(
          child: Text(
            'ArcGIS map will appear here',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

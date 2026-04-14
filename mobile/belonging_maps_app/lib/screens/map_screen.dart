import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/hamburger_menu.dart';
import 'somos_campus_map.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      body: Scaffold(
        drawer: AdminDrawer(),
        appBar: AppBar(title: const Text("Belonging Maps")),
        body: const SomosCampusMap(),
      ),
    );
  }
}

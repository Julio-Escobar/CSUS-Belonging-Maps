import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AdminDrawer(),

      appBar: AppBar(
        title: const Text("Belonging Maps"),
      ),

      body: const Center(
        child: Text(
          "ArcGIS map will appear here",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
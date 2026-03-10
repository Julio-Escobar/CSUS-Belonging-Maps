import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
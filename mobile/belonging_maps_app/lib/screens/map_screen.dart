import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    // Drawer to home hamburger menu
    drawer: Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(16.0),
              ),
            ),
        ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  title: const Text('Welcome'),
                  onTap: () {
                    // Close drawer
                    Navigator.of(context).pop();
                    // Add actions here
                  },
                ),
                ListTile(
                  title: const Text('Campus Map'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Add navigation or actions here
                  },
                ),
                ListTile(
                  title: const Text('Community Map'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Add navigation or actions here
                  },
                ),
                ListTile(
                  title: const Text('Organizations'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Add navigation or actions here
                  },
                ),
                ListTile(
                  title: const Text('Opportunities'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Add navigation or actions here
                  },
                ),
                ListTile(
                  title: const Text('Community Resources'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Add navigation or actions here
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Us'),
            onTap: () {
              Navigator.of(context).pop();
              showAboutDialog(
                context: context,
                applicationName: 'Belonging Maps',
                applicationVersion: '1.0.0',
                children: const [
                  Text('CSUS Belonging Maps — connecting campus and community resources.')
                ],
              );
            },
          ),
        ],
      ),
    ),
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
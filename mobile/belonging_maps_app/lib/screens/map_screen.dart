import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  //P1-50
  Future<void> _openWebsite(BuildContext context) async {
    final Uri url = Uri.parse(
      'https://www.csus.edu/president/inclusive-excellence/hispanic-serving-institution/',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open website')),
      );
    }
  }

  //P1-52
  Future<void> _openMaps(BuildContext context) async {
    final String address = "Del Norte Hall, Sacramento State";

    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }

  //Bottom Sheet
  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.green[800],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Title
              const Text(
                "Hispanic Serving Institution (HSI)",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              // Address (P1-52)
              GestureDetector(
                onTap: () => _openMaps(context),
                child: const Text(
                  "Del Norte Hall, Room 2005",
                  style: TextStyle(
                    color: Colors.white70,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Website (P1-50)
              GestureDetector(
                onTap: () => _openWebsite(context),
                child: const Text(
                  "Website: Click Here",
                  style: TextStyle(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Contact (P1-130)
              const Text(
                "Phone: (916) 278-4796",
                style: TextStyle(color: Colors.white),
              ),

              const Text(
                "Email: ie-hsi@csus.edu",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),

//Open in Maps Button
ElevatedButton(
  onPressed: () => _openMaps(context),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
  child: const Text("Open in Maps"),
),
            ],
          ),
        );
      },
    );
  }//1

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Campus Map")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showDetails(context),
          child: const Text("Tap Marker (Demo)"),
        ),
      ),
    );
  }
}
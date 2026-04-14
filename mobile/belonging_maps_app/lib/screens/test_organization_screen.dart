import 'package:flutter/material.dart';
import '../models/organization.dart';
import '../widgets/location_info_card.dart';
//Revmove when real data added

class TestOrganizationScreen extends StatelessWidget {
  const TestOrganizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Location'),
        backgroundColor: const Color(0xFF1A4A2E),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Sample organization data
            final organization = Organization(
              id: '1',
              name: 'Temp Location',
              description:
                  'Hello Hello Hello Hello Add discription here about the resource',
              socialLinks: {
                'instagram': 'https://instagram.com/devgandhi_',
                'facebook': 'https://facebook.com/sacstate',
                'twitter': 'https://twitter.com/sacstate',
              },
              category: 'Campus',
            );

            // Show location info card in bottom sheet
            showModalBottomSheet(
              context: context,
              builder: (context) => LocationInfoCard(location: organization),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A4A2E),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          child: const Text(
            'Show Map Location',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

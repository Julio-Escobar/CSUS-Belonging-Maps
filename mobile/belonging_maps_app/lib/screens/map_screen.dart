import 'package:flutter/material.dart';
import 'somos_campus_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _CampusMapsScreenState();
}

class _CampusMapsScreenState extends State<MapScreen> {
  final List<Map<String, String>> _events = [
    {'name': 'Welcome Fair', 'category': 'Student Life'},
    {'name': 'Career Expo', 'category': 'Career'},
    {'name': 'Art Walk', 'category': 'Arts'},
  ];

  String? _activeCategoryFilter;

  void _resetFilters() {
    setState(() {
      _activeCategoryFilter = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters reset to default')),
    );
  }

  void _showEventDetails({
    required String name,
    required String category,
    String? description,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(description),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SomosCampusMap();
  }
}
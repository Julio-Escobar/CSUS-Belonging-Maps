import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/hamburger_menu.dart';
import 'somos_campus_map.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

@override
  State<MapScreen> createState() => _CampusMapsScreenState();
}
class _CampusMapsScreenState extends State<MapScreen> {
  // Simple demo event model
  final List<Map<String, String>> _events = [
    {'name': 'Welcome Fair', 'category': 'Student Life'},
    {'name': 'Career Expo', 'category': 'Career'},
    {'name': 'Art Walk', 'category': 'Arts'},
  ];

  // Demo filter state (null == no filter)
  String? _activeCategoryFilter;

  // Reset filters action
  void _resetFilters() {
    setState(() {
      _activeCategoryFilter = null;
      // In a real map view you would also reset map extent or reload default data.
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters reset to default')),
    );
  }

  // Called when a marker (or event) is tapped: show name + category
  void _showEventDetails({required String name, required String category, String? description}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(category, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(description),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      body: Scaffold(
        drawer: AdminDrawer(),
        appBar: AppBar(title: const Text("Belonging Maps")),
        body: SomosCampusMap(),
      ),
    );
  }
}

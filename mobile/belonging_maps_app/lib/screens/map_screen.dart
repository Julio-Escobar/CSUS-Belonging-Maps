import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/hamburger_menu.dart';

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
    final filteredEvents = _activeCategoryFilter == null
        ? _events
        : _events.where((e) => e['category'] == _activeCategoryFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Maps'),
        actions: [
          IconButton(
            tooltip: 'Reset filters',
            icon: const Icon(Icons.refresh),
            onPressed: _resetFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Map placeholder — replace with map widget later
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: Stack(
                children: [
                  // Replace these positioned buttons with real map markers.
                  Center(child: Text('Map placeholder (replace with ArcGIS widget)', style: TextStyle(color: Colors.grey.shade700))),
                  Positioned(
                    left: 40,
                    top: 40,
                    child: IconButton(
                      icon: const Icon(Icons.place, color: Colors.red),
                      onPressed: () => _showEventDetails(name: _events[0]['name']!, category: _events[0]['category']!),
                      tooltip: _events[0]['name'],
                    ),
                  ),
                  Positioned(
                    right: 60,
                    top: 100,
                    child: IconButton(
                      icon: const Icon(Icons.place, color: Colors.blue),
                      onPressed: () => _showEventDetails(name: _events[1]['name']!, category: _events[1]['category']!),
                      tooltip: _events[1]['name'],
                    ),
                  ),
                  Positioned(
                    left: 140,
                    bottom: 40,
                    child: IconButton(
                      icon: const Icon(Icons.place, color: Colors.green),
                      onPressed: () => _showEventDetails(name: _events[2]['name']!, category: _events[2]['category']!),
                      tooltip: _events[2]['name'],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Simple filter UI and event list for testing
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _activeCategoryFilter == null,
                        onSelected: (_) => setState(() => _activeCategoryFilter = null),
                      ),
                      ..._events.map((e) => e['category']).toSet().map((cat) {
                        return FilterChip(
                          label: Text(cat!),
                          selected: _activeCategoryFilter == cat,
                          onSelected: (sel) => setState(() => _activeCategoryFilter = sel ? cat : null),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredEvents.length,
                      itemBuilder: (_, i) {
                        final ev = filteredEvents[i];
                        return ListTile(
                          title: Text(ev['name']!),
                          subtitle: Text(ev['category']!),
                          onTap: () => _showEventDetails(name: ev['name']!, category: ev['category']!),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

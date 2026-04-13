import 'package:flutter/material.dart';

class CampusMapsScreen extends StatefulWidget {
  const CampusMapsScreen({super.key});

  @override
  State<CampusMapsScreen> createState() => _CampusMapsScreenState();
}

class _CampusMapsScreenState extends State<CampusMapsScreen> {
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, String>> maps = [
    {
      'label': 'SOMOS Campus Map',
      'subtitle': 'Mapping Our Campus',
      'imagePath': 'assets/somoscampusmap.png',
    },
  ];

  List<Map<String, String>> filteredMaps = [];

  @override
  void initState() {
    super.initState();
    filteredMaps = maps;
  }

  void filterSearch(String query) {
    setState(() {
      filteredMaps = maps
          .where(
            (map) => map['label']!.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  void performSearch() {
    final query = searchController.text;

    setState(() {
      filteredMaps = maps
          .where(
            (map) => map['label']!.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A4A2E),
        foregroundColor: Colors.white,
        title: const Text(
          'Campus Maps',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: searchController,
              onChanged: filterSearch,
              onSubmitted: (_) => performSearch(),
              decoration: InputDecoration(
                hintText: "Search maps...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Explore Our Campus',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A4A2E),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a map to get started',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredMaps.length,
                itemBuilder: (context, index) {
                  final map = filteredMaps[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MapButton(
                      label: map['label']!,
                      subtitle: map['subtitle']!,
                      imagePath: map['imagePath']!,
                      onTap: () {},
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;

  const _MapButton({
    required this.label,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A4A2E).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey);
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Georgia',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

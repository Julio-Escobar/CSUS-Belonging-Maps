import 'package:flutter/material.dart';
import '/screens/somos_campus_map.dart';
import '/screens/ummah_campus_map.dart';
import '/screens/ubuntu_campus_map.dart';

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
      'imagePath': 'assets/somosCampusMap.png',
    },
  ];

  List<Map<String, String>> filteredMaps = [];

  @override
  void initState() {
    super.initState();
    filteredMaps = maps;
  }

  void performSearch(String query) {
    setState(() {
      filteredMaps = maps
          .where((map) =>
              map['label']!.toLowerCase().contains(query.toLowerCase()))
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
            fontFamily: '',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //campus buttons
            const Text(
              'Explore Our Campus',
              style: TextStyle(
                fontFamily: '',
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
            const SizedBox(height: 28),

            _MapButton(
              label: 'SOMOS Campus Map',
              subtitle: 'SOMOS Campus',
              imagePath: 'assets/somoscampusmap.PNG',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SomosCampusMap()),
                );
              },
            ),

            const SizedBox(height: 16),

            _MapButton(
              label: 'Ummah Campus Map',
              subtitle: 'Ummah Campus',
              imagePath: 'assets/ummahcampusmap.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UmmahCampusMap()),
                );
              },
            ),

            const SizedBox(height: 16),

            _MapButton(
              label: 'Ubuntu Campus Map',
              subtitle: 'Ubuntu Campus',
              imagePath: 'assets/ubuntucampusmap.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UbuntuCampusMap()),
                );
              },
            ),

            const SizedBox(height: 36),

            //resource buttons
            const Text(
              'Explore Our Campus',
              style: TextStyle(
                fontFamily: '',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A4A2E),
              ),
            ),

            const SizedBox(height: 20),

            // FIX: ListView inside Expanded ONLY (no scrollview above)
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SomosCampusMap(),
                          ),
                        );
                      },
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

class _MapButton extends StatefulWidget {
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
  State<_MapButton> createState() => _MapButtonState();
}

class _MapButtonState extends State<_MapButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
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
                Image.asset(widget.imagePath, fit: BoxFit.cover),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: '',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
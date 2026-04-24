import 'package:flutter/material.dart';
import '/screens/somos_community_map.dart';
import '/screens/ummah_community_map.dart';
import '/screens/ubuntu_community_map.dart';

class CommunityMapsDirectory extends StatelessWidget {
  const CommunityMapsDirectory({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 31, 58, 95),
        foregroundColor: Colors.white,
        title: const Text(
          'Community Maps',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Explore Community Maps',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 31, 58, 95),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a community to get started',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 28),

            //somos community button
            _MapButton(
              label: 'SOMOS Community Map',
              subtitle: 'SOMOS Community',
              imagePath: 'assets/somoscommunityheader.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SomosCommunityMap()),
                );
              },
            ),

            const SizedBox(height: 16),

            //ummah community button
            _MapButton(
              label: 'Ummah Community Map',
              subtitle: 'Ummah Community',
              imagePath: 'assets/ummahcommunityheader.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UmmahCommunityMap()),
                );
              },
            ),

            const SizedBox(height: 16),
            //ubuntu community button
            _MapButton(
              label: 'Ubuntu Community Map',
              subtitle: 'Ubuntu Community',
              imagePath: 'assets/ubuntucommunityheader.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UbuntuCommunityMap()),
                );
              },
            ),

            const SizedBox(height: 36),
            //resources
            const Text(
              'Explore Community Resource Maps',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 31, 58, 95),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a community to get started',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 28),

            //somos community resource button
            _MapButton(
              label: 'SOMOS Community Resource Map',
              subtitle: 'SOMOS Community Resources',
              imagePath: 'assets/somoscommunityheader.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SomosCommunityMap()),
                );
              },
            ),

            const SizedBox(height: 16),

            //ummah community resource button
            _MapButton(
              label: 'Ummah Community Resources Map',
              subtitle: 'Ummah Community Resources',
              imagePath: 'assets/ummahcommunityheader.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UmmahCommunityMap()),
                );
              },
            ),

            const SizedBox(height: 16),
            //ubuntu community resource button
            _MapButton(
              label: 'Ubuntu Community Resources Map',
              subtitle: 'Ubuntu Community Resources',
              imagePath: 'assets/ubuntucommunityheader.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UbuntuCommunityMap()),
                );
              },
            ),


            const SizedBox(height: 24),


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
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.975,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
          width: double.infinity,
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 31, 58, 95).withOpacity(0.25),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 4),
                                ],
                              ),
                            ),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 4),
                                ],
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
      ),
    );
  }
}
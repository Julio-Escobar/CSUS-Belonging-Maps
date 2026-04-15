import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/campus_maps_screen.dart';
import '../screens/community_maps_directory.dart';
import '../screens/login_screen.dart';

final Color backgroundMenuColor = const Color.fromARGB(255, 47, 95, 62);
final Color menuItemTextColor = Colors.white;
final Color menuItemIconColor = const Color.fromARGB(255, 153, 144, 11);

final Color topBarColor = const Color.fromARGB(255, 47, 95, 62);
final Color topBarTextColor = Colors.white;
final Color topBarIconColor = const Color.fromARGB(255, 9, 70, 29);

class HamburgerMenu extends StatefulWidget {
  final Widget body;
  final String title;

  const HamburgerMenu({
    super.key,
    required this.body,
    this.title = 'Belonging Maps',
  });

  @override
  State<HamburgerMenu> createState() => _HamburgerMenuState();
}

class _HamburgerMenuState extends State<HamburgerMenu> {
  bool _drawerOpen = false;

  void _toggleDrawer() {
    setState(() {
      _drawerOpen = !_drawerOpen;
    });
  }

  void _closeDrawer() {
    if (_drawerOpen) {
      setState(() {
        _drawerOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: topBarColor,
        foregroundColor: topBarTextColor,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleDrawer,
        ),
      ),
      body: Stack(
        children: [
          widget.body,
          IgnorePointer(
            ignoring: !_drawerOpen,
            child: AnimatedOpacity(
              opacity: _drawerOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(color: Colors.black),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _drawerOpen ? 0 : -280,
            top: 0,
            bottom: 0,
            width: 280,
            child: Material(
              elevation: 16,
              color: backgroundMenuColor,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.waving_hand_sharp),
                      title: const Text('Welcome'),
                      textColor: menuItemTextColor,
                      iconColor: menuItemIconColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WelcomeScreen(),
                          ),
                        );
                        _closeDrawer();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.school_outlined),
                      title: const Text('Campus Maps'),
                      textColor: menuItemTextColor,
                      iconColor: menuItemIconColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CampusMapsScreen(),
                          ),
                        );
                        _closeDrawer();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.location_city_outlined),
                      title: const Text('Community Maps'),
                      textColor: menuItemTextColor,
                      iconColor: menuItemIconColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CommunityMapsDirectory(),
                          ),
                        );
                        _closeDrawer();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.people_outline),
                      title: const Text('Organizations'),
                      textColor: menuItemTextColor,
                      iconColor: menuItemIconColor,
                      onTap: _closeDrawer,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: const Text('Opportunities'),
                      textColor: menuItemTextColor,
                      iconColor: menuItemIconColor,
                      onTap: _closeDrawer,
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.book_online_outlined),
                      title: const Text('Community Resources'),
                      textColor: menuItemTextColor,
                      iconColor: menuItemIconColor,
                      onTap: _closeDrawer,
                    ),
                    const Divider(),
                    const Spacer(),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_3_outlined),
                      title: const Text('Administrator Login'),
                      textColor: menuItemTextColor,
                      iconColor: menuItemIconColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                        );
                        _closeDrawer();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_pin_outlined),
                      title: const Text('About Us'),
                      textColor: menuItemTextColor,
                      iconColor: menuItemIconColor,
                      onTap: _closeDrawer,
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

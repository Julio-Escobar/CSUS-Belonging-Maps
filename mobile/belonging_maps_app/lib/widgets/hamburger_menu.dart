import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../screens/campus_maps_screen.dart';
import '../screens/community_maps_directory.dart';
import '../screens/community_resources_screen.dart';
import '../screens/organization_resources_screen.dart';
import '../screens/login_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/accessibility_settings_screen.dart';
import '../screens/opportunities.dart';
import '../services/auth_service.dart';
import '../services/accessibility_theme.dart';

class HamburgerMenu extends StatefulWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;

  const HamburgerMenu({
    super.key,
    required this.body,
    this.title = 'Belonging Maps',
    this.actions,
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
    final isAdmin = AuthService.isAdmin;
    final colors = AccessibilityColors.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final drawerDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 300);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _toggleDrawer,
        ),
        actions: widget.actions,
      ),
      body: Stack(
        children: [
          widget.body,
          IgnorePointer(
            ignoring: !_drawerOpen,
            child: AnimatedOpacity(
              opacity: _drawerOpen ? 0.5 : 0.0,
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(color: Colors.black),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: drawerDuration,
            left: _drawerOpen ? 0 : -280,
            top: 0,
            bottom: 0,
            width: 280,
            child: Material(
              elevation: 16,
              color: colors.primary,
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.waving_hand_sharp),
                        title: const Text('Welcome'),
                        textColor: colors.onPrimary,
                        iconColor: colors.menuIcon,
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
                        textColor: colors.onPrimary,
                        iconColor: colors.menuIcon,
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
                        leading: const Icon(Icons.library_books_outlined),
                        title: const Text('Community Resources'),
                        textColor: colors.onPrimary,
                        iconColor: colors.menuIcon,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CommunityResourcesScreen(),
                            ),
                          );
                          _closeDrawer();
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.folder_shared_outlined),
                        title: const Text('Organization Resources'),
                        textColor: colors.onPrimary,
                        iconColor: colors.menuIcon,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OrganizationResourcesScreen(),
                            ),
                          );
                          _closeDrawer();
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.location_city_outlined),
                        title: const Text('Community Maps'),
                        textColor: colors.onPrimary,
                        iconColor: colors.menuIcon,
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
                        leading: const Icon(Icons.announcement_outlined),
                        title: const Text('Opportunities'),
                        textColor: colors.onPrimary,
                        iconColor: colors.menuIcon,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OpportunitiesScreen(),
                            ),
                          );
                          _closeDrawer();
                        },
                      ),
                      const Divider(),

                      ListTile(
                        leading: const Icon(Icons.accessibility_new),
                        title: const Text('Accessibility Settings'),
                        textColor: colors.onPrimary,
                        iconColor: colors.menuIcon,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AccessibilitySettingsScreen(),
                            ),
                          );
                          _closeDrawer();
                        },
                      ),
                      const Divider(),

                      if (isAdmin) ...[
                        const Divider(),
                        const ListTile(
                          title: Text(
                            "ADMIN PANEL",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text("Edit Maps"),
                          textColor: colors.onPrimary,
                          iconColor: colors.menuIcon,
                          onTap: _closeDrawer,
                        ),
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text("Add Location"),
                          textColor: colors.onPrimary,
                          iconColor: colors.menuIcon,
                          onTap: _closeDrawer,
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text("Delete Entries"),
                          textColor: colors.onPrimary,
                          iconColor: colors.menuIcon,
                          onTap: _closeDrawer,
                        ),
                      ],

                      const Divider(),

                      if (!isAdmin)
                        ListTile(
                          leading: const Icon(Icons.person_3_outlined),
                          title: const Text('Administrator Login'),
                          textColor: colors.onPrimary,
                          iconColor: colors.menuIcon,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginScreen()),
                            );
                            _closeDrawer();
                          },
                        ),

                      if (isAdmin)
                        ListTile(
                          leading: const Icon(Icons.logout),
                          title: const Text('Logout'),
                          textColor: colors.onPrimary,
                          iconColor: colors.menuIcon,
                          onTap: () {
                            AuthService.isAdmin = false;

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WelcomeScreen(),
                              ),
                              (route) => false,
                            );

                            _closeDrawer();
                          },
                        ),

                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.person_pin_outlined),
                        title: const Text('About Us'),
                        textColor: colors.onPrimary,
                        iconColor: colors.menuIcon,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AboutUsScreen(),
                            ),
                          );
                          _closeDrawer();
                        },
                      ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

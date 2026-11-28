import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/strings.dart';
import '../screens/welcome_screen.dart';
import '../screens/campus_maps_screen.dart';
import '../screens/community_maps_directory.dart';
import '../screens/announcements_screen.dart';
import '../screens/login_screen.dart';
import '../screens/about_us_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/accessibility_settings_screen.dart';
import '../screens/scholarships_screen.dart';
import '../screens/surveys_screen.dart';
import '../screens/change_password_screen.dart';
import '../services/auth_service.dart';
import '../services/accessibility_theme.dart';

/// Top-level destinations listed in the navigation drawer.
enum MenuDestination {
  welcome,
  campusMaps,
  communityMaps,
  announcements,
  organizationResources,
  scholarships,
  favorites,
  forums,
  surveys,
  accessibilitySettings,
  login,
  changePassword,
  aboutUs,
}

/// One entry in the navigation drawer.
///
/// The label, icon, destination and screen live together so a rename can never
/// leave a menu entry opening a different page (the Announcements/Scholarships
/// swap regression).
typedef _PageEntry = ({
  MenuDestination destination,
  IconData icon,
  String label,
  Widget Function() build,
});

class HamburgerMenu extends StatefulWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;

  /// Replaces the menu button with a back button and hides the drawer.
  ///
  /// Maps and detail screens use this so people always have a way back to the
  /// page that opened them.
  final bool showBackButton;

  /// The drawer destination for the page hosting this menu.
  ///
  /// When set, the drawer highlights the current page and tapping it just
  /// closes the menu instead of pushing a duplicate.
  final MenuDestination? currentDestination;

  const HamburgerMenu({
    super.key,
    required this.body,
    this.title = 'Belonging Maps',
    this.actions,
    this.showBackButton = false,
    this.currentDestination,
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

  /// Opens a drawer destination directly above the app's root page.
  ///
  /// Removing the intermediate routes keeps back predictable: from any
  /// top-level page the system back button returns to the root instead of
  /// walking through stale copies of pages the person already left.
  void _selectDestination(MenuDestination destination, WidgetBuilder builder) {
    if (widget.currentDestination == destination) {
      _closeDrawer();
      return;
    }

    // Close the menu before leaving. The root page stays in the stack, so a
    // drawer left open there would otherwise cover it when the person returns.
    _closeDrawer();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: builder),
      (route) => route.isFirst,
    );
  }

  /// Returns to the app's root page (Welcome in the running app).
  void _goHome() {
    final wasRoot = ModalRoute.of(context)?.isFirst ?? false;
    _closeDrawer();
    if (!wasRoot) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// Opens the Handshake job board outside the app.
  ///
  /// Job opportunities live on Handshake, so the drawer hands people off to
  /// the system browser instead of keeping a duplicate page in the app.
  Future<void> _openJobOpportunities() async {
    _closeDrawer();

    var launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(AppStrings.jobOpportunitiesUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      launched = false;
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Job Opportunities')),
      );
    }
  }

  /// Main pages, in menu order: maps first, then the content pages.
  static final List<_PageEntry> _mainPages = [
    (
      destination: MenuDestination.campusMaps,
      icon: Icons.school_outlined,
      label: 'Campus Maps',
      build: () => const CampusMapsScreen(),
    ),
    (
      destination: MenuDestination.communityMaps,
      icon: Icons.location_city_outlined,
      label: 'Community Maps',
      build: () => const CommunityMapsDirectory(),
    ),
    (
      destination: MenuDestination.announcements,
      icon: Icons.announcement_outlined,
      label: 'Announcements',
      build: () => const AnnouncementsScreen(),
    ),
    (
      destination: MenuDestination.scholarships,
      icon: Icons.workspace_premium_outlined,
      label: 'Scholarships',
      build: () => const ScholarshipsScreen(),
    ),
  ];

  /// Secondary pages, listed below Job Opportunities.
  static final List<_PageEntry> _secondaryPages = [
    (
      destination: MenuDestination.favorites,
      icon: Icons.star_outline,
      label: 'Favorites',
      build: () => const FavoritesScreen(),
    ),
    (
      destination: MenuDestination.surveys,
      icon: Icons.feedback_outlined,
      label: 'Contact Us',
      build: () => const SurveysScreen(),
    ),
    (
      destination: MenuDestination.accessibilitySettings,
      icon: Icons.accessibility_new,
      label: 'Accessibility Settings',
      build: () => const AccessibilitySettingsScreen(),
    ),
    (
      destination: MenuDestination.aboutUs,
      icon: Icons.person_pin_outlined,
      label: 'About Us',
      build: () => const AboutUsScreen(),
    ),
  ];

  /// Account actions shown to signed-in admins.
  static final List<_PageEntry> _adminPages = [
    (
      destination: MenuDestination.changePassword,
      icon: Icons.password,
      label: 'Change Password',
      build: () => const ChangePasswordScreen(),
    ),
  ];

  /// Account actions shown to everyone else.
  static final List<_PageEntry> _guestPages = [
    (
      destination: MenuDestination.login,
      icon: Icons.person_3_outlined,
      label: 'Administrator Login',
      build: () => const LoginScreen(),
    ),
  ];

  /// Renders [pages] as drawer tiles, with the dividers used between entries.
  ///
  /// Each tile gets its label, icon, destination and screen from the same
  /// record so they always stay in sync.
  List<Widget> _pageTiles(
    AccessibilityColors colors,
    List<_PageEntry> pages, {
    bool leadingDivider = true,
  }) {
    return [
      if (leadingDivider) const Divider(),
      for (var i = 0; i < pages.length; i++) ...[
        if (i > 0) const Divider(),
        _drawerTile(
          colors: colors,
          icon: pages[i].icon,
          label: pages[i].label,
          isCurrent: widget.currentDestination == pages[i].destination,
          onTap: () => _selectDestination(
            pages[i].destination,
            (_) => pages[i].build(),
          ),
        ),
      ],
    ];
  }

  Widget _drawerTile({
    required AccessibilityColors colors,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isCurrent = false,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      textColor: colors.onPrimary,
      iconColor: isCurrent ? colors.onPrimary : colors.menuIcon,
      selected: isCurrent,
      selectedColor: colors.onPrimary,
      selectedTileColor: colors.onPrimary.withValues(alpha: 0.16),
      onTap: onTap,
    );
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

    if (widget.showBackButton) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: BackButton(onPressed: () => Navigator.maybePop(context)),
          actions: widget.actions,
        ),
        body: widget.body,
      );
    }

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
          tooltip: _drawerOpen
              ? 'Close navigation menu'
              : 'Open navigation menu',
          onPressed: _toggleDrawer,
        ),
        actions: widget.actions,
      ),
      body: Stack(
        children: [
          ExcludeSemantics(
            excluding: _drawerOpen,
            child: ExcludeFocus(excluding: _drawerOpen, child: widget.body),
          ),
          ExcludeSemantics(
            child: IgnorePointer(
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
          ),
          AnimatedPositioned(
            duration: drawerDuration,
            left: _drawerOpen ? 0 : -280,
            top: 0,
            bottom: 0,
            width: 280,
            child: ExcludeSemantics(
              excluding: !_drawerOpen,
              child: ExcludeFocus(
                excluding: !_drawerOpen,
                child: Material(
                  elevation: _drawerOpen ? 16 : 0,
                  color: colors.primary,
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Destinations follow the product's navigation
                          // order: main pages first, then settings and account
                          // actions at the bottom.
                          const Divider(),
                          _drawerTile(
                            colors: colors,
                            icon: Icons.waving_hand_sharp,
                            label: 'Welcome',
                            isCurrent:
                                widget.currentDestination ==
                                MenuDestination.welcome,
                            onTap: _goHome,
                          ),
                          ..._pageTiles(colors, _mainPages),
                          const Divider(),
                          _drawerTile(
                            colors: colors,
                            icon: Icons.work_outline,
                            label: 'Job Opportunities',
                            onTap: _openJobOpportunities,
                          ),

                          ..._pageTiles(colors, _secondaryPages),
                          const Divider(),

                          if (isAdmin) ...[
                            const ListTile(
                              title: Text(
                                "ADMIN PANEL",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            ..._pageTiles(
                              colors,
                              _adminPages,
                              leadingDivider: false,
                            ),
                          ],

                          if (!isAdmin)
                            ..._pageTiles(
                              colors,
                              _guestPages,
                              leadingDivider: false,
                            ),

                          if (isAdmin)
                            ListTile(
                              leading: const Icon(Icons.logout),
                              title: const Text('Logout'),
                              textColor: colors.onPrimary,
                              iconColor: colors.menuIcon,
                              onTap: () async {
                                // Clears the saved login too, so the admin
                                // controls stay hidden after a restart (P1-217).
                                _closeDrawer();
                                await AuthService.logout();
                                if (!context.mounted) return;

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WelcomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          const Divider(),
                        ],
                      ),
                    ),
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

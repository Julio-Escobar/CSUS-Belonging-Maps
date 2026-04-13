import 'package:flutter/material.dart';
import 'login_screen.dart';
import '/widgets/hamburger_menu.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

//1 Second stop

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // 1 second stop
  }

  @override
  Widget build(BuildContext context) {
    return HamburgerMenu(
      body: Scaffold(
        backgroundColor: const Color(0xFF2F5F3E), // Dark green background
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 100), // Space from top
            Center(
              child: Column(
                children: [
                  // Logo
                  Image.asset('assets/logo.png', width: 200, height: 200),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

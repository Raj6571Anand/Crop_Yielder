import 'dart:async';
import 'package:flutter/material.dart';
import 'home_page.dart'; // Import your main home page

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Optional: Add a subtle fade-in effect
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Timer to navigate to the home page after 3 seconds
    Timer(const Duration(seconds: 3), () {
      // Use pushReplacement so the user can't press "back" to return to the splash screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AdvisorHomePage()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ensure background is white to match the image asset
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            // Display the asset image you saved earlier
            child: Image.asset(
              'assets/splash_image.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
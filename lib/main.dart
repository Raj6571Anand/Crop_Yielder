import 'package:flutter/material.dart';
import 'theme.dart';
// import 'home_page.dart'; // <-- Remove or comment out this import
import 'splash_screen.dart'; // <-- Add this import

void main() {
  runApp(const CropOptimizerApp());
}

class CropOptimizerApp extends StatelessWidget {
  const CropOptimizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(Brightness.light),
      // CHANGE THIS LINE: Set home to SplashScreen instead of AdvisorHomePage
      home: const SplashScreen(),
    );
  }
}
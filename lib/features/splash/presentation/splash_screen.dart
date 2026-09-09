import 'package:flutter/material.dart';

/// Screen 1: Splash Screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement splash logo animation, auth check, and navigation
    return const Scaffold(
      body: Center(
        child: Text('BAHHAR Splash Screen'),
      ),
    );
  }
}

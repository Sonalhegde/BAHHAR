import 'package:flutter/material.dart';

/// Screen 3: Home Dashboard Screen
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Assemble opportunity gauge, species chips, and recommended hotspot list
    return Scaffold(
      appBar: AppBar(
        title: const Text('BAHHAR Home'),
      ),
      body: const Center(
        child: Text('Home Dashboard Screen'),
      ),
    );
  }
}

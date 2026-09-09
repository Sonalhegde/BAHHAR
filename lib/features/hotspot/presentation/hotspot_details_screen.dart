import 'package:flutter/material.dart';

/// Screen 5: Hotspot Details Screen
class HotspotDetailsScreen extends StatelessWidget {
  const HotspotDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement hotspot details (coordinates, depth, sea temp, best bite window)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotspot Details'),
      ),
      body: const Center(
        child: Text('Hotspot Details Screen'),
      ),
    );
  }
}

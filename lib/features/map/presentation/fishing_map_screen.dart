import 'package:flutter/material.dart';

/// Screen 4: Fishing Map Screen
class FishingMapScreen extends StatelessWidget {
  const FishingMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement Google Maps with layer toggles, species chips, and probability markers
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing Map'),
      ),
      body: const Center(
        child: Text('Fishing Map Screen'),
      ),
    );
  }
}

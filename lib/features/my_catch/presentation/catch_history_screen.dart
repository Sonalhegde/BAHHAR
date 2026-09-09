import 'package:flutter/material.dart';

/// Screen 9: Catch History Screen
class CatchHistoryScreen extends StatelessWidget {
  const CatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Display chronological catch log with photos, statistics, and Firestore stream
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catch History'),
      ),
      body: const Center(
        child: Text('Catch History Screen'),
      ),
    );
  }
}

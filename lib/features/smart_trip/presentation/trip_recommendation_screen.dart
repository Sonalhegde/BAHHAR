import 'package:flutter/material.dart';

/// Screen 7: Trip Recommendation Screen
class TripRecommendationScreen extends StatelessWidget {
  const TripRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Display ML-recommended waypoints, optimal departure window, and estimated fuel/catch rate
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Recommendation'),
      ),
      body: const Center(
        child: Text('Trip Recommendation Screen'),
      ),
    );
  }
}

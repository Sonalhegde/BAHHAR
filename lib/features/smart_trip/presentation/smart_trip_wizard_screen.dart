import 'package:flutter/material.dart';

/// Screen 6: Smart Trip Wizard Screen (4-step: Species, Starting Point, When, Review)
class SmartTripWizardScreen extends StatelessWidget {
  const SmartTripWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement 4-step wizard (step 1: species, step 2: starting port/GPS, step 3: date/time, step 4: review)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Trip Wizard'),
      ),
      body: const Center(
        child: Text('Smart Trip Wizard Screen'),
      ),
    );
  }
}

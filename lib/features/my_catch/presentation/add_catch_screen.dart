import 'package:flutter/material.dart';

/// Screen 8: Add New Catch Screen
class AddCatchScreen extends StatelessWidget {
  const AddCatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement photo capture, auto-GPS tag, species selector, weight, and storage upload
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Catch'),
      ),
      body: const Center(
        child: Text('Add New Catch Screen'),
      ),
    );
  }
}

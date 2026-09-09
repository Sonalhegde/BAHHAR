import 'package:flutter/material.dart';
import 'widgets/language_switcher_widget.dart';

/// Screen 10: Profile Screen (Language switcher, Boat info, Subscription, Logout)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement boat specs, subscription status, notification settings, and logout
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsetsDirectional.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            LanguageSwitcherWidget(),
          ],
        ),
      ),
    );
  }
}

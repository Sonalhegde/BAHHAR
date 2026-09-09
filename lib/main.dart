import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase placeholder
  await FirebaseService.init();

  runApp(
    const ProviderScope(
      child: BahharApp(),
    ),
  );
}

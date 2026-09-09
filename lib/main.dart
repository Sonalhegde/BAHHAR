import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase services placeholder
  await FirebaseService.init();

  runApp(const BahharApp());
}

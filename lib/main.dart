import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase placeholder
  await FirebaseService.init();

  // Restore language / port / units before the first frame, so the app opens in the
  // language it was left in rather than flashing English first. A platform without a
  // preferences backend (a desktop run, a test host) starts on defaults instead.
  try {
    await PrefsService.init();
  } catch (e) {
    debugPrint('BAHHAR: settings will not persist across restarts ($e).');
  }

  // FCM handlers. Inert unless Firebase is configured, so the demo build and the
  // tests never touch a plugin with no platform backing. A plugin that is present
  // but unusable on this device (no Google Play services, no APNs key) is the same
  // story: push is off, the app is not.
  try {
    await NotificationService.init();
    await NotificationService.subscribeRegion(PrefsService.getGovernorate());
  } catch (e) {
    debugPrint('BAHHAR: push notifications are unavailable ($e).');
  }

  runApp(
    const ProviderScope(
      child: BahharApp(),
    ),
  );
}

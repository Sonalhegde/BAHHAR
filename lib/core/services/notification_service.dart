import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';

/// One pushed alert, stripped of the Firebase type so the UI never imports it.
class BahharPush {
  final String title;
  final String body;

  /// `sea_state`, `licence_expiry`, `hotspot`, … — the key the app routes on.
  final String category;

  const BahharPush({
    required this.title,
    required this.body,
    this.category = 'general',
  });

  factory BahharPush.from(RemoteMessage message) {
    final data = message.data;
    return BahharPush(
      title: message.notification?.title ??
          data['title'] as String? ??
          // A push with no title is still a signal worth surfacing: the payload said
          // something arrived. Silence would be the app dropping a warning.
          'BAHHAR alert',
      body: message.notification?.body ?? data['body'] as String? ?? '',
      category: data['category'] as String? ?? 'general',
    );
  }
}

/// Delivery handler for a message that woke the app from the background.
///
/// Top-level and `vm:entry-point`-annotated because Firebase runs it in its own
/// isolate, where nothing from the app's object graph exists. It may only log: the
/// notification itself is rendered by the system tray, and a plugin call from here
/// would be reaching back into an app that is not running.
@pragma('vm:entry-point')
Future<void> bahharOnBackgroundMessage(RemoteMessage message) async {
  debugPrint(
    'BAHHAR push (background): ${message.data['category'] ?? 'general'}',
  );
}

/// FCM wiring: permission, token, region topics, and the in-app message stream.
///
/// What this does NOT do is show a banner while the app is open. Rendering a
/// foreground notification needs a local-notification plugin that is not a
/// dependency here, so an arrived message is pushed onto [messages] and the Home
/// dashboard draws it with the app's own alert styling. Adding the plugin later
/// changes how a message is displayed, not this contract.
///
/// Every entry point is inert when Firebase is not configured, so the demo build
/// and `flutter test` never touch a plugin that has no platform backing.
class NotificationService {
  static final StreamController<BahharPush> _controller =
      StreamController<BahharPush>.broadcast();

  static Stream<BahharPush> get messages => _controller.stream;

  /// The device's FCM token, once one exists. Null means "not registered", which the
  /// profile screen reads as no push delivery rather than as working push.
  static String? get token => _token;

  static String? _token;

  static bool _started = false;
  static final List<StreamSubscription<dynamic>> _subs = [];

  /// Registers the handlers. Safe to call more than once and safe to call when
  /// Firebase is absent — it simply does nothing in that case.
  static Future<void> init() async {
    if (!FirebaseService.isConfigured || _started) return;
    _started = true;
    try {
      final messaging = FirebaseMessaging.instance;

      // Permission is asked for, not assumed: iOS will not deliver anything until the
      // fisherman says yes, and the answer is theirs to give.
      final settings = await messaging.requestPermission();
      debugPrint('BAHHAR push authorisation: ${settings.authorizationStatus.name}');

      FirebaseMessaging.onBackgroundMessage(bahharOnBackgroundMessage);

      _token = await messaging.getToken();
      debugPrint('BAHHAR push token acquired: ${_token != null}');

      // A token rotates without the app being reopened; the backend has to be told.
      _subs.add(messaging.onTokenRefresh.listen((t) => _token = t));

      // Open on a notification: the message arrives here and the app decides what
      // screen to show, so routing stays in the app, not in the push payload.
      _subs.add(
        FirebaseMessaging.onMessage.listen((m) => _controller.add(BahharPush.from(m))),
      );
      _subs.add(
        FirebaseMessaging.onMessageOpenedApp
            .listen((m) => _controller.add(BahharPush.from(m))),
      );

      // Tap that started the app cold: nothing is listening yet, so report it once.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _controller.add(BahharPush.from(initial));
    } on FirebaseException catch (e) {
      // A missing GMS/apns configuration is a platform fact, not a bug to chase; the
      // rest of the app works without push.
      debugPrint('BAHHAR: push unavailable (${e.code}).');
      _started = false;
    }
  }

  /// Subscribes the device to alerts for one governorate. Topic names are lowercase
  /// ASCII so a non-Latin region label cannot produce a topic the server will never
  /// publish to.
  static Future<void> subscribeRegion(String governorate) async {
    if (!FirebaseService.isConfigured) return;
    final topic = governorate.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    if (topic.isEmpty) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic('region-$topic');
    } catch (e) {
      debugPrint('BAHHAR: could not subscribe to region-$topic ($e).');
    }
  }

  static Future<void> unsubscribeRegion(String governorate) async {
    if (!FirebaseService.isConfigured) return;
    final topic = governorate.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    if (topic.isEmpty) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('region-$topic');
    } catch (_) {
      // Unsubscribing is best-effort; the server stops pushing to a token it cannot
      // reach anyway.
    }
  }

  /// Releases the handler subscriptions. The broadcast controller outlives them, since
  /// anything still listening to [messages] belongs to a widget being torn down too.
  static void disposeListeners() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _started = false;
  }
}

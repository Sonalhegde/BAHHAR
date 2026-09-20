import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';

/// The most recent push notification, for the alert strip on the Home dashboard.
///
/// The underlying stream is a broadcast stream, so opening and closing a screen does
/// not consume a message another screen might want. It also means a message that
/// arrived while nothing was listening is not replayed here — the system-tray copy is
/// what survives that, which is why this is a strip and not the record of alerts.
final pushedAlertProvider = StreamProvider<BahharPush>((ref) {
  return NotificationService.messages;
});

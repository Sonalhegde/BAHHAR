import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../../shared/widgets/alert_banner.dart';

final notificationsSeed = [
  AppNotification(
    id: 'n1',
    title: 'High Swell & Wave Advisory',
    message: 'Significant wave heights of 2.1m detected off Ras Al Hadd. Exercise caution when navigating small skiffs.',
    timestamp: DateTime.now().subtract(const Duration(minutes: 42)),
    category: NotificationCategory.marine,
    severity: AlertSeverity.warning,
  ),
  AppNotification(
    id: 'n2',
    title: 'Kingfish Strike Window Open',
    message: 'Optimal morning tide and 27.2°C water temperature confirmed at Fahal Island for the next 3 hours.',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    category: NotificationCategory.trip,
    severity: AlertSeverity.info,
  ),
  AppNotification(
    id: 'n3',
    title: 'Marine Conservation Decree Update',
    message: 'Annual seasonal restriction now active for Daymaniyat Islands inner coral reefs. Special permits required.',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    category: NotificationCategory.regulatory,
    severity: AlertSeverity.danger,
  ),
];

final notificationsProvider = Provider<List<AppNotification>>((ref) {
  return notificationsSeed;
});

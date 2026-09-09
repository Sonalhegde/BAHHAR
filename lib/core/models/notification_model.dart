import '../../shared/widgets/alert_banner.dart';

enum NotificationCategory {
  weather,
  marine,
  trip,
  regulatory,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationCategory category;
  final AlertSeverity severity;
  final String? route;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    this.severity = AlertSeverity.info,
    this.route,
  });
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AlertSeverity {
  info,
  warning,
  danger,
}

/// AlertBanner (Section 4.4)
/// Dismissible banner for weather, marine, or regulatory notifications
class AlertBanner extends StatelessWidget {
  final String title;
  final String message;
  final AlertSeverity severity;
  final VoidCallback? onDismiss;

  const AlertBanner({
    super.key,
    required this.title,
    required this.message,
    this.severity = AlertSeverity.info,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color iconColor;
    IconData icon;

    switch (severity) {
      case AlertSeverity.info:
        bg = AppColors.oceanBlue.withOpacity(0.12);
        border = AppColors.oceanBlue;
        iconColor = AppColors.oceanBlue;
        icon = Icons.info_outline;
        break;
      case AlertSeverity.warning:
        bg = AppColors.sandGold.withOpacity(0.15);
        border = AppColors.sandGold;
        iconColor = const Color(0xFFB45309);
        icon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.danger:
        bg = AppColors.coralRed.withOpacity(0.15);
        border = AppColors.coralRed;
        iconColor = AppColors.coralRed;
        icon = Icons.dangerous_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withOpacity(0.4), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.captionMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : AppColors.deepNavyText,
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

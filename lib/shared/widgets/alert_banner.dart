import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AlertSeverity { info, warning, danger }

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
    Color bg, border, iconColor;
    IconData icon;

    switch (severity) {
      case AlertSeverity.danger:
        bg = AppColors.signalAlert.withValues(alpha: 0.06);
        border = AppColors.signalAlert.withValues(alpha: 0.2);
        iconColor = AppColors.signalAlert;
        icon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.warning:
        bg = AppColors.signalCaution.withValues(alpha: 0.08);
        border = AppColors.signalCaution.withValues(alpha: 0.2);
        iconColor = AppColors.signalCaution;
        icon = Icons.info_outline_rounded;
        break;
      case AlertSeverity.info:
        bg = AppColors.accentNavy.withValues(alpha: 0.06);
        border = AppColors.accentNavy.withValues(alpha: 0.15);
        iconColor = AppColors.accentNavy;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium.copyWith(color: iconColor)),
                const SizedBox(height: 2),
                Text(message, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }
}

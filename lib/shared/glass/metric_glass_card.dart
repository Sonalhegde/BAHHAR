import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/glass_tokens.dart';
import 'glass_container.dart';

class MetricGlassCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtext;
  final IconData? icon;
  final bool isAlert;
  final Color? accentColor;

  const MetricGlassCard({
    super.key,
    required this.label,
    required this.value,
    this.subtext,
    this.icon,
    this.isAlert = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? (isAlert ? AppColors.signalAlert : AppColors.cyanAccent);

    return GlassContainer(
      level: GlassLevel.standard,
      borderRadius: GlassTokens.radiusMedium,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.sectionHeader.copyWith(
                  fontSize: 10,
                  color: isAlert ? AppColors.signalAlert : AppColors.cyanBright,
                  letterSpacing: 0.8,
                ),
              ),
              if (icon != null)
                Icon(icon, size: 15, color: effectiveAccent),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.subhead.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isAlert ? AppColors.signalAlert : AppColors.textPrimary,
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 3),
            Text(
              subtext!,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

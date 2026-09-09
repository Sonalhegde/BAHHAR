import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// ConditionStatChip (Section 4.4)
/// Icon + Tabular Value + Unit Label for Wind, Wave, Sea Temp, Tide
class ConditionStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? subLabel;
  final Color? iconColor;

  const ConditionStatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.subLabel,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.borderGray,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor ?? AppColors.oceanBlue,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.micro.copyWith(
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.deepNavyText,
            ),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              subLabel!,
              style: AppTextStyles.micro.copyWith(
                color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

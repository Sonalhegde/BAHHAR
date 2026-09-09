import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ConditionStatChip extends StatelessWidget {
  final String label;
  final String value;
  final String? subtext;
  final bool isWarning;

  const ConditionStatChip({
    super.key,
    required this.label,
    required this.value,
    this.subtext,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.signalAlert.withValues(alpha: 0.06)
            : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarning
              ? AppColors.signalAlert.withValues(alpha: 0.2)
              : AppColors.borderHairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isWarning ? AppColors.signalAlert : AppColors.textPrimary,
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(subtext!, style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/glass_tokens.dart';
import '../glass/glass_container.dart';

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
    final accent = isWarning ? AppColors.signalAlert : AppColors.cyanAccent;

    return GlassContainer(
      level: GlassLevel.standard,
      borderRadius: GlassTokens.radiusMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: isWarning ? AppColors.signalAlert : AppColors.cyanAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isWarning ? AppColors.signalAlert : Colors.white,
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              subtext!,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

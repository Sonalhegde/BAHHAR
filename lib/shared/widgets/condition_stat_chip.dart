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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning
              ? AppColors.signalAlert.withValues(alpha: 0.4)
              : const Color(0xFFD3E4F8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: isWarning ? AppColors.signalAlert : AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isWarning ? AppColors.signalAlert : AppColors.oceanNavy,
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              subtext!,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

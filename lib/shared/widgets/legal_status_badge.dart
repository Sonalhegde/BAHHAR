import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class LegalStatusBadge extends StatelessWidget {
  final bool isRestricted;

  const LegalStatusBadge({super.key, required this.isRestricted});

  @override
  Widget build(BuildContext context) {
    final color = isRestricted ? AppColors.legalRestricted : AppColors.signalGood;
    final label = isRestricted ? 'Marine Reserve' : 'Open Waters';
    final icon = isRestricted ? Icons.shield_outlined : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

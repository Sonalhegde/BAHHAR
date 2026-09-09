import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum LegalStatus {
  permitted,
  restricted,
  protected,
}

/// Accessible LegalStatusBadge (Section 4.4)
/// Uses both color and distinct shape/icon so it is never reliant on color alone.
/// Uses distinct violet/purple tones for restricted/protected zones so it is NEVER
/// confused with low-probability red.
class LegalStatusBadge extends StatelessWidget {
  final LegalStatus status;
  final bool compact;

  const LegalStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String text;
    final Color badgeColor;
    final Color textColor;

    switch (status) {
      case LegalStatus.permitted:
        icon = Icons.check_circle_outline;
        text = 'Permitted';
        badgeColor = AppColors.permittedZone.withOpacity(0.14);
        textColor = const Color(0xFF059669);
        break;
      case LegalStatus.restricted:
        icon = Icons.gpp_maybe_outlined;
        text = 'Restricted';
        badgeColor = AppColors.restrictedZone.withOpacity(0.18);
        textColor = const Color(0xFF7C3AED);
        break;
      case LegalStatus.protected:
        icon = Icons.shield_outlined;
        text = 'Protected Reserve';
        badgeColor = AppColors.protectedArea.withOpacity(0.18);
        textColor = const Color(0xFF5B21B6);
        break;
    }

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: (compact ? AppTextStyles.micro : AppTextStyles.captionMedium).copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

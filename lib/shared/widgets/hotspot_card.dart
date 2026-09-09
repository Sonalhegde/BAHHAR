import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'legal_status_badge.dart';

/// HotspotCard (Section 4.4)
/// Displays hotspot name, fishing probability badge, nautical distance,
/// target species, and regulatory status.
class HotspotCard extends StatelessWidget {
  final String name;
  final int probability;
  final double distanceNm; // Nautical miles
  final String primarySpecies;
  final LegalStatus legalStatus;
  final VoidCallback? onTap;

  const HotspotCard({
    super.key,
    required this.name,
    required this.probability,
    required this.distanceNm,
    required this.primarySpecies,
    this.legalStatus = LegalStatus.permitted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final probColor = AppColors.getProbabilityColor(probability);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 260,
        padding: const EdgeInsetsDirectional.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightSurface : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.nightBorder : AppColors.borderGray,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.h2.copyWith(
                      fontSize: 17,
                      color: isDark ? Colors.white : AppColors.deepNavyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: probColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: probColor, width: 1),
                  ),
                  child: Text(
                    '$probability%',
                    style: AppTextStyles.captionMedium.copyWith(
                      color: probColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.navigation_outlined, size: 14, color: AppColors.oceanBlue),
                const SizedBox(width: 4),
                Text(
                  '${distanceNm.toStringAsFixed(1)} nm offshore',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phishing_outlined, size: 14, color: AppColors.aquaTeal),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    primarySpecies,
                    style: AppTextStyles.captionMedium.copyWith(
                      color: isDark ? Colors.white : AppColors.deepNavyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LegalStatusBadge(status: legalStatus, compact: true),
          ],
        ),
      ),
    );
  }
}

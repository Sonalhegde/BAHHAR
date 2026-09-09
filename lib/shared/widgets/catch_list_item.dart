import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// CatchListItem (Section 4.4)
/// Photo thumbnail, species, weight (kg), location, and date
class CatchListItem extends StatelessWidget {
  final String speciesName;
  final double weightKg;
  final double? lengthCm;
  final String locationName;
  final DateTime caughtAt;
  final String? photoUrl;
  final VoidCallback? onTap;

  const CatchListItem({
    super.key,
    required this.speciesName,
    required this.weightKg,
    this.lengthCm,
    required this.locationName,
    required this.caughtAt,
    this.photoUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsetsDirectional.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightSurface : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.nightBorder : AppColors.borderGray,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightBorder : AppColors.mistGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.phishing, size: 30, color: AppColors.oceanBlue),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speciesName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.deepNavyText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${weightKg.toStringAsFixed(1)} kg',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.aquaTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (lengthCm != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '•  ${lengthCm!.toStringAsFixed(0)} cm',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.sandGold),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationName,
                          style: AppTextStyles.micro.copyWith(
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

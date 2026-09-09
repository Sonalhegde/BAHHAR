import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/models/hotspot_model.dart';
import 'legal_status_badge.dart';

class HotspotCard extends StatelessWidget {
  final HotspotModel hotspot;
  final VoidCallback? onTap;

  const HotspotCard({super.key, required this.hotspot, this.onTap});

  @override
  Widget build(BuildContext context) {
    final probColor = AppColors.getProbabilityColor(hotspot.rating);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfacePure,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: probColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: probColor.withValues(alpha: 0.25)),
              ),
              alignment: Alignment.center,
              child: Text(
                '${hotspot.rating}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: probColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(hotspot.name, style: AppTextStyles.cardTitle),
                      LegalStatusBadge(isRestricted: hotspot.isProtectedReserve),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${hotspot.governorate} • ${hotspot.depthMeters}m • ${hotspot.distanceNmi} nmi',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: hotspot.primarySpecies.take(3).map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(s, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

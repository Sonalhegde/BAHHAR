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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD6E6F7), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score Badge
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: probColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: probColor.withValues(alpha: 0.35), width: 1.2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${hotspot.rating}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
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
                      Expanded(
                        child: Text(
                          hotspot.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.oceanNavy,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      LegalStatusBadge(isRestricted: hotspot.isProtectedReserve),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${hotspot.governorate} • ${hotspot.depthMeters}m depth • ${hotspot.distanceNmi} nmi',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: hotspot.primarySpecies.take(3).map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlueLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
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

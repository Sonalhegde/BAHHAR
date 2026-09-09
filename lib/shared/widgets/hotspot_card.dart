import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/glass_tokens.dart';
import '../../core/models/hotspot_model.dart';
import '../glass/glass_container.dart';
import 'legal_status_badge.dart';

class HotspotCard extends StatelessWidget {
  final HotspotModel hotspot;
  final VoidCallback? onTap;

  const HotspotCard({super.key, required this.hotspot, this.onTap});

  @override
  Widget build(BuildContext context) {
    final probColor = AppColors.getProbabilityColor(hotspot.rating);

    return GlassContainer(
      level: GlassLevel.standard,
      borderRadius: GlassTokens.radiusMedium,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score badge with glowing glass frame
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: probColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
              border: Border.all(color: probColor.withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: probColor.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${hotspot.rating}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Colors.white,
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
                        style: AppTextStyles.cardTitle,
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
                      color: const Color(0xFF0F2C46).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(GlassTokens.radiusSmall - 2),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Text(
                      s,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.cyanAccent,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

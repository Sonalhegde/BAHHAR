import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/models/hotspot_model.dart';
import 'legal_status_badge.dart';

class HotspotCard extends StatefulWidget {
  final HotspotModel hotspot;
  final VoidCallback? onTap;

  const HotspotCard({super.key, required this.hotspot, this.onTap});

  @override
  State<HotspotCard> createState() => _HotspotCardState();
}

class _HotspotCardState extends State<HotspotCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hotspot = widget.hotspot;
    final probColor = AppColors.getProbabilityColor(hotspot.probability);
    final isProtected = hotspot.legalStatus != LegalStatus.permitted;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pressed ? probColor.withValues(alpha: 0.35) : const Color(0xFFD6E6F7),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: _pressed ? 0.10 : 0.05),
                blurRadius: _pressed ? 18 : 12,
                offset: Offset(0, _pressed ? 6 : 3),
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
                '${hotspot.probability}',
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
                      LegalStatusBadge(isRestricted: isProtected),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${hotspot.region} • ${hotspot.depthMeters}m depth • ${hotspot.distanceNm} nmi',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: hotspot.targetSpecies.take(3).map((s) => Container(
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
      ),
    );
  }
}

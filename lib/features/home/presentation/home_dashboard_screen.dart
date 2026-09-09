import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/marine_provider.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/glass/glass_card.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';
import '../../../shared/widgets/condition_stat_chip.dart';
import '../../../shared/widgets/hotspot_card.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marineAsync = ref.watch(currentMarineConditionsProvider);
    final hotspotsAsync = ref.watch(hotspotsListProvider);
    final selectedRegion = ref.watch(selectedGovernorateProvider);
    final isArabic = ref.watch(isArabicProvider);

    return MarineBackground(
      showHeadlandSilhouettes: true,
      child: CustomScrollView(
        slivers: [
          // Coastal Header Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'محافظة مسقط • سلطنة عُمان' : '$selectedRegion Governorate'.toUpperCase(),
                        style: AppTextStyles.sectionHeader.copyWith(color: AppColors.primaryBlue),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: const [
                          Icon(Icons.location_on, size: 16, color: AppColors.primaryBlue),
                          SizedBox(width: 4),
                          Text(
                            'Mutrah Harbor (مطرح)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.oceanNavy),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.oceanNavy),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
                        border: Border.all(color: const Color(0xFFD6E6F7)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_outlined, size: 20, color: AppColors.oceanNavy),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.signalAlert,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hero Score Command Panel
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const FishingScoreGauge(score: 87, size: 86),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'مؤشر الصيد اليومي' : 'DAILY FISHING INDEX',
                          style: AppTextStyles.sectionHeader.copyWith(color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isArabic ? 'نافذة مدية استثنائية' : 'Exceptional Solunar Window',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.oceanNavy,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isArabic
                              ? 'ذروة نشاط الصيد: 05:15 - 08:30 ص'
                              : 'Dawn Slack Water: 05:15 - 08:30 AM',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live Marine Conditions Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'بيانات الأرصاد البحرية المباشرة' : 'LIVE MARINE CONDITIONS',
                    style: AppTextStyles.sectionHeader.copyWith(color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 8),
                  marineAsync.when(
                    data: (conditions) => Row(
                      children: [
                        Expanded(
                          child: ConditionStatChip(
                            label: isArabic ? 'ارتفاع الموج' : 'WAVE HEIGHT',
                            value: '${conditions.waveHeightMeters}m',
                            subtext: conditions.waveDirection,
                            isWarning: conditions.waveHeightMeters > 1.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ConditionStatChip(
                            label: isArabic ? 'سرعة الرياح' : 'WIND SPEED',
                            value: '${conditions.windSpeedKnots}kt',
                            subtext: conditions.windDirection,
                            isWarning: conditions.windSpeedKnots > 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ConditionStatChip(
                            label: isArabic ? 'حرارة البحر' : 'WATER TEMP',
                            value: '${conditions.waterTempCelsius}°C',
                            subtext: 'SST Normal',
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ),

          // Hotspots Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'أبرز المواقع المصنفة اليوم' : 'TOP RANKED SPOTS TODAY',
                    style: AppTextStyles.sectionHeader.copyWith(color: AppColors.primaryBlue),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/map'),
                    child: Text(
                      isArabic ? 'عرض الخريطة ←' : 'Nautical Chart →',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hotspot List
          hotspotsAsync.when(
            data: (hotspots) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final spot = hotspots[index];
                  return HotspotCard(
                    hotspot: spot,
                    onTap: () => context.push('/hotspots/${spot.id}'),
                  );
                },
                childCount: hotspots.length,
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                ),
              ),
            ),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

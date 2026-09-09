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
      child: CustomScrollView(
        slivers: [
          // Glass Command Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'محافظة مسقط • سلطنة عُمان' : '$selectedRegion Governorate'.toUpperCase(),
                        style: AppTextStyles.sectionHeader,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            isArabic ? 'ميناء مطرح (مطرح)' : 'Mutrah Harbor',
                            style: AppTextStyles.subhead.copyWith(fontSize: 19, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.cyanAccent),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: GlassContainer(
                      level: GlassLevel.standard,
                      borderRadius: GlassTokens.radiusSmall,
                      padding: const EdgeInsets.all(9),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_outlined, size: 20, color: Colors.white),
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

          // Hero Score Command Panel (Glassmorphic Gauge)
          SliverToBoxAdapter(
            child: ElevatedGlassCard(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              glowColor: AppColors.cyanAccent,
              child: Row(
                children: [
                  const FishingScoreGauge(score: 87, size: 86),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'مؤشر الصيد اليومي' : 'DAILY FISHING INDEX',
                          style: AppTextStyles.sectionHeader,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isArabic ? 'نافذة مدية استثنائية' : 'Exceptional Solunar Window',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                    style: AppTextStyles.sectionHeader,
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyanAccent),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ),

          // Hotspots Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'أبرز المواقع المصنفة اليوم' : 'TOP RANKED SPOTS TODAY',
                    style: AppTextStyles.sectionHeader,
                  ),
                  GestureDetector(
                    onTap: () => context.go('/map'),
                    child: Text(
                      isArabic ? 'عرض الخريطة ←' : 'View Nautical Chart →',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.cyanAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hotspots List
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyanAccent),
                ),
              ),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: Center(child: Text('Failed to load hotspots', style: TextStyle(color: Colors.white70))),
            ),
          ),

          // Extra bottom padding for floating navigation bar
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

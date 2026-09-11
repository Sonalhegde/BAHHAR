import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/marine_provider.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';
import '../../../shared/widgets/condition_stat_chip.dart';
import '../../../shared/widgets/hotspot_card.dart';
import '../../../shared/widgets/skeleton.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marineAsync = ref.watch(marineConditionsProvider);
    final hotspotsAsync = ref.watch(hotspotsProvider);
    final isOfflineDemo = ref.watch(offlineDataModeProvider);
    final selectedRegion = ref.watch(selectedGovernorateProvider);
    final isArabic = ref.watch(isArabicProvider);

    // Daily fishing index = best hotspot probability from the loaded catalogue.
    final hotspots = hotspotsAsync.valueOrNull ?? const [];
    final dailyIndex = hotspots.isEmpty
        ? 0
        : hotspots
            .reduce((a, b) =>
                a.probability >= b.probability ? a : b)
            .probability;

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
                        isArabic
                            ? 'محافظة مسقط • سلطنة عُمان'
                            : '$selectedRegion Governorate'.toUpperCase(),
                        style: AppTextStyles.sectionHeader
                            .copyWith(color: AppColors.primaryBlue),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: AppColors.primaryBlue),
                          SizedBox(width: 4),
                          Text(
                            'Mutrah Harbor (مطرح)',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.oceanNavy),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18, color: AppColors.oceanNavy),
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
                        borderRadius: BorderRadius.circular(
                            GlassTokens.radiusMedium),
                        border:
                            Border.all(color: const Color(0xFFD6E6F7)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A)
                                .withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_outlined,
                              size: 20, color: AppColors.oceanNavy),
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

          // Offline demo banner (visible, not silent)
          if (isOfflineDemo && !FirebaseService.isConfigured)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.signalCautionBg,
                  borderRadius: BorderRadius.circular(
                      GlassTokens.radiusSmall),
                  border: Border.all(
                      color: AppColors.signalCaution
                          .withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_outlined,
                        size: 14, color: AppColors.signalCaution),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'بيانات تجريبية محلية — Firebase غير مُعد'
                            : 'Showing bundled sample data — Firebase '
                                'not configured.',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.signalCaution,
                            fontSize: 11),
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
                border:
                    Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
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
                  FishingScoreGauge(
                      score: hotspots.isEmpty ? 0 : dailyIndex,
                      size: 86),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic
                              ? 'مؤشر الصيد اليومي'
                              : 'DAILY FISHING INDEX',
                          style: AppTextStyles.sectionHeader
                              .copyWith(color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isArabic
                              ? 'نافذة مدية استثنائية'
                              : 'Exceptional Solunar Window',
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
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
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
                    isArabic
                        ? 'بيانات الأرصاد البحرية المباشرة'
                        : 'LIVE MARINE CONDITIONS',
                    style: AppTextStyles.sectionHeader
                        .copyWith(color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 8),
                  marineAsync.when(
                    data: (conditions) => Row(
                      children: [
                        Expanded(
                          child: ConditionStatChip(
                            label:
                                isArabic ? 'ارتفاع الموج' : 'WAVE HEIGHT',
                            value: '${conditions.waveHeightM}m',
                            subtext:
                                'Period ${conditions.wavePeriodS}s',
                            isWarning: conditions.waveHeightM > 1.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ConditionStatChip(
                            label:
                                isArabic ? 'سرعة الرياح' : 'WIND SPEED',
                            value: '${conditions.windSpeedKts}kt',
                            subtext:
                                conditions.windDirectionCompass,
                            isWarning: conditions.windSpeedKts > 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ConditionStatChip(
                            label:
                                isArabic ? 'حرارة البحر' : 'WATER TEMP',
                            value:
                                '${conditions.seaTemperatureC}°C',
                            subtext: 'SST Normal',
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Row(
                      children: [
                        Expanded(child: SkeletonBox(height: 64)),
                        SizedBox(width: 8),
                        Expanded(child: SkeletonBox(height: 64)),
                        SizedBox(width: 8),
                        Expanded(child: SkeletonBox(height: 64)),
                      ],
                    ),
                    error: (e, _) => Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.signalAlertBg,
                        borderRadius: BorderRadius.circular(
                            GlassTokens.radiusSmall),
                      ),
                      child: Text(
                        isArabic
                            ? 'تعذر تحميل حالة البحر'
                            : 'Failed to load marine conditions.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.signalAlert),
                      ),
                    ),
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
                    isArabic
                        ? 'أبرز المواقع المصنفة اليوم'
                        : 'TOP RANKED SPOTS TODAY',
                    style: AppTextStyles.sectionHeader
                        .copyWith(color: AppColors.primaryBlue),
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
            data: (spots) => spots.isEmpty
                ? const SliverToBoxAdapter(child: SizedBox(height: 40))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final spot = spots[index];
                        return HotspotCard(
                          hotspot: spot,
                          onTap: () =>
                              context.push('/hotspots/${spot.id}'),
                        );
                      },
                      childCount: spots.length,
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SkeletonCard(),
                    SizedBox(height: 10),
                    SkeletonCard(),
                    SizedBox(height: 10),
                    SkeletonCard(),
                  ],
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.signalAlertBg,
                    borderRadius:
                        BorderRadius.circular(GlassTokens.radiusMedium),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isArabic
                            ? 'تعذر تحميل المواقع: $e'
                            : 'Failed to load hotspots.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.signalAlert),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(hotspotsProvider),
                        child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

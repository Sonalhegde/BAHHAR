import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/marine_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/weather_provider.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/marine_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';
import '../../../shared/widgets/condition_stat_chip.dart';
import '../../../shared/widgets/hotspot_card.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/animations/app_animations.dart';
import 'widgets/weather_card_widget.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marineAsync = ref.watch(marineConditionsProvider);
    final weatherAsync = ref.watch(weatherConditionsProvider);
    final pushed = ref.watch(pushedAlertProvider).valueOrNull;
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
            child: SlideFadeReveal(
              duration: const Duration(milliseconds: 450),
              offsetY: 12,
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
            child: SlideFadeReveal(
              delay: const Duration(milliseconds: 120),
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
          ),

          // Push alert strip: a message that arrived while the app was open. A
          // foreground banner needs a local-notification plugin this app does not
          // carry, so the push surfaces here instead of being swallowed. Dismissing
          // only clears the strip; the tray copy is untouched.
          if (pushed != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.signalCautionBg,
                    borderRadius:
                        BorderRadius.circular(GlassTokens.radiusSmall),
                    border: Border.all(
                        color: AppColors.signalCaution.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          size: 18, color: AppColors.signalCaution),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pushed.title,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.signalCaution,
                              ),
                            ),
                            if (pushed.body.isNotEmpty)
                              Text(
                                pushed.body,
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref.invalidate(pushedAlertProvider),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Live Marine Conditions Grid
          SliverToBoxAdapter(
            child: SlideFadeReveal(
              delay: const Duration(milliseconds: 220),
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
                    data: (conditions) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        const SizedBox(height: 8),
                        // Second row: the three readings a fisherman uses to decide
                        // *where* to go, once wave height and wind have said *whether*.
                        // Wave direction is its own bearing and never borrows the wind
                        // one — off this coast a swell from the SE and a afternoon land
                        // breeze from the NW are a normal morning.
                        Row(
                          children: [
                            Expanded(
                              child: ConditionStatChip(
                                label: isArabic
                                    ? 'اتجاه الموج'
                                    : 'WAVE FROM',
                                value: conditions.waveDirectionCompass,
                                subtext:
                                    'Period ${conditions.wavePeriodS}s',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ConditionStatChip(
                                label: isArabic ? 'التيار' : 'CURRENT',
                                value: '${conditions.currentSpeedKts}kt',
                                subtext: isArabic
                                    ? 'إلى ${conditions.currentSetsToCompass}'
                                    : 'Sets ${conditions.currentSetsToCompass}',
                                // 2 kt is the strong-current threshold the backend bands
                                // on, so the chip and the band cannot disagree.
                                isWarning:
                                    conditions.currentSpeedKts >= 2.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ConditionStatChip(
                                label: isArabic ? 'الرؤية' : 'VISIBILITY',
                                value: conditions.visibilityKm == null
                                    ? '—'
                                    : '${conditions.visibilityKm}km',
                                subtext: conditions.visibilityKm == null
                                    ? (isArabic
                                        ? 'غير متوفرة'
                                        : 'Not reported')
                                    : _visibilityBand(
                                        conditions.visibilityKm!, isArabic),
                              ),
                            ),
                          ],
                        ),
                        if (conditions.seaStateBand != 'unknown') ...[
                          const SizedBox(height: 8),
                          // The server's own verdict, printed as the server words it.
                          // It is the worst single reading, not an average, which is
                          // why it can say "rough sea" beside a calm-looking wave chip.
                          Row(
                            children: [
                              Icon(
                                Icons.waves_rounded,
                                size: 14,
                                color: conditions.isRough
                                    ? AppColors.signalAlert
                                    : AppColors.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _seaStateLabel(conditions.seaStateBand,
                                    isArabic),
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: conditions.isRough
                                      ? AppColors.signalAlert
                                      : AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Offline/stale-cache indicator (Master Build Prompt §9)
                        if (MarineService.isStale(conditions)) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.cloud_off,
                                  size: 13, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  isArabic
                                      ? 'آخر تحديث: ${Formatters.formatTime(conditions.lastUpdated)} — بيانات محفوظة محلياً'
                                      : 'Last updated ${Formatters.formatTime(conditions.lastUpdated)} — showing last known conditions',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textTertiary),
                                ),
                              ),
                            ],
                          ),
                        ],
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
          ),

          // Weather Section — the air above the water, beside the water itself.
          // One card under Ocean Conditions, in the same idiom, because a fisherman
          // reads the day as one glance and not as two screens. The card is its own
          // widget so the three shapes it can take have a test of their own.
          SliverToBoxAdapter(
            child: SlideFadeReveal(
              delay: const Duration(milliseconds: 260),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: WeatherCardWidget(
                  asyncWeather: weatherAsync,
                  isArabic: isArabic,
                ),
              ),
            ),
          ),

          // Hotspots Section Header
          SliverToBoxAdapter(
            child: SlideFadeReveal(
              delay: const Duration(milliseconds: 320),
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
          ),

          // Hotspot List
          hotspotsAsync.when(
            data: (spots) => spots.isEmpty
                ? const SliverToBoxAdapter(child: SizedBox(height: 40))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final spot = spots[index];
                        return SlideFadeReveal.staggered(
                          index: index,
                          child: HotspotCard(
                            hotspot: spot,
                            onTap: () =>
                                context.push('/hotspots/${spot.id}'),
                          ),
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

/// Marine visibility categories, applied to the kilometre figure the backend sends.
/// The words are the conventional mariner's bands; the number is never invented here.
String _visibilityBand(double km, bool isArabic) {
  if (km >= 10) return isArabic ? 'جيدة جداً' : 'Very good';
  if (km >= 4) return isArabic ? 'جيدة' : 'Good';
  if (km >= 1) return isArabic ? 'متوسطة' : 'Moderate';
  return isArabic ? 'منخفضة' : 'Low';
}

/// The server's sea-state band, worded the way the landing page words it.
String _seaStateLabel(String band, bool isArabic) {
  const en = {
    'good': 'Sea state: Good',
    'moderate': 'Sea state: Moderate',
    'rough_sea': 'Sea state: Rough sea',
    'strong_current': 'Sea state: Strong current',
    'high_risk': 'Sea state: High risk',
  };
  const ar = {
    'good': 'حالة البحر: جيدة',
    'moderate': 'حالة البحر: متوسطة',
    'rough_sea': 'حالة البحر: مضطربة',
    'strong_current': 'حالة البحر: تيار قوي',
    'high_risk': 'حالة البحر: خطر مرتفع',
  };
  return (isArabic ? ar[band] : en[band]) ??
      (isArabic ? 'حالة البحر' : 'Sea state');
}


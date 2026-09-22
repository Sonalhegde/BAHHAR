import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/weather_conditions.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/glass_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/condition_stat_chip.dart';
import '../../../../shared/widgets/skeleton.dart';

/// The Home dashboard's Weather section: the air above the water.
///
/// Takes the [AsyncValue] rather than a resolved reading so the loading, error and
/// data shapes of one card live in one file — and so a test can hand it any of the
/// three without standing up the provider graph behind it.
///
/// All wording is passed in through [isArabic] because this app is bilingual and the
/// copy lives with the widget that renders it, matching the Ocean Conditions grid.
class WeatherCardWidget extends StatelessWidget {
  const WeatherCardWidget({
    super.key,
    required this.asyncWeather,
    this.isArabic = false,
  });

  final AsyncValue<WeatherConditions> asyncWeather;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'الطقس' : 'WEATHER',
          style:
              AppTextStyles.sectionHeader.copyWith(color: AppColors.primaryBlue),
        ),
        const SizedBox(height: 8),
        asyncWeather.when(
          data: _content,
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
              borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
            ),
            child: Text(
              isArabic ? 'تعذر تحميل حالة الطقس' : 'Failed to load weather.',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.signalAlert),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(WeatherConditions weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ConditionStatChip(
                label: isArabic ? 'الحرارة' : 'AIR TEMP',
                value: '${weather.tempC.round()}°C',
                subtext: isArabic
                    ? 'محسوسة ${weather.feelsLikeC.round()}°'
                    : 'Feels ${weather.feelsLikeC.round()}°',
                // On this coast the felt temperature is the heat-stress number, and
                // 40°C is where the day changes; the air figure alone hides that.
                isWarning: weather.isHot,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ConditionStatChip(
                label: isArabic ? 'الرطوبة' : 'HUMIDITY',
                value: '${weather.humidityPct.round()}%',
                subtext: weather.condition,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ConditionStatChip(
                label: isArabic ? 'الأشعة فوق البنفسجية' : 'UV',
                value: weather.uvIndex.toStringAsFixed(0),
                subtext: _uvBandLabel(weather.uvBand),
                isWarning: weather.uvIndex >= 8,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            isArabic
                ? 'الرياح ${weather.windKmh.round()} كم/س${weather.windDir == null ? '' : ' ${weather.windDir}'} • احتمال المطر ${weather.rainProbabilityPct?.round() ?? 0}%'
                // A provider that measured no bearing leaves the word out rather than
                // printing a direction nobody observed.
                : 'Wind ${weather.windKmh.round()} km/h'
                    '${weather.windDir == null ? '' : ' ${weather.windDir}'}'
                    ' • Rain ${weather.rainProbabilityPct?.round() ?? 0}%',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ),
        if (weather.hourly.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              // 70 fits the tile's three lines (time, temp, rain) plus its padding
              // and border with headroom for a taller text scale; 62 overflowed.
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: weather.hourly.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) => _hourTile(weather.hourly[i]),
              ),
            ),
          ),
        // The five-day outlook, drawn from the same `daily` array the proxy returns.
        // It is a row of Expanded tiles rather than a second scroller because five
        // days is what the upstream sends, and a fisherman reads all five at a glance.
        if (weather.daily.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                for (final day in weather.daily.take(5))
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _dayTile(day),
                  )),
              ],
            ),
          ),
        // The proxy says which provider answered and why it degraded. Rendering that
        // verbatim is the difference between a sample reading and a measurement.
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            weather.note ??
                (isArabic
                    ? 'المصدر: ${weather.attribution}'
                    : 'Source: ${weather.attribution}'),
            style: AppTextStyles.caption.copyWith(
                fontSize: 10, color: AppColors.textTertiary),
          ),
        ),
        if (WeatherService.isStale(weather) || WeatherService.isSample(weather))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  WeatherService.isSample(weather)
                      ? Icons.science_outlined
                      : Icons.cloud_off,
                  size: 13,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    WeatherService.isSample(weather)
                        ? (isArabic
                            ? 'بيانات نموذجية — لا يوجد مزوّد متصل'
                            : 'Sample data — no weather provider is connected')
                        : (isArabic
                            ? 'آخر تحديث: ${Formatters.formatTime(weather.lastUpdated)} — بيانات محفوظة محلياً'
                            : 'Last updated ${Formatters.formatTime(weather.lastUpdated)} — showing last known weather'),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        // An alert is only ever rendered from a provider's own alert list. Open-Meteo
        // publishes none for Omani waters, so this stays hidden until AccuWeather is
        // connected — an absent feed is disclosed in the note above, never as an
        // all-clear.
        for (final alert in weather.alerts)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.signalAlertBg,
                borderRadius:
                    BorderRadius.circular(GlassTokens.radiusSmall),
              ),
              child: Text(
                alert.severity == null
                    ? alert.title
                    : '${alert.title} — ${alert.severity}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.signalAlert),
              ),
            ),
          ),
      ],
    );
  }

  Widget _hourTile(WeatherHour hour) {
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3E4F8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hour.time,
            style: AppTextStyles.caption
                .copyWith(fontSize: 10, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            '${hour.tempC.round()}°',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.oceanNavy,
            ),
          ),
          if (hour.rainProbabilityPct != null)
            Text(
              '${hour.rainProbabilityPct!.round()}%',
              style: AppTextStyles.caption
                  .copyWith(fontSize: 9.5, color: AppColors.primaryBlue),
            ),
        ],
      ),
    );
  }

  /// One day of the outlook: the weekday the proxy's own date falls on, then the high
  /// over the low. The condition phrase is left out on purpose — five tiles across a
  /// phone width cannot carry a sentence, and the hours above already say the sky.
  Widget _dayTile(WeatherDay day) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3E4F8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day.weekdayLabel(isArabic),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption
                .copyWith(fontSize: 10, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.highC.round()}°',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.oceanNavy,
            ),
          ),
          Text(
            '${day.lowC.round()}°',
            style: AppTextStyles.caption
                .copyWith(fontSize: 9.5, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  /// WHO UV bands, applied to the index value the provider reports. The band is
  /// presentation; the number underneath it is never altered.
  String _uvBandLabel(String band) {
    const en = {
      'low': 'Low',
      'moderate': 'Moderate',
      'high': 'High',
      'very_high': 'Very high',
      'extreme': 'Extreme',
    };
    const ar = {
      'low': 'منخفض',
      'moderate': 'معتدل',
      'high': 'مرتفع',
      'very_high': 'مرتفع جداً',
      'extreme': 'قاسٍ',
    };
    if (isArabic) return ar[band] ?? band;
    return en[band] ?? band;
  }
}

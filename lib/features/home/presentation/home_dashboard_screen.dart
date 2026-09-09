import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/marine_provider.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';
import '../../../shared/widgets/condition_stat_chip.dart';
import '../../../shared/widgets/hotspot_card.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final marineAsync = ref.watch(marineConditionsProvider);
    final hotspots = ref.watch(hotspotsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user?.homeRegion ?? "Muscat"}, Oman',
              style: AppTextStyles.h2.copyWith(fontSize: 16),
            ),
            const Text(
              'Coastal Waters',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, size: 20),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(marineConditionsProvider.future),
        color: AppColors.accentNavy,
        child: ListView(
          padding: const EdgeInsetsDirectional.all(16.0),
          children: [
            // Quiet Editorial Hero Card
            Container(
              padding: const EdgeInsetsDirectional.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurface : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.hairline,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const FishingScoreGauge(
                    probability: 88,
                    size: 180,
                    label: 'Overall Probability',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Target: Kingfish (كنعد) & Yellowfin Tuna',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.signalGood,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Conditions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Marine Conditions', style: AppTextStyles.h2),
                Text('Updated 5m ago', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 10),
            marineAsync.when(
              data: (marine) => SizedBox(
                height: 76,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ConditionStatChip(
                      icon: Icons.air,
                      value: '${marine.windSpeedKts.round()} kts',
                      label: 'Wind (${marine.windDirectionCompass})',
                    ),
                    const SizedBox(width: 8),
                    ConditionStatChip(
                      icon: Icons.waves,
                      value: '${marine.waveHeightM} m',
                      label: 'Wave Height',
                    ),
                    const SizedBox(width: 8),
                    ConditionStatChip(
                      icon: Icons.thermostat_outlined,
                      value: '${marine.seaTemperatureC}°C',
                      label: 'Sea Surface',
                    ),
                    const SizedBox(width: 8),
                    ConditionStatChip(
                      icon: Icons.water_outlined,
                      value: marine.tideState,
                      label: 'Tide State',
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err', style: AppTextStyles.caption),
            ),
            const SizedBox(height: 20),

            // Best Fishing Window
            Container(
              padding: const EdgeInsetsDirectional.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurface : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.hairline,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18, color: AppColors.inkSecondary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Optimal Bite Window Today', style: AppTextStyles.captionMedium),
                      SizedBox(height: 2),
                      Text(
                        '05:30 AM – 09:15 AM (Slack Flood Tide)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Hotspots Carousel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ranked Hotspots', style: AppTextStyles.h2),
                TextButton(
                  onPressed: () => context.go('/map'),
                  child: const Text('View All', style: TextStyle(color: AppColors.inkPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 125,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hotspots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final h = hotspots[index];
                  return HotspotCard(
                    name: h.name,
                    probability: h.probability,
                    distanceNm: h.distanceNm,
                    primarySpecies: h.targetSpecies.first,
                    legalStatus: h.legalStatus,
                    onTap: () => context.push('/hotspot/${h.id}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Primary CTAs
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.go('/map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Open Fishing Map', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/smart-trip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkPrimary,
                      side: const BorderSide(color: AppColors.hairline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Plan Smart Trip'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/catch'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkPrimary,
                      side: const BorderSide(color: AppColors.hairline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Log Catch'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
import '../../../shared/widgets/alert_banner.dart';

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
        title: Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: AppColors.aquaTeal),
            const SizedBox(width: 6),
            Text(
              '${user?.homeRegion ?? "Muscat"}, Oman',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(marineConditionsProvider.future),
        color: AppColors.oceanBlue,
        child: ListView(
          padding: const EdgeInsetsDirectional.all(16.0),
          children: [
            // Marine Alert Banner
            AlertBanner(
              title: 'Prime Morning Window Active',
              message: 'Current conditions off Muscat show 88% strike probability for Kingfish.',
              severity: AlertSeverity.info,
            ),
            const SizedBox(height: 16),

            // Hero Fishing Opportunity Gauge Card
            Container(
              padding: const EdgeInsetsDirectional.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurface : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.borderGray,
                ),
              ),
              child: Column(
                children: [
                  const FishingScoreGauge(
                    probability: 88,
                    size: 200,
                    label: 'Overall Strike Probability',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.aquaTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.aquaTeal),
                    ),
                    child: const Text(
                      'Optimal Conditions: Target Kingfish & Tuna',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Live Marine Conditions Strip (Section 6.3)
            Text(
              'Marine Conditions',
              style: AppTextStyles.h2.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),
            marineAsync.when(
              data: (marine) => SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ConditionStatChip(
                      icon: Icons.air,
                      value: '${marine.windSpeedKts.round()} kts',
                      label: 'Wind (${marine.windDirectionCompass})',
                      subLabel: 'Moderate',
                    ),
                    const SizedBox(width: 8),
                    ConditionStatChip(
                      icon: Icons.waves,
                      value: '${marine.waveHeightM} m',
                      label: 'Wave Height',
                      subLabel: '${marine.wavePeriodS}s swell',
                    ),
                    const SizedBox(width: 8),
                    ConditionStatChip(
                      icon: Icons.thermostat,
                      value: '${marine.seaTemperatureC}°C',
                      label: 'Sea Temp',
                      subLabel: 'Optimal',
                    ),
                    const SizedBox(width: 8),
                    ConditionStatChip(
                      icon: Icons.water,
                      value: marine.tideState,
                      label: 'Tide State',
                      subLabel: '${marine.tideHeightM}m peak',
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading marine data: $err'),
            ),
            const SizedBox(height: 20),

            // Best Fishing Window Card
            Container(
              padding: const EdgeInsetsDirectional.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurface : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.borderGray,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.sandGold.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wb_sunny_outlined, color: AppColors.sandGold),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Best Bite Window Today', style: AppTextStyles.captionMedium),
                        SizedBox(height: 2),
                        Text(
                          '05:30 AM – 09:15 AM (Dawn Slack Tide)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nearby Hotspots Carousel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Top Ranked Hotspots', style: AppTextStyles.h2.copyWith(fontSize: 18)),
                TextButton(
                  onPressed: () => context.go('/map'),
                  child: const Text('View Map', style: TextStyle(color: AppColors.oceanBlue)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hotspots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
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
              child: ElevatedButton.icon(
                onPressed: () => context.go('/map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepSea,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Explore Interactive Fishing Map', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/smart-trip'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.oceanBlue,
                      side: const BorderSide(color: AppColors.oceanBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    icon: const Icon(Icons.explore_outlined, size: 18),
                    label: const Text('Smart Trip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/catch'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.aquaTeal,
                      side: const BorderSide(color: AppColors.aquaTeal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size.fromHeight(46),
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Log Catch'),
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

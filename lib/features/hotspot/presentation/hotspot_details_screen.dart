import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/providers/marine_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';
import '../../../shared/widgets/condition_stat_chip.dart';
import '../../../shared/widgets/legal_status_badge.dart';
import '../../../shared/widgets/custom_buttons.dart';

class HotspotDetailsScreen extends ConsumerWidget {
  const HotspotDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotspots = ref.watch(hotspotsProvider);
    // Grab first or route param
    final hotspot = hotspots.first;
    final marineAsync = ref.watch(marineConditionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(hotspot.name),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotspot.nameAr, style: AppTextStyles.h1),
                    const SizedBox(height: 4),
                    Text('${hotspot.region} Governorate • ${hotspot.depthMeters}m depth',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              LegalStatusBadge(status: hotspot.legalStatus),
            ],
          ),
          if (hotspot.legalNotice.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsetsDirectional.all(12),
              decoration: BoxDecoration(
                color: AppColors.protectedArea.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.protectedArea),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: AppColors.protectedArea, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hotspot.legalNotice,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.protectedArea),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: FishingScoreGauge(
              probability: hotspot.probability,
              size: 190,
              label: 'Predicted Strike Rate',
            ),
          ),
          const SizedBox(height: 20),
          Text('Marine Conditions at Hotspot', style: AppTextStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          marineAsync.when(
            data: (m) => Row(
              children: [
                Expanded(
                  child: ConditionStatChip(
                    icon: Icons.air,
                    value: '${m.windSpeedKts} kts',
                    label: 'Wind',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ConditionStatChip(
                    icon: Icons.waves,
                    value: '${m.waveHeightM} m',
                    label: 'Wave',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ConditionStatChip(
                    icon: Icons.thermostat,
                    value: '${m.seaTemperatureC}°C',
                    label: 'Temp',
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
          ),
          const SizedBox(height: 20),
          Text('Target Species Present', style: AppTextStyles.h2.copyWith(fontSize: 18)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: hotspot.targetSpecies.map((s) {
              return Chip(
                avatar: const Icon(Icons.phishing, size: 16, color: AppColors.oceanBlue),
                label: Text(s),
                backgroundColor: isDark ? AppColors.nightSurface : AppColors.cardWhite,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          BahharPrimaryButton(
            label: 'Plan Smart Trip Here',
            icon: Icons.explore_outlined,
            onPressed: () {
              ref.read(tripPlanProvider.notifier).updateSpecies(hotspot.targetSpecies.first);
              context.go('/smart-trip');
            },
          ),
        ],
      ),
    );
  }
}

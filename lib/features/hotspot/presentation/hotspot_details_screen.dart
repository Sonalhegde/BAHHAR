import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/providers/marine_provider.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/glass/glass_card.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';
import '../../../shared/widgets/condition_stat_chip.dart';
import '../../../shared/widgets/legal_status_badge.dart';
import '../../../shared/polymorphic/soft_button.dart';

class HotspotDetailsScreen extends ConsumerWidget {
  final String hotspotId;
  const HotspotDetailsScreen({super.key, required this.hotspotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotspot = ref.watch(hotspotByIdProvider(hotspotId));
    final marineAsync = ref.watch(currentMarineConditionsProvider);

    if (hotspot == null) {
      return MarineBackground(
        child: Center(
          child: Text('Hotspot not found', style: AppTextStyles.body.copyWith(color: Colors.white)),
        ),
      );
    }

    return MarineBackground(
      child: CustomScrollView(
        slivers: [
          // Glass App Bar
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(hotspot.name, style: AppTextStyles.subhead.copyWith(color: Colors.white)),
            actions: [
              IconButton(icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white), onPressed: () {}),
              IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white), onPressed: () {}),
            ],
          ),

          // Overview Glass Card
          SliverToBoxAdapter(
            child: ElevatedGlassCard(
              margin: const EdgeInsets.all(16),
              glowColor: AppColors.cyanAccent,
              child: Row(
                children: [
                  FishingScoreGauge(score: hotspot.rating, size: 88),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hotspot.name, style: AppTextStyles.screenTitle.copyWith(fontSize: 20, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          '${hotspot.nameArabic} • ${hotspot.governorate}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        LegalStatusBadge(isRestricted: hotspot.isProtectedReserve),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live Marine Conditions Readouts
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COASTAL MARINE METRICS', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 8),
                  marineAsync.when(
                    data: (marine) => Row(
                      children: [
                        Expanded(
                          child: ConditionStatChip(
                            label: 'WAVE',
                            value: '${marine.waveHeightMeters}m',
                            subtext: marine.waveDirection,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ConditionStatChip(
                            label: 'WIND',
                            value: '${marine.windSpeedKnots}kt',
                            subtext: marine.windDirection,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ConditionStatChip(
                            label: 'WATER',
                            value: '${marine.waterTempCelsius}°C',
                            subtext: 'SST Normal',
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 20),

                  // Target Species
                  Text('KEY TARGET SPECIES', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hotspot.primarySpecies.map((s) => GlassContainer(
                      level: GlassLevel.standard,
                      borderRadius: GlassTokens.radiusSmall,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Text(s, style: AppTextStyles.labelSmall.copyWith(color: AppColors.cyanAccent)),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Bathymetric & Nav Specs
                  Text('BATHYMETRY & NAVIGATION SPECS', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 8),
                  GlassContainer(
                    level: GlassLevel.standard,
                    borderRadius: GlassTokens.radiusMedium,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildNavRow('GPS Coordinates', '${hotspot.latitude.toStringAsFixed(4)}° N, ${hotspot.longitude.toStringAsFixed(4)}° E'),
                        const Divider(color: Colors.white10, height: 16),
                        _buildNavRow('Contour Depth', '${hotspot.depthMeters} meters'),
                        const Divider(color: Colors.white10, height: 16),
                        _buildNavRow('Distance to Port', '${hotspot.distanceNmi} nautical miles'),
                        const Divider(color: Colors.white10, height: 16),
                        _buildNavRow('Substrate Structure', 'Rocky coral drop-off / gravel'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  SoftButton(
                    label: 'Plan Smart Trip to this Hotspot',
                    icon: Icons.navigation_rounded,
                    onPressed: () => context.push('/trip-planner'),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
      ],
    );
  }
}

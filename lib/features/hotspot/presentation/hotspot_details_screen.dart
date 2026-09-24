import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/providers/marine_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_card.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';
import '../../../shared/widgets/condition_stat_chip.dart';
import '../../../shared/widgets/legal_status_badge.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/polymorphic/soft_button.dart';

class HotspotDetailsScreen extends ConsumerWidget {
  final String hotspotId;
  const HotspotDetailsScreen({super.key, required this.hotspotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotspotAsync = ref.watch(hotspotByIdProvider(hotspotId));
    final marineAsync = ref.watch(marineConditionsProvider);

    return hotspotAsync.when(
      loading: () => MarineBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
          body: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SkeletonCard(height: 130),
                SizedBox(height: 12),
                SkeletonCard(height: 130),
              ],
            ),
          ),
        ),
      ),
      error: (e, _) => MarineBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load hotspot details.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
              TextButton(
                onPressed: () => ref.invalidate(hotspotByIdProvider(hotspotId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (hotspot) {
        if (hotspot == null) {
          return MarineBackground(
            child: Center(
              child: Text('Hotspot not found',
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
            ),
          );
        }

        final isProtected = hotspot.legalStatus != LegalStatus.permitted;

        return MarineBackground(
          child: CustomScrollView(
            slivers: [
              // Glass App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => context.pop(),
                ),
                title: Text(hotspot.name,
                    style: AppTextStyles.subhead
                        .copyWith(color: AppColors.textPrimary)),
                actions: [
                  IconButton(
                      icon: const Icon(Icons.bookmark_border_rounded,
                          color: AppColors.textPrimary),
                      onPressed: () {}),
                  IconButton(
                      icon: const Icon(Icons.share_outlined,
                          color: AppColors.textPrimary),
                      onPressed: () {}),
                ],
              ),

              // Overview Glass Card
              SliverToBoxAdapter(
                child: ElevatedGlassCard(
                  margin: const EdgeInsets.all(16),
                  glowColor: AppColors.cyanAccent,
                  child: Row(
                    children: [
                      FishingScoreGauge(score: hotspot.probability, size: 88),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hotspot.name,
                                style: AppTextStyles.screenTitle.copyWith(
                                    fontSize: 20, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(
                              '${hotspot.nameAr} • ${hotspot.region}',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            LegalStatusBadge(isRestricted: isProtected),
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
                      const Text('COASTAL MARINE METRICS',
                          style: AppTextStyles.sectionHeader),
                      const SizedBox(height: 8),
                      marineAsync.when(
                        data: (marine) => Row(
                          children: [
                            Expanded(
                              child: ConditionStatChip(
                                label: 'WAVE',
                                value: '${marine.waveHeightM}m',
                                subtext: 'Period ${marine.wavePeriodS}s',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ConditionStatChip(
                                label: 'WIND',
                                value: '${marine.windSpeedKts}kt',
                                subtext: marine.windDirectionCompass,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ConditionStatChip(
                                label: 'WATER',
                                value: '${marine.seaTemperatureC}°C',
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
                        error: (e, _) => const SizedBox(),
                      ),
                      const SizedBox(height: 20),

                      // Target Species
                      const Text('KEY TARGET SPECIES',
                          style: AppTextStyles.sectionHeader),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hotspot.targetSpecies
                            .map((s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(
                                        GlassTokens.radiusSmall),
                                    border: Border.all(
                                        color: AppColors.cyanAccent
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Text(s,
                                      style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.cyanAccent)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 20),

                      // Bathymetric & Nav Specs
                      const Text('BATHYMETRY & NAVIGATION SPECS',
                          style: AppTextStyles.sectionHeader),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(
                              GlassTokens.radiusMedium),
                          border: Border.all(
                              color: AppColors.textPrimary.withValues(alpha: 0.10)),
                        ),
                        child: Column(
                          children: [
                            _buildNavRow(
                                'GPS Coordinates',
                                '${hotspot.latitude.toStringAsFixed(4)}° N, '
                                '${hotspot.longitude.toStringAsFixed(4)}° E'),
                            const Divider(color: AppColors.textPrimary, height: 16),
                            _buildNavRow(
                                'Contour Depth', '${hotspot.depthMeters} meters'),
                            const Divider(color: AppColors.textPrimary, height: 16),
                            _buildNavRow('Distance to Port',
                                '${hotspot.distanceNm} nautical miles'),
                            const Divider(color: AppColors.textPrimary, height: 16),
                            _buildNavRow('Best Fishing Window',
                                hotspot.bestWindow),
                            if (hotspot.legalNotice.isNotEmpty) ...[
                              const Divider(color: AppColors.textPrimary, height: 16),
                              _buildNavRow(
                                  'Legal Notice', hotspot.legalNotice),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(hotspot.description,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary)),

                      const SizedBox(height: 28),
                      SoftButton(
                        label: 'Plan Smart Trip to this Hotspot',
                        icon: Icons.navigation_rounded,
                        onPressed: () {
                          ref
                              .read(tripPlanProvider.notifier)
                              .updateSpecies(hotspot.targetSpecies.first);
                          context.push('/trip-planner');
                        },
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/hotspots_provider.dart';
import '../../../core/providers/marine_provider.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';
import '../../../shared/widgets/condition_stat_chip.dart';
import '../../../shared/widgets/legal_status_badge.dart';

class HotspotDetailsScreen extends ConsumerWidget {
  final String hotspotId;
  const HotspotDetailsScreen({super.key, required this.hotspotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotspot = ref.watch(hotspotByIdProvider(hotspotId));
    final marineAsync = ref.watch(currentMarineConditionsProvider);

    if (hotspot == null) {
      return Scaffold(
        backgroundColor: AppColors.surfacePure,
        appBar: AppBar(title: const Text('Spot Details')),
        body: const Center(child: Text('Hotspot not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surfacePure,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePure,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(hotspot.name, style: AppTextStyles.subhead),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderHairline, height: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Overview
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
              ),
              child: Row(
                children: [
                  FishingScoreGauge(score: hotspot.rating, size: 90),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hotspot.name, style: AppTextStyles.screenTitle.copyWith(fontSize: 22)),
                        Text('${hotspot.nameArabic} • ${hotspot.governorate}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        LegalStatusBadge(isRestricted: hotspot.isProtectedReserve),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Live Conditions Grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REAL-TIME CONDITIONS', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 12),
                  marineAsync.when(
                    data: (marine) => Row(
                      children: [
                        Expanded(
                          child: ConditionStatChip(
                            label: 'WAVE HEIGHT',
                            value: '${marine.waveHeightMeters}m',
                            subtext: marine.waveDirection,
                            isWarning: marine.waveHeightMeters > 1.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ConditionStatChip(
                            label: 'WIND SPEED',
                            value: '${marine.windSpeedKnots}kt',
                            subtext: marine.windDirection,
                            isWarning: marine.windSpeedKnots > 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ConditionStatChip(
                            label: 'WATER TEMP',
                            value: '${marine.waterTempCelsius}°C',
                            subtext: 'SST Normal',
                          ),
                        ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 28),
                  Text('KEY TARGET SPECIES', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: hotspot.primarySpecies.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderHairline),
                      ),
                      child: Text(s, style: AppTextStyles.labelMedium),
                    )).toList(),
                  ),

                  const SizedBox(height: 28),
                  Text('NAVIGATION & BATHYMETRY', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePure,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderHairline),
                    ),
                    child: Column(
                      children: [
                        _buildNavRow('Coordinates', '${hotspot.latitude.toStringAsFixed(4)}° N, ${hotspot.longitude.toStringAsFixed(4)}° E'),
                        const Divider(height: 16, color: AppColors.borderHairline),
                        _buildNavRow('Depth', '${hotspot.depthMeters} meters'),
                        const Divider(height: 16, color: AppColors.borderHairline),
                        _buildNavRow('Distance from Port', '${hotspot.distanceNmi} nautical miles'),
                        const Divider(height: 16, color: AppColors.borderHairline),
                        _buildNavRow('Bottom Type', 'Rocky coral drop-off / gravel'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        context.push('/trip-planner');
                      },
                      child: Text('Plan Smart Trip Here', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}\n
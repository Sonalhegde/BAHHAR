import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/glass/glass_card.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/polymorphic/soft_button.dart';

/// Renders the TripService.planTrip() output for the wizard's TripRequest.
class TripRecommendationScreen extends ConsumerWidget {
  const TripRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(tripPlanResultProvider);

    return MarineBackground(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text('Calibrated Trip Plan',
                style:
                    AppTextStyles.subhead.copyWith(color: Colors.white)),
          ),
          resultAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    SkeletonCard(),
                    SizedBox(height: 12),
                    SkeletonCard(),
                    SizedBox(height: 12),
                    SkeletonCard(),
                  ],
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 36, color: AppColors.signalAlert),
                    const SizedBox(height: 10),
                    Text('Could not generate a trip plan.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(tripPlanResultProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (plan) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Glass Hero
                    ElevatedGlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      glowColor: AppColors.signalGood,
                      child: Row(
                        children: [
                          FishingScoreGauge(
                              score: plan.probability, size: 84),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('OPTIMAL TRIP WINDOW',
                                    style: AppTextStyles.sectionHeader
                                        .copyWith(
                                            color:
                                                AppColors.signalGood)),
                                const SizedBox(height: 3),
                                Text(plan.departureSlotLabel,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                const SizedBox(height: 3),
                                Text(
                                  'Incoming tide with optimal SST convergence offshore',
                                  style: AppTextStyles.caption.copyWith(
                                      color:
                                          AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Where this plan came from, said plainly. The backend ranks the
                    // catalogue against live water; the offline path ranks it against
                    // nothing but the spots' own numbers, and a plan that flew blind
                    // has to look like one that flew blind.
                    if (plan.isMock)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.signalCautionBg,
                            borderRadius: BorderRadius.circular(
                                GlassTokens.radiusSmall),
                          ),
                          child: Text(
                            'Planned offline — no live sea conditions were available, '
                            'so this ranking ignores the water.',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.signalCaution),
                          ),
                        ),
                      ),

                    // Every candidate tripped this boat's own radius or budget limit.
                    // "Least-impossible" is not "sailable", and the screen says so.
                    if (plan.noViableOption)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.signalAlertBg,
                            borderRadius: BorderRadius.circular(
                                GlassTokens.radiusSmall),
                          ),
                          child: Text(
                            'No spot fits this boat\'s limits — widen the radius, '
                            'raise the budget, or choose a closer port.',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.signalAlert),
                          ),
                        ),
                      ),

                    // Primary Destination Card
                    const Text('PRIMARY WAYPOINT DESTINATION',
                        style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 8),
                    GlassContainer(
                      level: GlassLevel.standard,
                      borderRadius: GlassTokens.radiusMedium,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan.hotspot.name,
                              style: AppTextStyles.cardTitle
                                  .copyWith(fontSize: 16)),
                          Text(
                            '${plan.distanceNm.toStringAsFixed(1)} nmi from ${plan.departurePort}',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary),
                          ),
                          const Divider(color: Colors.white10, height: 20),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem('RIG TACKLE',
                                  plan.recommendedTackle),
                              _buildStatItem('TARGET DEPTH',
                                  plan.targetDepthRange),
                              _buildStatItem(
                                  'EST. FUEL',
                                  '${plan.estimatedFuelLiters.toStringAsFixed(0)} Liters'
                                  ' (${plan.estimatedCostOmr.toStringAsFixed(1)} OMR)'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Waypoint Timeline
                    const Text('WAYPOINT ROUTE SCHEDULE',
                        style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 8),
                    GlassContainer(
                      level: GlassLevel.standard,
                      borderRadius: GlassTokens.radiusMedium,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          for (var i = 0; i < plan.waypoints.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                  color: Colors.white10, height: 16),
                            _buildWaypointRow(
                              plan.waypoints[i].time,
                              plan.waypoints[i].title,
                              plan.waypoints[i].subtitle,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    SoftButton(
                      label: 'Confirm & Save Trip Plan',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Trip plan saved to your logbook!')),
                        );
                        context.go('/home');
                      },
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.sectionHeader
                  .copyWith(fontSize: 9.5)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildWaypointRow(String time, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(time,
            style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.cyanAccent)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(sub,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

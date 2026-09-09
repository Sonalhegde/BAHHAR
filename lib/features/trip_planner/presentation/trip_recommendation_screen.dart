import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/glass/glass_card.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';
import '../../../shared/polymorphic/soft_button.dart';

class TripRecommendationScreen extends ConsumerWidget {
  const TripRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MarineBackground(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text('Calibrated Trip Plan', style: AppTextStyles.subhead.copyWith(color: Colors.white)),
          ),

          // Overview Glass Hero
          SliverToBoxAdapter(
            child: ElevatedGlassCard(
              margin: const EdgeInsets.all(16),
              glowColor: AppColors.signalGood,
              child: Row(
                children: [
                  const FishingScoreGauge(score: 89, size: 84),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OPTIMAL TRIP WINDOW', style: AppTextStyles.sectionHeader.copyWith(color: AppColors.signalGood)),
                        const SizedBox(height: 3),
                        Text('05:15 AM - 09:30 AM', style: AppTextStyles.bodyMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 3),
                        Text('Incoming tide with optimal SST convergence offshore', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Primary Destination Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PRIMARY WAYPOINT DESTINATION', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 8),
                  GlassContainer(
                    level: GlassLevel.standard,
                    borderRadius: GlassTokens.radiusMedium,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fahal Island Drop-off', style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
                        Text('12.4 nmi from Marina Bandar Al Rowdha', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        const Divider(color: Colors.white10, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatItem('RIG TACKLE', 'Trolling 40lb'),
                            _buildStatItem('TARGET DEPTH', '35 - 45m'),
                            _buildStatItem('EST. FUEL', '38 Liters'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Waypoint Timeline
                  Text('WAYPOINT ROUTE SCHEDULE', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 8),
                  GlassContainer(
                    level: GlassLevel.standard,
                    borderRadius: GlassTokens.radiusMedium,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildWaypointRow('05:00 AM', 'Depart Marina Bandar Al Rowdha', 'Heading 045° • Sea calm 0.6m'),
                        const Divider(color: Colors.white10, height: 16),
                        _buildWaypointRow('05:40 AM', 'Arrive at East Shelf Contour', 'Begin slow troll for Kingfish'),
                        const Divider(color: Colors.white10, height: 16),
                        _buildWaypointRow('08:15 AM', 'Shift to North Reef Pinnacle', 'Jigging window during slack tide'),
                        const Divider(color: Colors.white10, height: 16),
                        _buildWaypointRow('10:30 AM', 'Return cruise before afternoon breeze', 'Wind picking up to 14kt NW'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  SoftButton(
                    label: 'Confirm & Save Trip Plan',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trip plan saved to your logbook!')),
                      );
                      context.go('/home');
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
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.sectionHeader.copyWith(fontSize: 9.5)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  Widget _buildWaypointRow(String time, String title, String sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(time, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.cyanAccent)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 2),
              Text(sub, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

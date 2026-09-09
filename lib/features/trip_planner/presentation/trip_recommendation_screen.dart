import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/fishing_score_gauge.dart';

class TripRecommendationScreen extends ConsumerWidget {
  const TripRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surfacePure,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePure,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Trip Plan Recommendation', style: AppTextStyles.subhead),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderHairline, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall plan score banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfacePure,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Row(
                children: [
                  const FishingScoreGauge(score: 89, size: 84),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Optimal Window', style: AppTextStyles.subhead),
                        const SizedBox(height: 4),
                        Text(
                          '05:15 AM - 09:30 AM\nIncoming tide with optimal SST convergence',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text('PRIMARY DESTINATION', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfacePure,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fahal Island Drop-off', style: AppTextStyles.cardTitle),
                  Text('12.4 nmi from Marina Bandar Al Rowdha', style: AppTextStyles.caption),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem('RECOMMENDED RIG', 'Trolling Rig 40lb'),
                      _buildMetricItem('BEST DEPTH', '35 - 45m'),
                      _buildMetricItem('EST. FUEL', '38 Liters'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text('WAYPOINT ROUTE SCHEDULE', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfacePure,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                children: [
                  _buildWaypointItem('05:00 AM', 'Depart Marina Bandar Al Rowdha', 'Heading 045° • Calm sea (0.6m)'),
                  const Divider(height: 1, color: AppColors.borderHairline),
                  _buildWaypointItem('05:40 AM', 'Arrive at East Shelf Contour', 'Begin slow troll for Kingfish'),
                  const Divider(height: 1, color: AppColors.borderHairline),
                  _buildWaypointItem('08:15 AM', 'Shift to North Reef Pinnacle', 'Jigging window during slack water'),
                  const Divider(height: 1, color: AppColors.borderHairline),
                  _buildWaypointItem('10:30 AM', 'Return cruise before afternoon breeze', 'Wind increasing to 14kt NW'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip plan saved to your log')),
                  );
                  context.go('/home');
                },
                child: Text('Confirm & Save Trip Plan', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.8)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildWaypointItem(String time, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.accentNavy)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}\n
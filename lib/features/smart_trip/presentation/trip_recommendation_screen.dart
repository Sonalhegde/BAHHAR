import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../shared/widgets/custom_buttons.dart';

class TripRecommendationScreen extends ConsumerWidget {
  const TripRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(tripRecommendationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommended Trips'),
      ),
      body: recommendations.isEmpty
          ? const Center(
              child: Text('No hotspots within fuel budget. Try increasing budget slider.'),
            )
          : ListView.separated(
              padding: const EdgeInsetsDirectional.all(16.0),
              itemCount: recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final r = recommendations[index];
                final probColor = AppColors.getProbabilityColor(r.probability);

                return Container(
                  padding: const EdgeInsetsDirectional.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurface : AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.nightBorder : AppColors.borderGray,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(r.hotspot.name, style: AppTextStyles.h2),
                          ),
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: probColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: probColor),
                            ),
                            child: Text(
                              '${r.probability}% Match',
                              style: TextStyle(fontWeight: FontWeight.bold, color: probColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.navigation_outlined, size: 16, color: AppColors.oceanBlue),
                          const SizedBox(width: 4),
                          Text('${r.distanceNm} nm round-trip • ~${r.travelMinutes} mins travel'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.local_gas_station_outlined, size: 16, color: AppColors.sandGold),
                          const SizedBox(width: 4),
                          Text(
                            'Estimated Fuel: ${r.estimatedFuelLiters} L (~${r.estimatedCostOmr} OMR)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      BahharPrimaryButton(
                        label: 'Start Navigation',
                        icon: Icons.directions,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Launching marine navigation to ${r.hotspot.name} (${r.hotspot.latitude}, ${r.hotspot.longitude})'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

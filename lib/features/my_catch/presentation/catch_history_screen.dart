import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/catches_provider.dart';
import '../../../shared/widgets/catch_list_item.dart';

class CatchHistoryScreen extends ConsumerWidget {
  const CatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catches = ref.watch(catchesProvider);
    final (totalCatches, totalTrips, topSpecies) = ref.watch(catchStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Catch Log'),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16.0),
        children: [
          // Header Stats Row (Section 6.6)
          Row(
            children: [
              _buildStatTile('Total Catches', '$totalCatches', isDark),
              const SizedBox(width: 8),
              _buildStatTile('Trips Logged', '$totalTrips', isDark),
              const SizedBox(width: 8),
              _buildStatTile('Top Species', topSpecies.split(' ').first, isDark),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Catches', style: AppTextStyles.h2),
              Text('${catches.length} items', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 10),
          ...catches.map((c) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 10.0),
              child: CatchListItem(
                speciesName: c.speciesName,
                weightKg: c.weightKg,
                lengthCm: c.lengthCm,
                locationName: c.locationName,
                caughtAt: c.caughtAt,
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-catch'),
        backgroundColor: AppColors.oceanBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Catch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightSurface : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.nightBorder : AppColors.borderGray),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.h2.copyWith(color: AppColors.oceanBlue)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.micro, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

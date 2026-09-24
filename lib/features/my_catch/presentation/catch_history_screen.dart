import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/catches_provider.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/widgets/skeleton.dart';

class CatchHistoryScreen extends ConsumerWidget {
  const CatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catchesAsync = ref.watch(catchesProvider);

    return MarineBackground(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Catch Log History',
                      style: AppTextStyles.subhead
                          .copyWith(fontSize: 20, color: AppColors.textPrimary)),
                  GestureDetector(
                    onTap: () => context.push('/my-catch/add'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.oceanNavy,
                        borderRadius:
                            BorderRadius.circular(GlassTokens.radiusPill),
                        border: Border.all(
                            color: AppColors.cyanAccent
                                .withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded,
                              size: 16, color: AppColors.cyanAccent),
                          SizedBox(width: 4),
                          Text('Log Catch',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          catchesAsync.when(
            data: (catches) {
              if (catches.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phishing_rounded,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        Text('No catches logged yet',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        const Text(
                            'Log catches to calibrate personal ML predictions.',
                            style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final item = catches[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassContainer(
                          level: GlassLevel.standard,
                          borderRadius: GlassTokens.radiusMedium,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Photo thumbnail when available
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    GlassTokens.radiusSmall),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: item.photoUrl != null
                                      ? Image.network(item.photoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => _speciesIcon())
                                      : _speciesIcon(),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(item.speciesName,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: AppTextStyles.cardTitle
                                                  .copyWith(
                                                      color: AppColors.textPrimary)),
                                        ),
                                        Text(
                                            '${item.weightKg.toStringAsFixed(1)} kg',
                                            style: AppTextStyles.bodyMedium.copyWith(
                                                fontWeight:
                                                    FontWeight.w700,
                                                color:
                                                    AppColors.cyanBright)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.locationName}'
                                      '${item.lengthCm != null ? ' • ${item.lengthCm!.toStringAsFixed(0)} cm' : ''}',
                                      style: AppTextStyles.caption,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (item.baitOrLure != null) ...[
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.textPrimary
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(item.baitOrLure!,
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                        fontSize: 10,
                                                        color: AppColors
                                                            .cyanAccent)),
                                          ),
                                        ],
                                        if (item.released) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.signalGood
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text('Released',
                                                style: AppTextStyles.caption
                                                    .copyWith(
                                                        fontSize: 10,
                                                        color: AppColors
                                                            .signalGood)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: catches.length,
                  ),
                ),
              );
            },
            loading: () => const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    SkeletonCard(),
                    SizedBox(height: 10),
                    SkeletonCard(),
                    SizedBox(height: 10),
                    SkeletonCard(),
                  ],
                ),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_outlined,
                        size: 40, color: AppColors.textTertiary),
                    const SizedBox(height: 10),
                    Text('Failed to load history',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(catchesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _speciesIcon() {
    return Container(
      color: AppColors.cyanAccent.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: const Icon(Icons.set_meal_outlined,
          size: 22, color: AppColors.cyanAccent),
    );
  }
}

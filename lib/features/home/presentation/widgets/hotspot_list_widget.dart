import 'package:flutter/material.dart';

import 'package:bahhar/core/models/hotspot_model.dart';
import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/core/theme/app_text_styles.dart';
import 'package:bahhar/shared/animations/app_animations.dart';
import 'package:bahhar/shared/widgets/hotspot_card.dart';

/// Top recommended hotspots as ranked cards.
///
/// Sorts [hotspots] by descending strike probability and renders up to [limit]
/// of them using the shared [HotspotCard], each entering with the app's
/// staggered "surface rising" motion. Tapping a card reports the hotspot
/// through [onTap] so the host can navigate to its details. Shows a friendly
/// bilingual empty state when there is nothing to rank.
class HotspotListWidget extends StatelessWidget {
  const HotspotListWidget({
    super.key,
    required this.hotspots,
    this.onTap,
    this.limit,
    this.isArabic = false,
    this.emptyMessage,
  });

  final List<HotspotModel> hotspots;

  /// Invoked with the tapped hotspot.
  final ValueChanged<HotspotModel>? onTap;

  /// Maximum number of cards to show (all of them when null).
  final int? limit;

  final bool isArabic;

  /// Overrides the automatic bilingual empty message.
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (hotspots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Text(
            emptyMessage ??
                (isArabic
                    ? 'لا توجد مواقع مصنفة حالياً'
                    : 'No ranked spots available right now.'),
            style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    final ranked = [...hotspots]
      ..sort((a, b) => b.probability.compareTo(a.probability));
    final shown = limit == null ? ranked : ranked.take(limit!).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shown.length; i++)
          SlideFadeReveal.staggered(
            index: i,
            child: HotspotCard(
              hotspot: shown[i],
              onTap: onTap == null ? null : () => onTap!(shown[i]),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bahhar/core/providers/hotspots_provider.dart';
import 'package:bahhar/core/providers/preferences_provider.dart';
import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/core/theme/app_text_styles.dart';
import 'package:bahhar/core/theme/glass_tokens.dart';

/// Species filtering chips for the hotspot map markers.
///
/// Renders one chip per distinct species across the loaded hotspots
/// ([availableSpeciesProvider]) plus an "All Spots" reset. Selecting a chip
/// writes to [selectedSpeciesFilterProvider], which [filteredHotspotsProvider]
/// observes so the map (and [ProbabilityMarkersWidget]) redraw with only the
/// matching spots. Single-select, tap-again to clear, fully bilingual.
class MapSpeciesFilterChips extends ConsumerWidget {
  const MapSpeciesFilterChips({
    super.key,
    this.allLabel,
    this.maxChipWidth = 180,
  });

  /// Overrides the automatic bilingual "All" label.
  final String? allLabel;

  /// Prevents a long species name from stretching a chip.
  final double maxChipWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    final speciesAsync = ref.watch(availableSpeciesProvider);
    final selected = ref.watch(selectedSpeciesFilterProvider);

    return speciesAsync.maybeWhen(
      data: (species) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: allLabel ?? (isArabic ? 'كل المواقع' : 'All Spots'),
              isSelected: selected == null,
              onTap: () =>
                  ref.read(selectedSpeciesFilterProvider.notifier).state = null,
            ),
            for (final s in species)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: s,
                  isSelected: selected == s,
                  maxWidth: maxChipWidth,
                  onTap: () => ref.read(selectedSpeciesFilterProvider.notifier).state =
                      selected == s ? null : s,
                ),
              ),
          ],
        ),
      ),
      orElse: () => const SizedBox(height: 34),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.maxWidth,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: GestureDetector(
        key: Key('species_filter_chip_$label'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.oceanNavy : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
            border: Border.all(
              color: isSelected ? AppColors.cyanAccent : const Color(0xFFD6E6F7),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

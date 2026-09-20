import 'package:flutter/material.dart';

import 'package:bahhar/core/constants/fish_species.dart';
import 'package:bahhar/core/theme/app_colors.dart';
import 'package:bahhar/core/theme/app_text_styles.dart';
import 'package:bahhar/core/theme/glass_tokens.dart';

/// Horizontal species selector chips (Kingfish, Tuna, Hammour, …).
///
/// A fully controlled, multi-select chip row driven by the [FishSpecies]
/// catalogue so labels, artwork and Arabic names stay in sync with the rest of
/// the app. The host owns the selection ([selected] holds the chosen species)
/// and receives updates through [onChanged]. Falls back gracefully to an empty
/// row when there are no species.
class SpeciesChipsWidget extends StatelessWidget {
  const SpeciesChipsWidget({
    super.key,
    required this.selected,
    required this.onChanged,
    this.species = FishSpecies.values,
    this.isArabic = false,
    this.singleSelect = false,
  });

  /// Currently selected species.
  final List<FishSpecies> selected;

  /// Emits the new selection whenever a chip is tapped.
  final ValueChanged<List<FishSpecies>> onChanged;

  /// The catalogue to render. Defaults to every known species.
  final List<FishSpecies> species;

  final bool isArabic;

  /// When true, tapping a chip replaces the selection instead of toggling.
  final bool singleSelect;

  String _label(FishSpecies s) => isArabic ? s.nameAr : s.displayName;

  void _handleTap(FishSpecies s) {
    if (singleSelect) {
      final isOn = selected.contains(s);
      onChanged(isOn ? const <FishSpecies>[] : <FishSpecies>[s]);
      return;
    }
    final next = List<FishSpecies>.from(selected);
    if (!next.remove(s)) next.add(s);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    if (species.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: species.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final s = species[i];
          final isOn = selected.contains(s);
          return GestureDetector(
            key: Key('species_chip_${s.name}'),
            onTap: () => _handleTap(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isOn ? AppColors.primaryBlue : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
                border: Border.all(
                  color: isOn ? AppColors.primaryBlue : const Color(0xFFD6E6F7),
                  width: 1.2,
                ),
                boxShadow: isOn
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : const [],
              ),
              child: Text(
                _label(s),
                style: AppTextStyles.labelSmall.copyWith(
                  color: isOn ? Colors.white : AppColors.textPrimary,
                  fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

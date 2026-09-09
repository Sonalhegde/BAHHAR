import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SpeciesItem {
  final String id;
  final String nameEn;
  final String nameAr;
  final int? probability;

  const SpeciesItem({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.probability,
  });
}

/// SpeciesSelector (Section 4.4)
/// Horizontally scrollable selectable chips with optional probability badge.
class SpeciesSelector extends StatelessWidget {
  final List<SpeciesItem> species;
  final String? selectedSpeciesId;
  final ValueChanged<SpeciesItem> onSelect;

  const SpeciesSelector({
    super.key,
    required this.species,
    required this.selectedSpeciesId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        itemCount: species.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = species[index];
          final isSelected = item.id == selectedSpeciesId;

          return ChoiceChip(
            selected: isSelected,
            onSelected: (_) => onSelect(item),
            showCheckmark: false,
            selectedColor: isDark ? AppColors.oceanBlue : AppColors.deepSea,
            backgroundColor: isDark ? AppColors.nightSurface : AppColors.cardWhite,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? AppColors.nightBorder : AppColors.borderGray),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phishing,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.oceanBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  item.nameEn,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.deepNavyText),
                  ),
                ),
                if (item.probability != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.getProbabilityColor(item.probability!).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${item.probability}%',
                      style: AppTextStyles.micro.copyWith(
                        color: AppColors.getProbabilityColor(item.probability!),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

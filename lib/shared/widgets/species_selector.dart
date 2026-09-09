import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class SpeciesSelector extends StatelessWidget {
  final List<String> species;
  final List<String> selected;
  final ValueChanged<List<String>>? onChanged;

  const SpeciesSelector({
    super.key,
    required this.species,
    required this.selected,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: species.map((s) {
        final isSelected = selected.contains(s);
        return GestureDetector(
          onTap: () {
            final updated = List<String>.from(selected);
            if (isSelected) {
              updated.remove(s);
            } else {
              updated.add(s);
            }
            onChanged?.call(updated);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentNavy : AppColors.surfacePure,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppColors.accentNavy : AppColors.borderHairline,
              ),
            ),
            child: Text(
              s,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

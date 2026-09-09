import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_tokens.dart';

/// Language Capsule Pill Toggle as shown in the reference: [ EN | عربي ]
class LanguageCapsuleToggle extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onToggle;

  const LanguageCapsuleToggle({
    super.key,
    required this.isArabic,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1FC),
          borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
          border: Border.all(color: const Color(0xFFD3E4F8), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // English Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: !isArabic ? AppColors.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
                boxShadow: !isArabic
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                'EN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: !isArabic ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
            // Arabic Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isArabic ? AppColors.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
                boxShadow: isArabic
                    ? [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                'عربي',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isArabic ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Polymorphic Filter Chip
class PolymorphicChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const PolymorphicChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : const Color(0xFFD6E5F5),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PolymorphicSegmentedBar extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const PolymorphicSegmentedBar({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FB),
        borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
        border: Border.all(color: const Color(0xFFD6E6F7)),
      ),
      child: Row(
        children: List.generate(options.length, (idx) {
          final isSelected = idx == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  options[idx],
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

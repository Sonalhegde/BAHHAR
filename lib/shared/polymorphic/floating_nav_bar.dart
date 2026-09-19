import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class NavDestinationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const NavDestinationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class FloatingGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestinationItem> items;

  const FloatingGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          border: const Border(
            top: BorderSide(color: Color(0xFFE2EDF8), width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F2644).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (idx) {
            final item = items[idx];
            final isSelected = idx == selectedIndex;
            const motion = Duration(milliseconds: 220);
            const ease = Curves.easeOutCubic;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDestinationSelected(idx);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Soft pill halo blooming behind the active icon
                    AnimatedContainer(
                      duration: motion,
                      curve: ease,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 14 : 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryBlueLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: AnimatedScale(
                        duration: motion,
                        curve: Curves.easeOutBack,
                        scale: isSelected ? 1.12 : 1.0,
                        child: Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          size: 22,
                          color: isSelected
                              ? AppColors.primaryBlue
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: motion,
                      curve: ease,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.textSecondary,
                      ),
                      child: Text(item.label),
                    ),
                    const SizedBox(height: 3),
                    // Active indicator dot from reference image
                    AnimatedScale(
                      duration: motion,
                      curve: Curves.easeOutBack,
                      scale: isSelected ? 1.0 : 0.0,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

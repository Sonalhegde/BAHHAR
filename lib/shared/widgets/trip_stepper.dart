import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class TripStepData {
  final String title;
  final String subtitle;
  final Widget content;

  const TripStepData({
    required this.title,
    required this.subtitle,
    required this.content,
  });
}

/// TripStepper (Section 4.4)
/// Clean vertical step container for the 6-step Smart Trip wizard
class TripStepper extends StatelessWidget {
  final int currentStep;
  final List<TripStepData> steps;
  final ValueChanged<int> onStepTapped;

  const TripStepper({
    super.key,
    required this.currentStep,
    required this.steps,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index < currentStep;
        final isActive = index == currentStep;
        final step = steps[index];

        return Container(
          margin: const EdgeInsetsDirectional.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurface : AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppColors.oceanBlue
                  : (isDark ? AppColors.nightBorder : AppColors.borderGray),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => onStepTapped(index),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.aquaTeal
                              : (isActive ? AppColors.oceanBlue : Colors.transparent),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.aquaTeal
                                : (isActive
                                    ? AppColors.oceanBlue
                                    : (isDark ? Colors.white38 : Colors.grey)),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.deepNavyText,
                              ),
                            ),
                            Text(
                              step.subtitle,
                              style: AppTextStyles.caption.copyWith(
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isActive ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: isDark ? Colors.white60 : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              if (isActive)
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
                  child: step.content,
                ),
            ],
          ),
        );
      }),
    );
  }
}

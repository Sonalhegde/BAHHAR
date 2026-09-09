import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class TripStepper extends StatelessWidget {
  final List<TripStep> steps;
  final int currentStep;

  const TripStepper({super.key, required this.steps, this.currentStep = 0});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (idx) {
        final step = steps[idx];
        final isActive = idx == currentStep;
        final isPassed = idx < currentStep;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isPassed || isActive ? AppColors.accentNavy : AppColors.surfaceSubtle,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPassed || isActive ? AppColors.accentNavy : AppColors.borderHairline,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: isPassed
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Text(
                            '${idx + 1}',
                            style: AppTextStyles.caption.copyWith(
                              color: isActive ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  if (idx < steps.length - 1)
                    Container(
                      width: 1,
                      height: 28,
                      color: isPassed ? AppColors.accentNavy : AppColors.borderHairline,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                    if (step.subtitle != null)
                      Text(step.subtitle!, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class TripStep {
  final String title;
  final String? subtitle;
  const TripStep({required this.title, this.subtitle});
}

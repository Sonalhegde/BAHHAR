import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/bahhar_logo_widget.dart';
import '../../../shared/widgets/custom_buttons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = const [
    {
      'title': 'Know Before You Go',
      'subtitle': 'Real-time marine conditions and ML fishing probability engineered specifically for Omani waters.',
      'icon': 'water',
    },
    {
      'title': 'Fish the Right Spot, Legally',
      'subtitle': 'Explore ranked hotspots with distinct overlays for protected marine reserves and restricted zones.',
      'icon': 'shield',
    },
    {
      'title': 'Plan the Optimal Trip',
      'subtitle': 'Smart Trip engine balances weather, species bite windows, and fuel cost from your departure port.',
      'icon': 'compass',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: TextButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text('Skip', style: TextStyle(color: AppColors.oceanBlue)),
                ),
              ),
              const Spacer(),
              const BahharLogoWidget(size: 80, color: AppColors.deepSea),
              const SizedBox(height: 32),
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slide['title']!,
                          style: AppTextStyles.h1.copyWith(
                            color: isDark ? Colors.white : AppColors.deepNavyText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide['subtitle']!,
                          style: AppTextStyles.body.copyWith(
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                    height: 8,
                    width: isActive ? 24 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.oceanBlue : AppColors.borderGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const Spacer(),
              BahharPrimaryButton(
                label: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_currentPage < _slides.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    context.go('/auth');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

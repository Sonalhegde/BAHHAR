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
    },
    {
      'title': 'Fish the Right Spot, Legally',
      'subtitle': 'Explore ranked hotspots with distinct overlays for protected marine reserves and restricted zones.',
    },
    {
      'title': 'Plan the Optimal Trip',
      'subtitle': 'Smart Trip engine balances weather, species bite windows, and fuel cost from your departure port.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePure,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.topEnd,
                child: TextButton(
                  onPressed: () => context.go('/auth'),
                  child: Text('Skip', style: AppTextStyles.labelMedium.copyWith(color: AppColors.accentNavy)),
                ),
              ),
              const Spacer(),
              const BahharLogoWidget(size: 72, showSubtitle: false),
              const SizedBox(height: 32),
              SizedBox(
                height: 200,
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
                          style: AppTextStyles.screenTitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide['subtitle']!,
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: isActive ? 24 : 6,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.accentNavy : AppColors.borderHairline,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const Spacer(),
              PrimaryButton(
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

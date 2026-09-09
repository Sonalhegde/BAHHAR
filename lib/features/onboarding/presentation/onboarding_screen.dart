import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/polymorphic/soft_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = const [
    {
      'icon': Icons.tsunami_rounded,
      'title': 'Know Before You Go',
      'subtitle': 'Real-time marine conditions and ML fishing probability engineered specifically for Omani waters.',
      'badge': 'OCEANIC INTELLIGENCE',
    },
    {
      'icon': Icons.shield_outlined,
      'title': 'Fish Legally & Sustainably',
      'subtitle': 'Explore ranked hotspots with distinct glass overlays for protected marine reserves like Daymaniyat.',
      'badge': 'REGULATORY COMPLIANCE',
    },
    {
      'icon': Icons.navigation_rounded,
      'title': 'Plan Optimal Waypoints',
      'subtitle': 'Smart Trip engine balances tides, target bite windows, and vessel fuel burn from your departure marina.',
      'badge': 'FUEL-OPTIMIZED ROUTING',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return MarineBackground(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Top Bar with Skip Action
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/auth'),
                child: Text(
                  'Skip',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.cyanAccent),
                ),
              ),
            ),
            const Spacer(),

            // Floating Carousel Glass Panel
            SizedBox(
              height: 380,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return GlassContainer(
                    level: GlassLevel.prominent,
                    borderRadius: GlassTokens.radiusLarge,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cyanAccent.withValues(alpha: 0.16),
                            border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.4), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyanAccent.withValues(alpha: 0.25),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: Icon(slide['icon'] as IconData, size: 44, color: AppColors.cyanAccent),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          slide['badge'] as String,
                          style: AppTextStyles.sectionHeader.copyWith(fontSize: 10, letterSpacing: 1.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slide['title'] as String,
                          style: AppTextStyles.screenTitle.copyWith(fontSize: 22, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          slide['subtitle'] as String,
                          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            // Minimal step indicator pills
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 4,
                  width: isActive ? 28 : 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.cyanAccent : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const Spacer(),

            // Primary Navigation Button
            SoftButton(
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

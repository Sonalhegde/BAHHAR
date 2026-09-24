import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/polymorphic/soft_button.dart';
import '../../../shared/animations/app_animations.dart';

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
              child: SlideFadeReveal(
                delay: const Duration(milliseconds: 200),
                offsetY: -12,
                child: TextButton(
                  onPressed: () => context.go('/auth'),
                  child: Text(
                    'Skip',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.cyanAccent),
                  ),
                ),
              ),
            ),
            const Spacer(),

            // Floating Carousel Glass Panel with depth parallax
            SlideFadeReveal(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 700),
              offsetY: 34,
              child: SizedBox(
                height: 380,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return AnimatedBuilder(
                      animation: _pageController,
                      child: GlassContainer(
                        level: GlassLevel.prominent,
                        borderRadius: GlassTokens.radiusLarge,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BreathingPulse(
                              child: Container(
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
                            ),
                            const SizedBox(height: 24),
                            Text(
                              slide['badge'] as String,
                              style: AppTextStyles.sectionHeader.copyWith(fontSize: 10, letterSpacing: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide['title'] as String,
                              style: AppTextStyles.screenTitle.copyWith(fontSize: 22, color: AppColors.textPrimary),
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
                      ),
                      builder: (context, child) {
                        // Cards sink back in scale/opacity as they leave the viewport.
                        final page = _pageController.hasClients
                            ? (_pageController.page ?? _currentPage.toDouble())
                            : _currentPage.toDouble();
                        final delta = (page - index).clamp(-1.0, 1.0);
                        final t = 1 - delta.abs();
                        return Transform.scale(
                          scale: 0.92 + 0.08 * t,
                          child: Opacity(opacity: 0.55 + 0.45 * t, child: child),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),
            // Minimal step indicator pills
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 4,
                  width: isActive ? 28 : 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.cyanAccent : AppColors.textPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const Spacer(),

            // Primary Navigation Button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero).animate(animation),
                  child: child,
                ),
              ),
              child: SoftButton(
                key: ValueKey(_currentPage == _slides.length - 1),
                label: _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  if (_currentPage < _slides.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                    );
                  } else {
                    context.go('/auth');
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

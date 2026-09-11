import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/widgets/bahhar_logo_widget.dart';
import '../../../shared/polymorphic/soft_button.dart';
import '../../../shared/polymorphic/soft_toggle.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(isArabicProvider);

    return MarineBackground(
      showHeadlandSilhouettes: true,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              // Top Header Bar: Language Capsule + Location Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LanguageCapsuleToggle(
                    isArabic: isArabic,
                    onToggle: () => ref.read(isArabicProvider.notifier).toggleLanguage(),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: AppColors.oceanNavy),
                      SizedBox(width: 4),
                      Text(
                        'Oman',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.oceanNavy,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.oceanNavy),
                    ],
                  ),
                ],
              ),
              const Spacer(flex: 2),

              // Central Bahhar Sail Emblem + Wordmark + Arabic Calligraphy
              const BahharLogoWidget(
                size: 88,
                showWordmark: true,
                showSubtitle: true,
                showArabic: true,
              ),

              const Spacer(flex: 2),

              // Enter Command Button
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: SoftButton(
                  label: isArabic ? 'دخول التطبيق' : 'Enter Command',
                  icon: Icons.arrow_forward_rounded,
                  style: SoftButtonStyle.primary,
                  onPressed: () => context.go('/home'),
                ),
              ),
              const SizedBox(height: 14),

              // Tagline
              Text(
                'Navigate  •  Explore  •  Stay Safe',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

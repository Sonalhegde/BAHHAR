import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';
import '../../../shared/polymorphic/soft_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isArabic = ref.watch(isArabicProvider);

    return MarineBackground(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                isArabic ? 'الملف الشخصي واللوائح' : 'Captain Profile & Settings',
                style: AppTextStyles.subhead.copyWith(fontSize: 20, color: Colors.white),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Captain Glass Card
                  GlassContainer(
                    level: GlassLevel.prominent,
                    borderRadius: GlassTokens.radiusMedium,
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.oceanNavy,
                          child: const Text('B', style: TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 20)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Captain Salim Al-Riyami', style: AppTextStyles.cardTitle.copyWith(color: Colors.white)),
                              Text(authState.phone ?? '+968 9123 4567', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                              Text('Muscat • Coastal Vessel Operator', style: AppTextStyles.caption.copyWith(color: AppColors.cyanAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('APPLICATION PREFERENCES', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 8),
                  GlassContainer(
                    level: GlassLevel.standard,
                    borderRadius: GlassTokens.radiusMedium,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          title: 'Language / اللغة',
                          subtitle: isArabic ? 'العربية (عُمان)' : 'English',
                          trailing: TextButton(
                            onPressed: () => ref.read(isArabicProvider.notifier).toggleLanguage(),
                            child: Text(isArabic ? 'English' : 'عربي', style: const TextStyle(color: AppColors.cyanAccent)),
                          ),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildSettingItem(
                          title: 'Speed & Distance Units',
                          subtitle: 'Knots & Nautical Miles (nmi)',
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildSettingItem(
                          title: 'Depth Units',
                          subtitle: 'Meters (m)',
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('REGULATORY & COMPLIANCE', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 8),
                  GlassContainer(
                    level: GlassLevel.standard,
                    borderRadius: GlassTokens.radiusMedium,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _buildSettingItem(
                          title: 'Oman Fishery Laws & Seasons',
                          subtitle: 'Ministry of Agriculture, Fisheries and Water Resources',
                          trailing: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.cyanAccent),
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        _buildSettingItem(
                          title: 'Daymaniyat Nature Reserve Permits',
                          subtitle: 'Environment Authority Oman',
                          trailing: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.cyanAccent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  SoftButton(
                    label: 'Sign Out',
                    style: SoftButtonStyle.danger,
                    onPressed: () {
                      ref.read(authNotifierProvider.notifier).signOut();
                      context.go('/login');
                    },
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({required String title, required String subtitle, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

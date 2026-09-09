import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/preferences_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isArabic = ref.watch(isArabicProvider);

    return Scaffold(
      backgroundColor: AppColors.surfacePure,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePure,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(isArabic ? 'الملف الشخصي' : 'Profile & Settings', style: AppTextStyles.subhead),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderHairline, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User identification card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfacePure,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.accentNavy,
                    child: Text(
                      'B',
                      style: AppTextStyles.subhead.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Captain Salim Al-Riyami', style: AppTextStyles.cardTitle),
                        Text(authState.phone ?? '+968 9123 4567', style: AppTextStyles.caption),
                        Text('Muscat • Coastal Fisherman', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            Text('PREFERENCES', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfacePure,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    title: 'Application Language',
                    subtitle: isArabic ? 'العربية (عُمان)' : 'English',
                    trailing: TextButton(
                      onPressed: () {
                        ref.read(isArabicProvider.notifier).toggleLanguage();
                      },
                      child: Text(isArabic ? 'Switch to EN' : 'تغيير للعربية', style: AppTextStyles.labelSmall.copyWith(color: AppColors.accentNavy)),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderHairline),
                  _buildSettingItem(
                    title: 'Speed & Distance Units',
                    subtitle: 'Knots & Nautical Miles (nmi)',
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
                  ),
                  const Divider(height: 1, color: AppColors.borderHairline),
                  _buildSettingItem(
                    title: 'Depth Units',
                    subtitle: 'Meters (m)',
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            Text('REGULATORY & COMPLIANCE', style: AppTextStyles.sectionHeader),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfacePure,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                children: [
                  _buildSettingItem(
                    title: 'Oman Fishery Laws & Seasons',
                    subtitle: 'Ministry of Agriculture, Fisheries and Water Resources',
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textTertiary),
                  ),
                  const Divider(height: 1, color: AppColors.borderHairline),
                  _buildSettingItem(
                    title: 'Daymaniyat Nature Reserve Permits',
                    subtitle: 'Environment Authority Oman',
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.signalAlert,
                  side: const BorderSide(color: AppColors.borderHairline),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).signOut();
                  context.go('/login');
                },
                child: Text('Sign Out', style: AppTextStyles.labelMedium.copyWith(color: AppColors.signalAlert)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
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
}\n
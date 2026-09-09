import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../shared/widgets/custom_buttons.dart';
import 'widgets/language_switcher_widget.dart';

/// Screen 10: Profile & Settings Screen (Section 6.7)
/// Avatar, home region selector, units toggle, notification toggles, logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final prefs = ref.watch(preferencesProvider);
    final prefsNotifier = ref.read(preferencesProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(16.0),
        children: [
          // User Card
          Container(
            padding: const EdgeInsetsDirectional.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.nightSurface : AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.nightBorder : AppColors.borderGray,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.deepSea,
                  child: Text(
                    user?.displayName?.substring(0, 1).toUpperCase() ?? 'B',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Bahhar Captain',
                        style: AppTextStyles.h2.copyWith(
                          color: isDark ? Colors.white : AppColors.deepNavyText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'fisherman@bahhar.om',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.oceanBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Region: ${user?.homeRegion ?? "Muscat"}',
                          style: AppTextStyles.micro.copyWith(
                            color: AppColors.oceanBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'App Preferences',
            style: AppTextStyles.h2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          // Language Switcher
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isDark ? AppColors.nightSurface : AppColors.cardWhite,
            title: const Text('Language / اللغة'),
            trailing: const LanguageSwitcherWidget(),
          ),
          const SizedBox(height: 8),
          // Unit switch
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isDark ? AppColors.nightSurface : AppColors.cardWhite,
            title: const Text('Units'),
            subtitle: Text(prefs.isMetric ? 'Metric (°C, km, kts)' : 'Imperial (°F, nm, mph)'),
            trailing: Switch(
              value: prefs.isMetric,
              onChanged: (_) => prefsNotifier.toggleUnits(),
              activeColor: AppColors.oceanBlue,
            ),
          ),
          const SizedBox(height: 8),
          // Dark Mode Toggle
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isDark ? AppColors.nightSurface : AppColors.cardWhite,
            title: const Text('Night Mode (Dawn/Dusk)'),
            subtitle: const Text('High contrast dark ocean theme for early departures'),
            trailing: Switch(
              value: isDark,
              onChanged: (val) {
                prefsNotifier.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
              activeColor: AppColors.aquaTeal,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Notification Alerts',
            style: AppTextStyles.h2.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isDark ? AppColors.nightSurface : AppColors.cardWhite,
            title: const Text('Marine & Wave Alerts'),
            value: prefs.marineAlerts,
            onChanged: prefsNotifier.toggleMarineAlerts,
            activeColor: AppColors.oceanBlue,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isDark ? AppColors.nightSurface : AppColors.cardWhite,
            title: const Text('Hotspot Probability Changes'),
            value: prefs.hotspotUpdates,
            onChanged: prefsNotifier.toggleHotspotUpdates,
            activeColor: AppColors.oceanBlue,
          ),
          const SizedBox(height: 24),
          BahharSecondaryButton(
            label: 'Sign Out',
            icon: Icons.logout,
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              context.go('/auth');
            },
          ),
        ],
      ),
    );
  }
}

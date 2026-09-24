import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    final prefs = ref.watch(preferencesProvider);
    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: Text(t('settings')),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        children: [
          // ── Language ───────────────────────────────────────────────────────
          _SectionHeader(t('settings_language')),
          _SegmentedChoice(
            options: const ['English', 'العربية'],
            selectedIndex: isArabic ? 1 : 0,
            onChanged: (i) => ref.read(isArabicProvider.notifier).setArabic(i == 1),
          ),

          // ── Appearance ─────────────────────────────────────────────────────
          _SectionHeader(isArabic ? 'المظهر' : 'Appearance'),
          _SegmentedChoice(
            options: [
              isArabic ? 'فاتح' : 'Light',
              isArabic ? 'داكن' : 'Dark',
              isArabic ? 'النظام' : 'System',
            ],
            selectedIndex: switch (prefs.themeMode) {
              ThemeMode.light => 0,
              ThemeMode.dark => 1,
              _ => 2,
            },
            onChanged: (i) => ref
                .read(preferencesProvider.notifier)
                .setThemeMode(const [ThemeMode.light, ThemeMode.dark, ThemeMode.system][i]),
          ),

          // ── Units ─────────────────────────────────────────────────────────
          _SectionHeader(t('settings_units')),
          _SegmentedChoice(
            options: [
              '${isArabic ? 'متري' : 'Metric'} (kg, m, °C)',
              '${isArabic ? 'إمبراطوري' : 'Imperial'} (lb, ft, °F)',
            ],
            selectedIndex: prefs.isMetric ? 0 : 1,
            onChanged: (i) {
              if ((i == 0) != prefs.isMetric) {
                ref.read(preferencesProvider.notifier).toggleUnits();
              }
            },
          ),

          // ── Notifications ─────────────────────────────────────────────────
          _SectionHeader(t('settings_notifications')),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2EDF8)),
            ),
            child: Column(
              children: [
                _SwitchTile(
                  label: isArabic ? 'تنبيهات الطقس' : 'Weather Alerts',
                  value: prefs.weatherAlerts,
                  onChanged: (v) => ref.read(preferencesProvider.notifier).toggleWeatherAlerts(v),
                ),
                const Divider(height: 1, indent: 16, color: Color(0xFFF0F4F8)),
                _SwitchTile(
                  label: isArabic ? 'تنبيهات بحرية' : 'Marine Alerts',
                  value: prefs.marineAlerts,
                  onChanged: (v) => ref.read(preferencesProvider.notifier).toggleMarineAlerts(v),
                ),
                const Divider(height: 1, indent: 16, color: Color(0xFFF0F4F8)),
                _SwitchTile(
                  label: isArabic ? 'تذكيرات الرحلات' : 'Trip Reminders',
                  value: prefs.tripReminders,
                  onChanged: (v) => ref.read(preferencesProvider.notifier).toggleTripReminders(v),
                ),
                const Divider(height: 1, indent: 16, color: Color(0xFFF0F4F8)),
                _SwitchTile(
                  label: isArabic ? 'تذكيرات انتهاء التصاريح' : 'Licence Expiry Reminders',
                  value: prefs.licenceExpiryReminders,
                  onChanged: (v) => ref.read(preferencesProvider.notifier).toggleLicenceExpiryReminders(v),
                ),
                const Divider(height: 1, indent: 16, color: Color(0xFFF0F4F8)),
                _SwitchTile(
                  label: isArabic ? 'تنبيهات السلامة' : 'Safety Alerts',
                  value: prefs.safetyAlerts,
                  onChanged: (v) => ref.read(preferencesProvider.notifier).toggleSafetyAlerts(v),
                ),
              ],
            ),
          ),

          // ── Location ──────────────────────────────────────────────────────
          _SectionHeader(t('location')),
          _LocationControl(isArabic: isArabic, ref: ref),

          // ── Privacy ───────────────────────────────────────────────────────
          _SectionHeader(t('settings_privacy')),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2EDF8)),
            ),
            child: Text(
              t('location_privacy_desc'),
              style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
            ),
          ),

          const SizedBox(height: 32),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(t('settings_about')),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2EDF8)),
            ),
            child: Column(
              children: [
                _AboutRow(label: isArabic ? 'الإصدار' : 'Version', value: '1.0.0'),
                const SizedBox(height: 6),
                _AboutRow(label: isArabic ? 'البريد الإلكتروني للدعم' : 'Support Email', value: 'support@bahhar.app'),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFF8FA9C8)),
      ),
    );
  }
}

class _SegmentedChoice extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _SegmentedChoice({required this.options, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.asMap().entries.map((e) {
          final selected = e.key == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))] : [],
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? AppColors.primaryBlue : Colors.grey[500],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}

class _LocationControl extends StatelessWidget {
  final bool isArabic;
  final WidgetRef ref;
  const _LocationControl({required this.isArabic, required this.ref});

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(locationTrackingProvider);
    final items = [
      (LocationTrackingMode.off, AppTranslations.t('location_off', isArabic), Icons.location_off_outlined),
      (LocationTrackingMode.mapOnly, AppTranslations.t('location_map_only', isArabic), Icons.map_outlined),
      (LocationTrackingMode.activeTrip, AppTranslations.t('location_active_trip', isArabic), Icons.gps_fixed_rounded),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EDF8)),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          final (itemMode, label, icon) = e.value;
          final selected = mode == itemMode;
          return Column(
            children: [
              InkWell(
                onTap: () => ref.read(locationTrackingProvider.notifier).setMode(itemMode),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: selected ? AppColors.primaryBlue : Colors.grey[400]),
                      const SizedBox(width: 14),
                      Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: selected ? AppColors.oceanNavy : Colors.black87))),
                      if (selected) const Icon(Icons.check_rounded, color: AppColors.primaryBlue, size: 20),
                    ],
                  ),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 50, color: Color(0xFFF0F4F8)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  const _AboutRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8FA9C8))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

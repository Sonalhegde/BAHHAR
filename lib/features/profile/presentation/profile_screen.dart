import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/fisherman_profile_provider.dart';
import '../../../core/providers/safety_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/localization/locale_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    final profile = ref.watch(fishermanProfileProvider);
    final checklist = ref.watch(safetyChecklistProvider);
    final licences = ref.watch(licencesProvider);
    final vessels = ref.watch(vesselsProvider);
    final crew = ref.watch(crewProvider);
    final gear = ref.watch(gearProvider);
    final prefs = ref.watch(preferencesProvider);

    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: CustomScrollView(
        slivers: [
          // ── LinkedIn/GCC Institutional Header ─────────────────────────────
          SliverAppBar(
            expandedHeight: 168,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _LinkedInProfileHeader(profile: profile, isArabic: isArabic),
            ),
          ),

          // ── Registry Completeness Status ──────────────────────────────────
          SliverToBoxAdapter(
            child: _RegistryCompletionCard(
              percentage: profile.completionPercentage,
              isArabic: isArabic,
            ),
          ),

          // ── Uniform Professional Grouped Sections ─────────────────────────
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 6),

              // 1. Personal Identity & Contact
              _SectionHeader(isArabic ? 'الهوية ومعلومات الاتصال' : 'CIVIL IDENTITY & CONTACT'),
              _CardGroup(
                children: [
                  _ProfileTile(
                    icon: Icons.person_outline_rounded,
                    label: t('full_name'),
                    value: isArabic && profile.fullNameArabic.isNotEmpty
                        ? profile.fullNameArabic
                        : profile.fullName,
                    onTap: () => context.push('/profile/edit-personal'),
                  ),
                  _ProfileTile(
                    icon: Icons.fingerprint_rounded,
                    label: t('civil_id'),
                    value: LocaleUtils.maskId(profile.civilId),
                    trailingWidget: _RevealButton(isArabic: isArabic),
                    onTap: () => context.push('/profile/edit-personal'),
                  ),
                  _ProfileTile(
                    icon: Icons.phone_android_rounded,
                    label: t('phone_number'),
                    value: LocaleUtils.maskPhone(profile.phoneNumber),
                    onTap: () => context.push('/profile/edit-personal'),
                  ),
                  _ProfileTile(
                    icon: Icons.location_on_outlined,
                    label: t('governorate'),
                    value: '${profile.governorate}${profile.wilayat != null ? " • ${profile.wilayat}" : ""}',
                    onTap: () => context.push('/profile/edit-personal'),
                  ),
                  _ProfileTile(
                    icon: Icons.contact_emergency_outlined,
                    label: t('emergency_contact'),
                    value: profile.emergencyContact?.name ?? '—',
                    hint: profile.emergencyContact?.phoneNumber != null
                        ? LocaleUtils.maskPhone(profile.emergencyContact!.phoneNumber)
                        : null,
                    onTap: () => context.push('/profile/edit-personal'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. Official Marine Licences & Craft
              _SectionHeader(isArabic ? 'التراخيص والسفن البحرية' : 'MARINE LICENCES & ASSETS'),
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.badge_outlined,
                    label: t('fishing_licences'),
                    hint: isArabic ? 'تصاريح الصيد الحرفي والتجاري' : 'Artisanal & commercial permits',
                    badge: '${licences.length}',
                    onTap: () => context.push('/profile/licences'),
                  ),
                  _NavTile(
                    icon: Icons.directions_boat_outlined,
                    label: t('my_boats'),
                    hint: isArabic ? 'السفن والقوارب المسجلة' : 'Registered vessels & inspection',
                    badge: '${vessels.length}',
                    onTap: () => context.push('/profile/vessels'),
                  ),
                  _NavTile(
                    icon: Icons.group_outlined,
                    label: t('crew'),
                    hint: isArabic ? 'سجل الطاقم والبحارة' : 'Authorized crew manifest',
                    badge: '${crew.length}',
                    onTap: () => context.push('/profile/crew'),
                  ),
                  _NavTile(
                    icon: Icons.tune_rounded,
                    label: t('fishing_gear'),
                    hint: isArabic ? 'تصاريح الشباك والمعدات' : 'Permits for specialized gear',
                    badge: '${gear.length}',
                    onTap: () => context.push('/profile/gear'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 3. Digital Documents Vault
              _SectionHeader(isArabic ? 'محفظة الوثائق' : 'DOCUMENTS WALLET'),
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.folder_open_rounded,
                    label: t('documents_wallet'),
                    hint: isArabic ? 'التراخيص، شهادات الفحص، التأمين' : 'Permits, inspection, insurance records',
                    onTap: () => context.push('/profile/documents'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 4. Safety Center
              _SectionHeader(isArabic ? 'السلامة والجاهزية البحرية' : 'MARITIME SAFETY & PROTOCOLS'),
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.shield_outlined,
                    label: t('pre_departure_checklist'),
                    hint: checklist.isComplete
                        ? (isArabic ? 'جميع الفحوصات مكتملة — إبحار آمن' : 'All 10 checks verified — ready')
                        : (isArabic ? 'فحص سترات النجاة والوقود والأجهزة' : 'Life jackets, fuel buffer & comms'),
                    badge: '${checklist.checkedCount}/${checklist.totalCount}',
                    badgeColor: checklist.isComplete ? AppColors.signalGood : AppColors.primaryBlue,
                    onTap: () => context.push('/profile/safety'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 5. System Settings
              _SectionHeader(isArabic ? 'الإعدادات والتفضيلات' : 'SETTINGS & PREFERENCES'),
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.language_rounded,
                    label: t('settings_language'),
                    hint: isArabic ? 'العربية (Arabic)' : 'English',
                    onTap: () => context.push('/profile/settings'),
                  ),
                  _NavTile(
                    icon: Icons.straighten_rounded,
                    label: t('settings_units'),
                    hint: prefs.isMetric ? t('settings_units_metric') : t('settings_units_imperial'),
                    onTap: () => context.push('/profile/settings'),
                  ),
                  _NavTile(
                    icon: Icons.notifications_none_rounded,
                    label: t('settings_notifications'),
                    hint: isArabic ? 'تنبيهات الطقس وانتهاء الصلاحية' : 'Severe weather & licence expiry',
                    onTap: () => context.push('/profile/settings'),
                  ),
                  _NavTile(
                    icon: Icons.navigation_outlined,
                    label: t('location_privacy'),
                    hint: isArabic ? 'أذونات تتبع الموقع' : 'Granular marine GPS permissions',
                    onTap: () => context.push('/profile/settings'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 6. Support & Official Guidelines
              _SectionHeader(isArabic ? 'المساعدة والأنظمة الرسمية' : 'SUPPORT & OFFICIAL INFORMATION'),
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.help_outline_rounded,
                    label: t('help'),
                    hint: isArabic ? 'أدلة الاستخدام والاستخدام في البحر' : 'Step-by-step guides & offline advice',
                    onTap: () => context.push('/profile/help'),
                  ),
                  _NavTile(
                    icon: Icons.outlined_flag_rounded,
                    label: t('report_issue'),
                    hint: isArabic ? 'إرسال بلاغ فني أو ملاحي' : 'Report technical or mapping issue',
                    onTap: () => context.push('/profile/report'),
                  ),
                  _NavTile(
                    icon: Icons.account_balance_outlined,
                    label: t('official_info'),
                    hint: isArabic ? 'لوائح وزارة الثروة الزراعية والسمكية' : 'MAFWR regulations & royal decrees',
                    onTap: () => context.push('/profile/official-info'),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 7. Session Management
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.logout_rounded,
                    label: t('settings_sign_out'),
                    isDestructive: true,
                    onTap: () => _confirmSignOut(context, isArabic),
                  ),
                ],
              ),

              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppTranslations.t('settings_sign_out', isArabic), style: AppTextStyles.subhead),
        content: Text(
          isArabic
              ? 'هل تريد تسجيل الخروج من بَحّار؟ ستبقى بياناتك وسجلاتك محفوظة بأمان.'
              : 'Are you sure you want to sign out of BAHHAR? Your records remain securely backed up.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.t('cancel', isArabic), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/auth');
            },
            child: Text(
              AppTranslations.t('settings_sign_out', isArabic),
              style: const TextStyle(color: AppColors.signalAlert, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── LinkedIn Institutional Header ─────────────────────────────────────────────

class _LinkedInProfileHeader extends StatelessWidget {
  final dynamic profile;
  final bool isArabic;
  const _LinkedInProfileHeader({required this.profile, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final name = isArabic && profile.fullNameArabic.isNotEmpty
        ? profile.fullNameArabic
        : profile.fullName;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.iconBoxNeutral,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      isArabic ? 'سلطنة عُمان • سجل الصيادين' : 'SULTANATE OF OMAN • REGISTRY',
                      style: AppTextStyles.micro.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (profile.fishermanId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    profile.fishermanId!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.iconBoxNeutral,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, size: 30, color: AppColors.iconForeground),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.subhead.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 13, color: AppColors.signalGood),
                        const SizedBox(width: 4),
                        Text(
                          isArabic ? 'صياد معتمد • وزارة الثروة الزراعية والسمكية' : 'Verified Fisher • MAFWR Oman',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.signalGood,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Registry Completion Card ──────────────────────────────────────────────────

class _RegistryCompletionCard extends StatelessWidget {
  final int percentage;
  final bool isArabic;
  const _RegistryCompletionCard({required this.percentage, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'اكتمال الملف والسجلات' : 'Registry Profile Status',
                style: AppTextStyles.captionMedium.copyWith(color: AppColors.textPrimary),
              ),
              Text(
                '${LocaleUtils.formatInt(percentage, isArabic)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 5,
              backgroundColor: AppColors.borderHairline,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inset Card Group Container ─────────────────────────────────────────────────

class _CardGroup extends StatelessWidget {
  final List<Widget> children;
  const _CardGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderHairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 56, color: AppColors.dividerColor),
          ],
        ],
      ),
    );
  }
}

// ── Section Header (LinkedIn Styled) ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        label,
        style: AppTextStyles.sectionHeader,
      ),
    );
  }
}

// ── Profile Data Tile (Clean Monochrome Icons) ────────────────────────────────

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.trailingWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.iconBoxNeutral,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(icon, size: 18, color: AppColors.iconForeground),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 1),
                  Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                  if (hint != null)
                    Text(hint!, style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
                ],
              ),
            ),
            trailingWidget ?? const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Navigation Menu Tile (LinkedIn Consistent Layout) ─────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final String? badge;
  final Color? badgeColor;
  final bool isDestructive;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    this.hint,
    this.badge,
    this.badgeColor,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDestructive ? AppColors.signalAlert : AppColors.textPrimary;
    final iconColor = isDestructive ? AppColors.signalAlert : AppColors.iconForeground;
    final iconBoxColor = isDestructive ? AppColors.signalAlertBg : AppColors.iconBoxNeutral;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBoxColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                  ),
                  if (hint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        hint!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.primaryBlue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeColor ?? AppColors.primaryBlue,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Reveal Button ──────────────────────────────────────────────────────────────

class _RevealButton extends StatefulWidget {
  final bool isArabic;
  const _RevealButton({required this.isArabic});

  @override
  State<_RevealButton> createState() => _RevealButtonState();
}

class _RevealButtonState extends State<_RevealButton> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => setState(() => _revealed = !_revealed),
      child: Text(
        _revealed
            ? AppTranslations.t('hide', widget.isArabic)
            : AppTranslations.t('show', widget.isArabic),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
      ),
    );
  }
}

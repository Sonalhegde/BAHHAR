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
      backgroundColor: const Color(0xFFF4F7FB),
      body: CustomScrollView(
        slivers: [
          // ── Government-Grade Header ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _GovernmentProfileHeader(profile: profile, isArabic: isArabic),
            ),
          ),

          // ── Profile Completion Status ──────────────────────────────────────
          SliverToBoxAdapter(
            child: _InstitutionalCompletionBanner(
              percentage: profile.completionPercentage,
              isArabic: isArabic,
            ),
          ),

          // ── Grouped Inset Sections (GCC Government Style) ──────────────────
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // 1. Personal Identity & Civil Registry
              _SectionHeader(isArabic ? 'الهوية والسجل المدني' : 'CIVIL IDENTITY & CONTACT'),
              _CardGroup(
                children: [
                  _ProfileTile(
                    icon: Icons.badge_outlined,
                    iconBg: const Color(0xFFEEF4FB),
                    iconColor: AppColors.primaryBlue,
                    label: t('full_name'),
                    value: isArabic && profile.fullNameArabic.isNotEmpty
                        ? profile.fullNameArabic
                        : profile.fullName,
                    onTap: () => context.push('/profile/edit-personal'),
                  ),
                  _ProfileTile(
                    icon: Icons.fingerprint_rounded,
                    iconBg: const Color(0xFFEEF4FB),
                    iconColor: AppColors.primaryBlue,
                    label: t('civil_id'),
                    value: LocaleUtils.maskId(profile.civilId),
                    trailingWidget: _RevealButton(isArabic: isArabic),
                    onTap: () => context.push('/profile/edit-personal'),
                  ),
                  _ProfileTile(
                    icon: Icons.phone_android_rounded,
                    iconBg: const Color(0xFFEEF4FB),
                    iconColor: AppColors.primaryBlue,
                    label: t('phone_number'),
                    value: LocaleUtils.maskPhone(profile.phoneNumber),
                    onTap: () => context.push('/profile/edit-personal'),
                  ),
                  _ProfileTile(
                    icon: Icons.location_city_rounded,
                    iconBg: const Color(0xFFEEF4FB),
                    iconColor: AppColors.primaryBlue,
                    label: t('governorate'),
                    value: '${profile.governorate}${profile.wilayat != null ? " • ${profile.wilayat}" : ""}',
                    onTap: () => context.push('/profile/edit-personal'),
                  ),
                  _ProfileTile(
                    icon: Icons.contact_emergency_outlined,
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFDC2626),
                    label: t('emergency_contact'),
                    value: profile.emergencyContact?.name ?? '—',
                    hint: profile.emergencyContact?.phoneNumber != null
                        ? LocaleUtils.maskPhone(profile.emergencyContact!.phoneNumber)
                        : null,
                    onTap: () => context.push('/profile/edit-personal'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2. Official Fishing Licences & Marine Assets
              _SectionHeader(isArabic ? 'السجلات والتراخيص البحرية' : 'MARINE LICENCES & ASSETS'),
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.card_membership_rounded,
                    iconBg: const Color(0xFFEEF4FB),
                    iconColor: AppColors.primaryBlue,
                    label: t('fishing_licences'),
                    hint: isArabic ? 'تصاريح الصيد الحرفي والتجاري' : 'Artisanal & commercial permits',
                    badge: '${licences.length}',
                    badgeColor: AppColors.primaryBlue,
                    onTap: () => context.push('/profile/licences'),
                  ),
                  _NavTile(
                    icon: Icons.directions_boat_outlined,
                    iconBg: const Color(0xFFE8F6F8),
                    iconColor: const Color(0xFF007A8C),
                    label: t('my_boats'),
                    hint: isArabic ? 'السفن والقوارب المسجلة' : 'Registered vessels & inspection',
                    badge: '${vessels.length}',
                    badgeColor: const Color(0xFF007A8C),
                    onTap: () => context.push('/profile/vessels'),
                  ),
                  _NavTile(
                    icon: Icons.group_outlined,
                    iconBg: const Color(0xFFF0EDF9),
                    iconColor: const Color(0xFF4F46E5),
                    label: t('crew'),
                    hint: isArabic ? 'سجل الطاقم والبحارة' : 'Authorized crew & deckhands',
                    badge: '${crew.length}',
                    badgeColor: const Color(0xFF4F46E5),
                    onTap: () => context.push('/profile/crew'),
                  ),
                  _NavTile(
                    icon: Icons.inventory_2_outlined,
                    iconBg: const Color(0xFFF5F3FF),
                    iconColor: const Color(0xFF6366F1),
                    label: t('fishing_gear'),
                    hint: isArabic ? 'تصاريح الشباك والمعدات' : 'Permits for nets & traps',
                    badge: '${gear.length}',
                    badgeColor: const Color(0xFF6366F1),
                    onTap: () => context.push('/profile/gear'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3. Digital Documents Wallet
              _SectionHeader(isArabic ? 'محفظة الوثائق الرقمية' : 'DOCUMENTS WALLET'),
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.folder_shared_outlined,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF1D4ED8),
                    label: t('documents_wallet'),
                    hint: isArabic ? 'التراخيص، الفحص السنوي، التأمين' : 'Licences, registration, insurance',
                    onTap: () => context.push('/profile/documents'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 4. Maritime Safety Center
              _SectionHeader(isArabic ? 'مركز السلامة البحرية' : 'MARITIME SAFETY'),
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.verified_user_outlined,
                    iconBg: checklist.isComplete ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                    iconColor: checklist.isComplete ? const Color(0xFF059669) : const Color(0xFFD97706),
                    label: t('pre_departure_checklist'),
                    hint: checklist.isComplete
                        ? (isArabic ? 'جميع الفحوصات مكتملة' : 'Ready for voyage')
                        : (isArabic ? 'فحص سترات النجاة والوقود والأجهزة' : '10 vital pre-sail checks'),
                    badge: '${checklist.checkedCount}/${checklist.totalCount}',
                    badgeColor: checklist.isComplete ? const Color(0xFF059669) : const Color(0xFFD97706),
                    onTap: () => context.push('/profile/safety'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 5. System Preferences & Compliance
              _SectionHeader(isArabic ? 'الإعدادات والخصوصية' : 'SETTINGS & PREFERENCES'),
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.language_rounded,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF334155),
                    label: t('settings_language'),
                    hint: isArabic ? 'العربية (Arabic)' : 'English',
                    onTap: () => context.push('/profile/settings'),
                  ),
                  _NavTile(
                    icon: Icons.straighten_rounded,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF334155),
                    label: t('settings_units'),
                    hint: prefs.isMetric ? t('settings_units_metric') : t('settings_units_imperial'),
                    onTap: () => context.push('/profile/settings'),
                  ),
                  _NavTile(
                    icon: Icons.notifications_none_rounded,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF334155),
                    label: t('settings_notifications'),
                    hint: isArabic ? 'تنبيهات الطقس وانتهاء الرخص' : 'Marine alerts & licence reminders',
                    onTap: () => context.push('/profile/settings'),
                  ),
                  _NavTile(
                    icon: Icons.location_on_outlined,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF334155),
                    label: t('location_privacy'),
                    hint: isArabic ? 'تحديد إذن التتبع البحري' : 'Granular GPS permissions',
                    onTap: () => context.push('/profile/settings'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 6. Support, Help & Official Decrees
              _SectionHeader(isArabic ? 'الدعم والمعلومات الرسمية' : 'SUPPORT & OFFICIAL INFORMATION'),
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.menu_book_rounded,
                    iconBg: const Color(0xFFFFFBEB),
                    iconColor: const Color(0xFFB45309),
                    label: t('help'),
                    hint: isArabic ? 'أدلة الاستخدام والاستخدام بدون إنترنت' : 'Step-by-step guides & offline use',
                    onTap: () => context.push('/profile/help'),
                  ),
                  _NavTile(
                    icon: Icons.report_problem_outlined,
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFDC2626),
                    label: t('report_issue'),
                    hint: isArabic ? 'إرسال بلاغ فني أو بيئي' : 'Submit technical or safety report',
                    onTap: () => context.push('/profile/report'),
                  ),
                  _NavTile(
                    icon: Icons.account_balance_outlined,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF0284C7),
                    label: t('official_info'),
                    hint: isArabic ? 'لوائح وزارة الثروة الزراعية والسمكية' : 'MAFWR regulations & decrees',
                    onTap: () => context.push('/profile/official-info'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 7. Account Session
              _CardGroup(
                children: [
                  _NavTile(
                    icon: Icons.power_settings_new_rounded,
                    iconBg: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFDC2626),
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
        title: Text(AppTranslations.t('settings_sign_out', isArabic)),
        content: Text(isArabic
            ? 'هل تريد تسجيل الخروج من بَحّار؟ ستبقى بياناتك محفوظة ومحمية.'
            : 'Are you sure you want to sign out of BAHHAR? Your data remains securely backed up.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppTranslations.t('cancel', isArabic)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/auth');
            },
            child: Text(
              AppTranslations.t('settings_sign_out', isArabic),
              style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Government Profile Header ──────────────────────────────────────────────────

class _GovernmentProfileHeader extends StatelessWidget {
  final dynamic profile;
  final bool isArabic;
  const _GovernmentProfileHeader({required this.profile, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final name = isArabic && profile.fullNameArabic.isNotEmpty
        ? profile.fullNameArabic
        : profile.fullName;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // National Fisher Header Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 13, color: AppColors.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      isArabic ? 'سلطنة عُمان • سجل الصيادين' : 'SULTANATE OF OMAN • FISHER REGISTRY',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (profile.fishermanId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    profile.fishermanId!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Avatar + User Identity Details
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, size: 36, color: Color(0xFF475569)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.oceanNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          isArabic ? 'صياد معتمد • وزارة الثروة الزراعية والسمكية' : 'Verified Fisher • MAFWR Oman',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF059669),
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

// ── Institutional Completion Banner ───────────────────────────────────────────

class _InstitutionalCompletionBanner extends StatelessWidget {
  final int percentage;
  final bool isArabic;
  const _InstitutionalCompletionBanner({required this.percentage, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EDF8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isArabic ? 'اكتمال الملف الشخصي والسجلات' : 'Profile & Registry Completeness',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.oceanNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${LocaleUtils.formatInt(percentage, isArabic)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2EDF8),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EDF8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

// ── Institutional Profile Tile ─────────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String? hint;
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.oceanNavy)),
                  if (hint != null)
                    Text(hint!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            trailingWidget ?? const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

// ── Institutional Navigation Tile ──────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? hint;
  final String? badge;
  final Color? badgeColor;
  final bool isDestructive;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.hint,
    this.badge,
    this.badgeColor,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? const Color(0xFFDC2626) : AppColors.oceanNavy,
                    ),
                  ),
                  if (hint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        hint!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.primaryBlue).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? AppColors.primaryBlue,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBD5E1)),
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

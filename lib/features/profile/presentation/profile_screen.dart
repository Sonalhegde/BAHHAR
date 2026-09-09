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
    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(profile: profile, isArabic: isArabic),
            ),
          ),

          // ── Completion Banner ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _CompletionBanner(
              percentage: profile.completionPercentage,
              isArabic: isArabic,
            ),
          ),

          // ── Section list ─────────────────────────────────────────────────
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // Personal
              _SectionHeader(t('personal_info')),
              _ProfileTile(
                icon: Icons.person_outline_rounded,
                label: t('full_name'),
                value: isArabic && profile.fullNameArabic.isNotEmpty
                    ? profile.fullNameArabic
                    : profile.fullName,
                onTap: () => context.push('/profile/edit-personal'),
              ),
              _ProfileTile(
                icon: Icons.badge_outlined,
                label: t('civil_id'),
                value: LocaleUtils.maskId(profile.civilId),
                trailingWidget: _RevealButton(isArabic: isArabic),
                onTap: () => context.push('/profile/edit-personal'),
              ),
              _ProfileTile(
                icon: Icons.phone_outlined,
                label: t('phone_number'),
                value: LocaleUtils.maskPhone(profile.phoneNumber),
                onTap: () => context.push('/profile/edit-personal'),
              ),
              _ProfileTile(
                icon: Icons.location_on_outlined,
                label: t('governorate'),
                value: profile.governorate,
                onTap: () => context.push('/profile/edit-personal'),
              ),
              _ProfileTile(
                icon: Icons.emergency_outlined,
                label: t('emergency_contact'),
                value: profile.emergencyContact?.name ?? '—',
                hint: profile.emergencyContact?.phoneNumber,
                onTap: () => context.push('/profile/edit-personal'),
              ),

              const SizedBox(height: 8),

              // Fishing
              _SectionHeader(t('fishing_info')),
              _NavTile(
                icon: Icons.card_membership_outlined,
                label: t('fishing_licences'),
                badge: '${ref.watch(licencesProvider).length}',
                onTap: () => context.push('/profile/licences'),
              ),
              _NavTile(
                icon: Icons.sailing_outlined,
                label: t('my_boats'),
                badge: '${ref.watch(vesselsProvider).length}',
                onTap: () => context.push('/profile/vessels'),
              ),
              _NavTile(
                icon: Icons.group_outlined,
                label: t('crew'),
                badge: '${ref.watch(crewProvider).length}',
                onTap: () => context.push('/profile/crew'),
              ),
              _NavTile(
                icon: Icons.anchor_outlined,
                label: t('fishing_gear'),
                badge: '${ref.watch(gearProvider).length}',
                onTap: () => context.push('/profile/gear'),
              ),

              const SizedBox(height: 8),

              // Documents
              _SectionHeader(t('documents')),
              _NavTile(
                icon: Icons.folder_outlined,
                label: t('documents_wallet'),
                onTap: () => context.push('/profile/documents'),
              ),

              const SizedBox(height: 8),

              // Safety
              _SectionHeader(t('safety_center')),
              _NavTile(
                icon: Icons.checklist_rounded,
                label: t('pre_departure_checklist'),
                badge: '${checklist.checkedCount}/${checklist.totalCount}',
                badgeColor: checklist.isComplete ? Colors.green : AppColors.primaryBlue,
                onTap: () => context.push('/profile/safety'),
              ),

              const SizedBox(height: 8),

              // Preferences & Settings
              _SectionHeader(t('settings')),
              _NavTile(
                icon: Icons.language_outlined,
                label: t('settings_language'),
                hint: isArabic ? 'العربية' : 'English',
                onTap: () => context.push('/profile/settings'),
              ),
              _NavTile(
                icon: Icons.straighten_outlined,
                label: t('settings_units'),
                hint: ref.watch(preferencesProvider).isMetric
                    ? t('settings_units_metric')
                    : t('settings_units_imperial'),
                onTap: () => context.push('/profile/settings'),
              ),
              _NavTile(
                icon: Icons.notifications_outlined,
                label: t('settings_notifications'),
                onTap: () => context.push('/profile/settings'),
              ),
              _NavTile(
                icon: Icons.location_on_outlined,
                label: t('location_privacy'),
                onTap: () => context.push('/profile/settings'),
              ),

              const SizedBox(height: 8),

              // Support
              _SectionHeader(t('help')),
              _NavTile(
                icon: Icons.help_outline_rounded,
                label: t('help'),
                onTap: () => context.push('/profile/help'),
              ),
              _NavTile(
                icon: Icons.flag_outlined,
                label: t('report_issue'),
                onTap: () => context.push('/profile/report'),
              ),
              _NavTile(
                icon: Icons.info_outline_rounded,
                label: t('official_info'),
                onTap: () => context.push('/profile/official-info'),
              ),

              const SizedBox(height: 8),

              // Account
              _SectionHeader(t('settings_account')),
              _NavTile(
                icon: Icons.logout_rounded,
                label: t('settings_sign_out'),
                isDestructive: false,
                onTap: () => _confirmSignOut(context, isArabic),
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
            ? 'هل تريد تسجيل الخروج من بَحّار؟'
            : 'Are you sure you want to sign out of BAHHAR?'),
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
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final dynamic profile;
  final bool isArabic;
  const _ProfileHeader({required this.profile, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final name = isArabic && profile.fullNameArabic.isNotEmpty
        ? profile.fullNameArabic
        : profile.fullName;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FB),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.person_rounded, size: 40, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  profile.governorate,
                  style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                if (profile.fishermanId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      profile.fishermanId!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Completion Banner ─────────────────────────────────────────────────────────

class _CompletionBanner extends StatelessWidget {
  final int percentage;
  final bool isArabic;
  const _CompletionBanner({required this.percentage, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final t = (String k) => AppTranslations.t(k, isArabic);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EDF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('profile_completion'), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              Text(
                '${LocaleUtils.formatInt(percentage, isArabic)}% ${t('profile_complete')}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2EDF8),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 80 ? Colors.green : AppColors.primaryBlue,
              ),
            ),
          ),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Color(0xFF8FA9C8),
        ),
      ),
    );
  }
}

// ── Profile Info Tile ─────────────────────────────────────────────────────────

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
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
                  const SizedBox(height: 2),
                  Text(value, style: AppTextStyles.body),
                  if (hint != null)
                    Text(hint!, style: AppTextStyles.caption.copyWith(color: Colors.grey[500])),
                ],
              ),
            ),
            trailingWidget ?? Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ── Navigation Tile ────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final String? hint;
  final bool isDestructive;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    this.badge,
    this.badgeColor,
    this.hint,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : AppColors.primaryBlue;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.body.copyWith(color: isDestructive ? Colors.red : null)),
                  if (hint != null)
                    Text(hint!, style: AppTextStyles.caption.copyWith(color: Colors.grey[500])),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.primaryBlue).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: badgeColor ?? AppColors.primaryBlue,
                  ),
                ),
              ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
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
        style: TextStyle(fontSize: 12, color: AppColors.primaryBlue),
      ),
    );
  }
}

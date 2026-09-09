import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/fisherman_profile_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/localization/locale_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/crew_member_model.dart';

class CrewScreen extends ConsumerWidget {
  const CrewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    final crew = ref.watch(crewProvider);
    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: Text(t('crew')),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddSheet(context, ref, isArabic),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(t('add')),
          ),
        ],
      ),
      body: crew.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_outlined, size: 56, color: Color(0xFFB0C8E4)),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'لا يوجد أفراد طاقم مضافون بعد' : 'No crew members added yet',
                    style: const TextStyle(color: Color(0xFF8FA9C8), fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showAddSheet(context, ref, isArabic),
                    child: Text(t('add_crew')),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: crew.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _CrewCard(
                member: crew[i],
                isArabic: isArabic,
                onDelete: () => ref.read(crewProvider.notifier).remove(crew[i].id),
              ),
            ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, bool isArabic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddCrewForm(ref: ref, isArabic: isArabic),
    );
  }
}

class _CrewCard extends StatelessWidget {
  final CrewMemberModel member;
  final bool isArabic;
  final VoidCallback onDelete;
  const _CrewCard({required this.member, required this.isArabic, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EDF8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                child: const Icon(Icons.person_rounded, color: AppColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic && member.nameArabic.isNotEmpty ? member.nameArabic : member.name,
                      style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      isArabic && member.roleArabic.isNotEmpty ? member.roleArabic : member.role,
                      style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (member.phoneNumber != null || member.civilId != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F4F8)),
            const SizedBox(height: 12),
            if (member.phoneNumber != null)
              _Row(icon: Icons.phone_outlined, text: LocaleUtils.maskPhone(member.phoneNumber!)),
            if (member.civilId != null)
              _Row(icon: Icons.badge_outlined, text: LocaleUtils.maskId(member.civilId!)),
            if (member.fishingLicenceNumber != null)
              _Row(icon: Icons.card_membership_outlined, text: member.fishingLicenceNumber!),
            if (member.emergencyContactName != null)
              _Row(
                icon: Icons.emergency_outlined,
                text: '${member.emergencyContactName} · ${member.emergencyContactPhone ?? '—'}',
              ),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
              label: Text(AppTranslations.t('delete', isArabic), style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Row({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF8FA9C8)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _AddCrewForm extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final bool isArabic;
  const _AddCrewForm({required this.ref, required this.isArabic});
  @override
  ConsumerState<_AddCrewForm> createState() => _AddCrewFormState();
}

class _AddCrewFormState extends ConsumerState<_AddCrewForm> {
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _licCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String t(String k) => AppTranslations.t(k, widget.isArabic);
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('add_crew'), style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: t('crew_name'))),
          const SizedBox(height: 12),
          TextField(controller: _roleCtrl, decoration: InputDecoration(labelText: t('crew_role'), hintText: 'Captain, Deckhand...')),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl, decoration: InputDecoration(labelText: t('crew_phone')), keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          TextField(controller: _licCtrl, decoration: InputDecoration(labelText: t('crew_licence'))),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _save,
              child: Text(t('save')),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.isEmpty) return;
    ref.read(crewProvider.notifier).add(CrewMemberModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      role: _roleCtrl.text.trim().isEmpty ? 'Crew' : _roleCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      fishingLicenceNumber: _licCtrl.text.trim().isEmpty ? null : _licCtrl.text.trim(),
    ));
    Navigator.pop(context);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _roleCtrl.dispose(); _phoneCtrl.dispose(); _licCtrl.dispose(); super.dispose(); }
}

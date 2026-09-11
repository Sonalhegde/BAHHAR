import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/fisherman_profile_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/localization/locale_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/fishing_licence_model.dart';

class LicencesScreen extends ConsumerWidget {
  const LicencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    final licences = ref.watch(licencesProvider);
    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: Text(t('fishing_licences')),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddLicenceSheet(context, ref, isArabic),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(t('add')),
          ),
        ],
      ),
      body: licences.isEmpty
          ? _EmptyState(
              icon: Icons.card_membership_outlined,
              message: isArabic ? 'لا توجد تصاريح صيد مضافة بعد' : 'No fishing licences added yet',
              actionLabel: t('add_licence'),
              onAction: () => _showAddLicenceSheet(context, ref, isArabic),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: licences.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _LicenceCard(
                licence: licences[i],
                isArabic: isArabic,
                onDelete: () => ref.read(licencesProvider.notifier).remove(licences[i].id),
              ),
            ),
    );
  }

  void _showAddLicenceSheet(BuildContext context, WidgetRef ref, bool isArabic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddLicenceForm(ref: ref, isArabic: isArabic),
    );
  }
}

class _LicenceCard extends StatelessWidget {
  final FishingLicenceModel licence;
  final bool isArabic;
  final VoidCallback onDelete;

  const _LicenceCard({required this.licence, required this.isArabic, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final status = licence.computedStatus;
    final statusColor = switch (status) {
      LicenceStatus.valid => Colors.green,
      LicenceStatus.expiringSoon => Colors.orange,
      LicenceStatus.expired => Colors.red,
      LicenceStatus.pending => Colors.grey,
    };
    final statusLabel = switch (status) {
      LicenceStatus.valid => AppTranslations.t('valid', isArabic),
      LicenceStatus.expiringSoon => AppTranslations.t('expiring_soon', isArabic),
      LicenceStatus.expired => AppTranslations.t('expired', isArabic),
      LicenceStatus.pending => AppTranslations.t('pending', isArabic),
    };

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
              Expanded(
                child: Text(
                  isArabic && licence.licenceTypeArabic.isNotEmpty
                      ? licence.licenceTypeArabic
                      : licence.licenceType,
                  style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: AppTranslations.t('licence_number', isArabic),
            value: licence.licenceNumber,
          ),
          _InfoRow(
            label: AppTranslations.t('licence_expiry', isArabic),
            value: LocaleUtils.formatDate(licence.expiryDate, isArabic),
          ),
          _InfoRow(
            label: AppTranslations.t('licence_issuing_authority', isArabic),
            value: isArabic && licence.issuingAuthorityArabic.isNotEmpty
                ? licence.issuingAuthorityArabic
                : licence.issuingAuthority,
          ),
          if (status == LicenceStatus.expiringSoon)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${LocaleUtils.formatInt(licence.daysUntilExpiry, isArabic)} ${AppTranslations.t('days_until_expiry', isArabic)}',
                    style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 13, color: Color(0xFF8FA9C8))),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _AddLicenceForm extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final bool isArabic;
  const _AddLicenceForm({required this.ref, required this.isArabic});

  @override
  ConsumerState<_AddLicenceForm> createState() => _AddLicenceFormState();
}

class _AddLicenceFormState extends ConsumerState<_AddLicenceForm> {
  final _numCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _authCtrl = TextEditingController();
  DateTime? _issueDate;
  DateTime? _expiryDate;

  @override
  Widget build(BuildContext context) {
    String t(String k) => AppTranslations.t(k, widget.isArabic);
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('add_licence'), style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _numCtrl,
            decoration: InputDecoration(labelText: t('licence_number')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _typeCtrl,
            decoration: InputDecoration(labelText: t('licence_type')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _authCtrl,
            decoration: InputDecoration(labelText: t('licence_issuing_authority')),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _issueDate = d);
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(_issueDate != null
                      ? LocaleUtils.formatDate(_issueDate!, widget.isArabic)
                      : t('licence_issue_date')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2040),
                    );
                    if (d != null) setState(() => _expiryDate = d);
                  },
                  icon: const Icon(Icons.event_outlined, size: 16),
                  label: Text(_expiryDate != null
                      ? LocaleUtils.formatDate(_expiryDate!, widget.isArabic)
                      : t('licence_expiry')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
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
    if (_numCtrl.text.isEmpty || _issueDate == null || _expiryDate == null) return;
    final licence = FishingLicenceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      licenceNumber: _numCtrl.text.trim(),
      licenceType: _typeCtrl.text.trim().isEmpty ? 'Artisanal Fishing' : _typeCtrl.text.trim(),
      issueDate: _issueDate!,
      expiryDate: _expiryDate!,
      issuingAuthority: _authCtrl.text.trim().isEmpty
          ? 'Ministry of Agriculture, Fisheries and Water Resources'
          : _authCtrl.text.trim(),
      status: LicenceStatus.valid,
    );
    ref.read(licencesProvider.notifier).add(licence);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _numCtrl.dispose();
    _typeCtrl.dispose();
    _authCtrl.dispose();
    super.dispose();
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  const _EmptyState({required this.icon, required this.message, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: const Color(0xFFB0C8E4)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(0xFF8FA9C8), fontSize: 15)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

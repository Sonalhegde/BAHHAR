import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/fisherman_profile_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/localization/locale_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/document_model.dart';

class DocumentsWalletScreen extends ConsumerWidget {
  const DocumentsWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    final docs = ref.watch(documentsProvider);
    String t(String k) => AppTranslations.t(k, isArabic);

    final expiring = docs.where((d) => d.isExpiringSoon).toList();
    final expired = docs.where((d) => d.isExpired).toList();
    final valid = docs.where((d) => !d.isExpiringSoon && !d.isExpired).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: Text(t('documents_wallet')),
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
      body: docs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_outlined, size: 56, color: Color(0xFFB0C8E4)),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'لا توجد مستندات مضافة بعد' : 'No documents added yet',
                    style: const TextStyle(color: Color(0xFF8FA9C8), fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showAddSheet(context, ref, isArabic),
                    child: Text(t('add_document')),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (expired.isNotEmpty) ...[
                  _GroupHeader(isArabic ? 'منتهية الصلاحية' : 'Expired', Colors.red),
                  const SizedBox(height: 8),
                  ...expired.map((d) => _DocCard(doc: d, isArabic: isArabic,
                    onDelete: () => ref.read(documentsProvider.notifier).remove(d.id))),
                  const SizedBox(height: 16),
                ],
                if (expiring.isNotEmpty) ...[
                  _GroupHeader(isArabic ? 'تنتهي قريباً' : 'Expiring Soon', Colors.orange),
                  const SizedBox(height: 8),
                  ...expiring.map((d) => _DocCard(doc: d, isArabic: isArabic,
                    onDelete: () => ref.read(documentsProvider.notifier).remove(d.id))),
                  const SizedBox(height: 16),
                ],
                if (valid.isNotEmpty) ...[
                  _GroupHeader(isArabic ? 'سارية' : 'Valid', Colors.green),
                  const SizedBox(height: 8),
                  ...valid.map((d) => _DocCard(doc: d, isArabic: isArabic,
                    onDelete: () => ref.read(documentsProvider.notifier).remove(d.id))),
                ],
                const SizedBox(height: 80),
              ],
            ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, bool isArabic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddDocForm(ref: ref, isArabic: isArabic),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _GroupHeader(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _DocCard extends StatelessWidget {
  final DocumentModel doc;
  final bool isArabic;
  final VoidCallback onDelete;
  const _DocCard({required this.doc, required this.isArabic, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final days = doc.daysUntilExpiry;
    final expired = doc.isExpired;
    final expiringSoon = doc.isExpiringSoon;
    final statusColor = expired ? Colors.red : expiringSoon ? Colors.orange : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EDF8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description_outlined, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic && doc.titleArabic.isNotEmpty ? doc.titleArabic : doc.title.isNotEmpty ? doc.title : doc.type.labelEn,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  doc.documentNumber,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8FA9C8)),
                ),
                if (doc.expiryDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        expired
                            ? (isArabic ? 'منتهي الصلاحية' : 'Expired')
                            : '${AppTranslations.t('expires_in', isArabic)} ${LocaleUtils.formatInt(days!, isArabic)} ${AppTranslations.t('days', isArabic)}',
                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
          ),
        ],
      ),
    );
  }
}

class _AddDocForm extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final bool isArabic;
  const _AddDocForm({required this.ref, required this.isArabic});
  @override
  ConsumerState<_AddDocForm> createState() => _AddDocFormState();
}

class _AddDocFormState extends ConsumerState<_AddDocForm> {
  final _titleCtrl = TextEditingController();
  final _numCtrl = TextEditingController();
  DocumentType _selectedType = DocumentType.fishingLicence;
  DateTime? _expiryDate;

  @override
  Widget build(BuildContext context) {
    String t(String k) => AppTranslations.t(k, widget.isArabic);
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('add_document'), style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          DropdownButtonFormField<DocumentType>(
            value: _selectedType,
            decoration: InputDecoration(labelText: t('document_type')),
            items: DocumentType.values.map((dt) => DropdownMenuItem(
              value: dt,
              child: Text(widget.isArabic ? dt.labelAr : dt.labelEn),
            )).toList(),
            onChanged: (v) => setState(() => _selectedType = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: _titleCtrl, decoration: InputDecoration(labelText: t('document_type'), hintText: isArabic ? 'اسم المستند' : 'Document name')),
          const SizedBox(height: 12),
          TextField(controller: _numCtrl, decoration: InputDecoration(labelText: t('document_number'))),
          const SizedBox(height: 12),
          OutlinedButton.icon(
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
                : t('document_expiry')),
          ),
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

  get isArabic => widget.isArabic;

  void _save() {
    if (_numCtrl.text.isEmpty) return;
    ref.read(documentsProvider.notifier).add(DocumentModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      documentNumber: _numCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      expiryDate: _expiryDate,
    ));
    Navigator.pop(context);
  }

  @override
  void dispose() { _titleCtrl.dispose(); _numCtrl.dispose(); super.dispose(); }
}

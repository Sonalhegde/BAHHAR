import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/fisherman_profile_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/localization/locale_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/vessel_model.dart';

class VesselsScreen extends ConsumerWidget {
  const VesselsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    final vessels = ref.watch(vesselsProvider);
    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: Text(t('my_boats')),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddVesselSheet(context, ref, isArabic),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(t('add')),
          ),
        ],
      ),
      body: vessels.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sailing_outlined, size: 56, color: Color(0xFFB0C8E4)),
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'لا توجد قوارب مضافة بعد' : 'No boats added yet',
                    style: const TextStyle(color: Color(0xFF8FA9C8), fontSize: 15),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showAddVesselSheet(context, ref, isArabic),
                    child: Text(t('add_boat')),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vessels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _VesselCard(
                vessel: vessels[i],
                isArabic: isArabic,
                onDelete: () => ref.read(vesselsProvider.notifier).remove(vessels[i].id),
              ),
            ),
    );
  }

  void _showAddVesselSheet(BuildContext context, WidgetRef ref, bool isArabic) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddVesselForm(ref: ref, isArabic: isArabic),
    );
  }
}

class _VesselCard extends StatelessWidget {
  final VesselModel vessel;
  final bool isArabic;
  final VoidCallback onDelete;
  const _VesselCard({required this.vessel, required this.isArabic, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final navExpiringSoon = vessel.navLicenceExpiringSoon;
    final navExpired = vessel.navLicenceExpired;
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
              const Icon(Icons.sailing_rounded, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic && vessel.nameArabic.isNotEmpty ? vessel.nameArabic : vessel.name,
                      style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      isArabic && vessel.typeArabic.isNotEmpty ? vessel.typeArabic : vessel.type,
                      style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (vessel.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppTranslations.t('active', isArabic),
                    style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F4F8)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (vessel.registrationNumber.isNotEmpty)
                _Chip(label: AppTranslations.t('boat_registration', isArabic), value: vessel.registrationNumber),
              if (vessel.lengthMeters != null)
                _Chip(label: AppTranslations.t('boat_length', isArabic), value: LocaleUtils.formatLength(vessel.lengthMeters!, true, isArabic)),
              if (vessel.engineHp != null)
                _Chip(label: AppTranslations.t('boat_engine_hp', isArabic), value: LocaleUtils.formatInt(vessel.engineHp!, isArabic)),
              if (vessel.capacityPersons != null)
                _Chip(label: AppTranslations.t('boat_capacity', isArabic), value: LocaleUtils.formatInt(vessel.capacityPersons!, isArabic)),
            ],
          ),
          if (vessel.navLicenceExpiry != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  navExpired ? Icons.error_outline : navExpiringSoon ? Icons.warning_amber_rounded : Icons.verified_outlined,
                  size: 16,
                  color: navExpired ? Colors.red : navExpiringSoon ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  '${AppTranslations.t('boat_nav_licence', isArabic)}: ${LocaleUtils.formatDate(vessel.navLicenceExpiry!, isArabic)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: navExpired ? Colors.red : navExpiringSoon ? Colors.orange : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
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

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  const _Chip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8FA9C8))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AddVesselForm extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final bool isArabic;
  const _AddVesselForm({required this.ref, required this.isArabic});

  @override
  ConsumerState<_AddVesselForm> createState() => _AddVesselFormState();
}

class _AddVesselFormState extends ConsumerState<_AddVesselForm> {
  final _nameCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    String t(String k) => AppTranslations.t(k, widget.isArabic);
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('add_boat'), style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: t('boat_name'))),
          const SizedBox(height: 12),
          TextField(controller: _regCtrl, decoration: InputDecoration(labelText: t('boat_registration'))),
          const SizedBox(height: 12),
          TextField(controller: _typeCtrl, decoration: InputDecoration(labelText: t('boat_type'), hintText: 'Dhow, Motorboat...')),
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
    if (_nameCtrl.text.isEmpty) return;
    final vessel = VesselModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      registrationNumber: _regCtrl.text.trim(),
      type: _typeCtrl.text.trim().isEmpty ? 'Fishing Vessel' : _typeCtrl.text.trim(),
    );
    ref.read(vesselsProvider.notifier).add(vessel);
    Navigator.pop(context);
  }

  @override
  void dispose() { _nameCtrl.dispose(); _regCtrl.dispose(); _typeCtrl.dispose(); super.dispose(); }
}

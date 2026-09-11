import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/fisherman_profile_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/models/fisherman_profile_model.dart';

class EditPersonalInfoScreen extends ConsumerStatefulWidget {
  const EditPersonalInfoScreen({super.key});

  @override
  ConsumerState<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends ConsumerState<EditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _nameArCtrl;
  late TextEditingController _civilIdCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _altPhoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _wilayatCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _emergNameCtrl;
  late TextEditingController _emergNameArCtrl;
  late TextEditingController _emergPhoneCtrl;
  late TextEditingController _emergRelCtrl;
  String _selectedGovernorate = 'Muscat';
  bool _civilIdRevealed = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(fishermanProfileProvider);
    _nameCtrl = TextEditingController(text: profile.fullName);
    _nameArCtrl = TextEditingController(text: profile.fullNameArabic);
    _civilIdCtrl = TextEditingController(text: profile.civilId);
    _phoneCtrl = TextEditingController(text: profile.phoneNumber);
    _altPhoneCtrl = TextEditingController(text: profile.alternatePhone ?? '');
    _emailCtrl = TextEditingController(text: profile.email ?? '');
    _wilayatCtrl = TextEditingController(text: profile.wilayat ?? '');
    _addressCtrl = TextEditingController(text: profile.address ?? '');
    _emergNameCtrl = TextEditingController(text: profile.emergencyContact?.name ?? '');
    _emergNameArCtrl = TextEditingController(text: profile.emergencyContact?.nameArabic ?? '');
    _emergPhoneCtrl = TextEditingController(text: profile.emergencyContact?.phoneNumber ?? '');
    _emergRelCtrl = TextEditingController(text: profile.emergencyContact?.relationship ?? '');
    _selectedGovernorate = profile.governorate;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(isArabicProvider);
    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        title: Text(t('personal_info')),
        backgroundColor: AppColors.surfacePure,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => _save(isArabic),
            child: Text(
              t('save'),
              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(isArabic ? 'الاسم والهوية' : 'Name & Identity'),
            _Field(
              label: t('full_name'),
              controller: _nameCtrl,
              validator: (v) => Validators.name(v, isArabic: isArabic),
            ),
            _Field(
              label: '${t('full_name')} (العربية)',
              controller: _nameArCtrl,
              validator: (v) => Validators.name(v, isArabic: isArabic, requiredField: false),
            ),
            _CivilIdField(
              label: t('civil_id'),
              controller: _civilIdCtrl,
              revealed: _civilIdRevealed,
              onToggleReveal: () => setState(() => _civilIdRevealed = !_civilIdRevealed),
              isArabic: isArabic,
            ),

            _Section(isArabic ? 'معلومات الاتصال' : 'Contact'),
            _Field(
              label: t('phone_number'),
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              validator: (v) => Validators.omanPhone(v, isArabic: isArabic),
            ),
            _Field(
              label: '${t('phone_number')} (${isArabic ? 'بديل' : 'Alternate'})',
              controller: _altPhoneCtrl,
              keyboardType: TextInputType.phone,
              validator: (v) => Validators.omanPhone(v, isArabic: isArabic, requiredField: false),
            ),
            _Field(
              label: t('email'),
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => Validators.email(v, isArabic: isArabic),
            ),

            _Section(isArabic ? 'الموقع' : 'Location'),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surfacePure,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedGovernorate,
                decoration: InputDecoration(
                  labelText: t('governorate'),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: AppTranslations.governorates.map((g) => DropdownMenuItem(
                  value: g['en'],
                  child: Text(isArabic ? AppTranslations.t(g['key']!, isArabic) : g['en']!),
                )).toList(),
                onChanged: (v) => setState(() => _selectedGovernorate = v!),
              ),
            ),
            _Field(label: t('wilayat'), controller: _wilayatCtrl),
            _Field(label: t('address'), controller: _addressCtrl),

            _Section(isArabic ? 'جهة الاتصال في الطوارئ' : 'Emergency Contact'),
            _Field(
              label: t('emergency_contact_name'),
              controller: _emergNameCtrl,
              validator: (v) => Validators.name(v, isArabic: isArabic, requiredField: false),
            ),
            _Field(
              label: '${t('emergency_contact_name')} (العربية)',
              controller: _emergNameArCtrl,
            ),
            _Field(
              label: t('emergency_contact_phone'),
              controller: _emergPhoneCtrl,
              keyboardType: TextInputType.phone,
              validator: (v) => Validators.omanPhone(v, isArabic: isArabic, requiredField: false),
            ),
            _Field(label: t('emergency_contact_relation'), controller: _emergRelCtrl),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _save(bool isArabic) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(isArabic
              ? 'يرجى تصحيح الحقول المميزة'
              : 'Please correct the highlighted fields'),
          backgroundColor: AppColors.signalAlert,
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }

    final notifier = ref.read(fishermanProfileProvider.notifier);
    notifier.updatePersonalInfo(
      fullName: _nameCtrl.text.trim(),
      fullNameArabic: _nameArCtrl.text.trim(),
      civilId: _civilIdCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      alternatePhone: _altPhoneCtrl.text.trim().isEmpty ? null : _altPhoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      governorate: _selectedGovernorate,
      wilayat: _wilayatCtrl.text.trim().isEmpty ? null : _wilayatCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
    );
    if (_emergNameCtrl.text.trim().isNotEmpty || _emergPhoneCtrl.text.trim().isNotEmpty) {
      notifier.updateEmergencyContact(EmergencyContactModel(
        name: _emergNameCtrl.text.trim(),
        nameArabic: _emergNameArCtrl.text.trim(),
        relationship: _emergRelCtrl.text.trim(),
        phoneNumber: _emergPhoneCtrl.text.trim(),
      ));
    }

    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(isArabic ? 'تم حفظ التغييرات' : 'Changes saved'),
        backgroundColor: AppColors.signalGood,
        behavior: SnackBarBehavior.floating,
      ));
    context.pop();
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _nameArCtrl, _civilIdCtrl, _phoneCtrl, _altPhoneCtrl,
      _emailCtrl, _wilayatCtrl, _addressCtrl, _emergNameCtrl, _emergNameArCtrl,
      _emergPhoneCtrl, _emergRelCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfacePure,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          errorStyle: const TextStyle(color: AppColors.signalAlert),
        ),
      ),
    );
  }
}

class _CivilIdField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final bool isArabic;

  const _CivilIdField({
    required this.label,
    required this.controller,
    required this.revealed,
    required this.onToggleReveal,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfacePure,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: !revealed,
              keyboardType: TextInputType.number,
              validator: (v) => Validators.civilId(v, isArabic: isArabic),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                errorStyle: const TextStyle(color: AppColors.signalAlert),
              ),
            ),
          ),
          TextButton(
            onPressed: onToggleReveal,
            child: Text(
              revealed
                  ? AppTranslations.t('hide', isArabic)
                  : AppTranslations.t('show', isArabic),
              style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}

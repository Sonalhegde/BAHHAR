import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/safety_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/models/safety_checklist_model.dart';

class SafetyCenterScreen extends ConsumerWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    final checklist = ref.watch(safetyChecklistProvider);
    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: Text(t('safety_center')),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: () => ref.read(safetyChecklistProvider.notifier).resetAll(),
            child: Text(isArabic ? 'إعادة تعيين' : 'Reset', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress card
          _ProgressCard(checklist: checklist, isArabic: isArabic),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              t('pre_departure_checklist'),
              style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w700),
            ),
          ),

          // Checklist items
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2EDF8)),
            ),
            child: Column(
              children: ChecklistItemKey.values.asMap().entries.map((entry) {
                final index = entry.key;
                final key = entry.value;
                final item = checklist.items.firstWhere((i) => i.key == key);
                return _ChecklistTile(
                  item: item,
                  isArabic: isArabic,
                  isLast: index == ChecklistItemKey.values.length - 1,
                  onToggle: () => ref.read(safetyChecklistProvider.notifier).toggle(key),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Emergency contact reminder
          _EmergencyReminder(isArabic: isArabic),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final SafetyChecklistModel checklist;
  final bool isArabic;
  const _ProgressCard({required this.checklist, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final isComplete = checklist.isComplete;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isComplete ? const Color(0xFFE8F8EE) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete ? Colors.green.withValues(alpha: 0.3) : const Color(0xFFE2EDF8),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isComplete ? Icons.check_circle_rounded : Icons.checklist_rounded,
                color: isComplete ? Colors.green : AppColors.primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isComplete
                      ? AppTranslations.t('safety_complete', isArabic)
                      : '${checklist.checkedCount} / ${checklist.totalCount} ${isArabic ? 'مكتملة' : 'completed'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isComplete ? Colors.green[700] : AppColors.oceanNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: checklist.completionRatio,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2EDF8),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final ChecklistItem item;
  final bool isArabic;
  final bool isLast;
  final VoidCallback onToggle;
  const _ChecklistTile({required this.item, required this.isArabic, required this.isLast, required this.onToggle});

  String _label(ChecklistItemKey key, bool isArabic) {
    final map = {
      ChecklistItemKey.lifeJackets: 'checklist_life_jackets',
      ChecklistItemKey.fuel: 'checklist_fuel',
      ChecklistItemKey.engineCheck: 'checklist_engine',
      ChecklistItemKey.navEquipment: 'checklist_nav_equipment',
      ChecklistItemKey.comms: 'checklist_comms',
      ChecklistItemKey.emergencyGear: 'checklist_emergency_gear',
      ChecklistItemKey.water: 'checklist_water',
      ChecklistItemKey.documents: 'checklist_documents',
      ChecklistItemKey.weather: 'checklist_weather',
      ChecklistItemKey.floatPlan: 'checklist_float_plan',
    };
    return AppTranslations.t(map[key]!, isArabic);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: item.isChecked ? AppColors.primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.isChecked ? AppColors.primaryBlue : const Color(0xFFB0C8E4),
                      width: 2,
                    ),
                  ),
                  child: item.isChecked
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _label(item.key, isArabic),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
                      color: item.isChecked ? Colors.grey[500] : AppColors.oceanNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) const Divider(height: 1, indent: 54, color: Color(0xFFF0F4F8)),
        ],
      ),
    );
  }
}

class _EmergencyReminder extends StatelessWidget {
  final bool isArabic;
  const _EmergencyReminder({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.emergency_outlined, color: Colors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'تذكير بجهة الطوارئ' : 'Emergency Contact Reminder',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF7B4A00)),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic
                      ? 'تأكد من إبلاغ جهة الاتصال البرية الخاصة بك بخطة رحلتك قبل المغادرة.'
                      : 'Make sure your shore-based emergency contact knows your trip plan before departure.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF7B4A00), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/providers/safety_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/localization/locale_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/report_issue_model.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  IssueCategory _category = IssueCategory.appProblem;
  final _descCtrl = TextEditingController();
  ReportIssueModel? _submitted;

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(isArabicProvider);
    final pastIssues = ref.watch(reportIssuesProvider);
    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: Text(t('report_issue')),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_submitted != null) _SuccessBanner(issue: _submitted!, isArabic: isArabic),

          // Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2EDF8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('issue_category'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF8FA9C8))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: IssueCategory.values.map((cat) {
                    final selected = _category == cat;
                    return FilterChip(
                      selected: selected,
                      label: Text(isArabic ? cat.labelAr : cat.labelEn),
                      onSelected: (_) => setState(() => _category = cat),
                      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primaryBlue,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.primaryBlue : Colors.grey[600],
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(t('issue_description'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF8FA9C8))),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: isArabic ? 'صف المشكلة بالتفصيل…' : 'Describe the issue in detail…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: const Color(0xFFF4F8FC),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: Text(isArabic ? 'إرسال البلاغ' : 'Submit Report'),
                  ),
                ),
              ],
            ),
          ),

          // Past issues
          if (pastIssues.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              isArabic ? 'البلاغات السابقة' : 'Previous Reports',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: Color(0xFF8FA9C8)),
            ),
            const SizedBox(height: 8),
            ...pastIssues.reversed.map((issue) => _IssueStatusCard(issue: issue, isArabic: isArabic)),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _submit() {
    final isArabic = ref.read(isArabicProvider);
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isArabic ? 'يرجى وصف المشكلة' : 'Please describe the issue'),
      ));
      return;
    }
    final issue = ref.read(reportIssuesProvider.notifier).submit(
      category: _category,
      description: _descCtrl.text.trim(),
    );
    setState(() { _submitted = issue; _descCtrl.clear(); });
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() { _descCtrl.dispose(); super.dispose(); }
}

class _SuccessBanner extends StatelessWidget {
  final ReportIssueModel issue;
  final bool isArabic;
  const _SuccessBanner({required this.issue, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.t('issue_submitted', isArabic),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppTranslations.t('issue_id', isArabic)}: ${issue.referenceId}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1B5E20)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueStatusCard extends StatelessWidget {
  final ReportIssueModel issue;
  final bool isArabic;
  const _IssueStatusCard({required this.issue, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (issue.status) {
      IssueStatus.submitted => Colors.blue,
      IssueStatus.underReview => Colors.orange,
      IssueStatus.resolved => Colors.green,
    };
    final statusLabel = switch (issue.status) {
      IssueStatus.submitted => AppTranslations.t('issue_submitted', isArabic),
      IssueStatus.underReview => AppTranslations.t('issue_under_review', isArabic),
      IssueStatus.resolved => AppTranslations.t('issue_resolved', isArabic),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
                  isArabic ? issue.category.labelAr : issue.category.labelEn,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(issue.referenceId, style: const TextStyle(fontSize: 12, color: Color(0xFF8FA9C8))),
          const SizedBox(height: 4),
          Text(
            issue.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleUtils.formatDate(issue.submittedAt, isArabic),
            style: const TextStyle(fontSize: 12, color: Color(0xFF8FA9C8)),
          ),
        ],
      ),
    );
  }
}

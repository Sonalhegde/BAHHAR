import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/safety_checklist_model.dart';
import '../models/report_issue_model.dart';

// ─── Safety Checklist Provider ────────────────────────────────────────────────

class SafetyChecklistNotifier extends StateNotifier<SafetyChecklistModel> {
  SafetyChecklistNotifier() : super(SafetyChecklistModel.createFresh());

  void toggle(ChecklistItemKey key) {
    state = state.withToggled(key);
  }

  void resetAll() {
    state = state.withReset();
  }

  void startNewChecklist() {
    state = SafetyChecklistModel.createFresh();
  }
}

final safetyChecklistProvider =
    StateNotifierProvider<SafetyChecklistNotifier, SafetyChecklistModel>(
        (ref) => SafetyChecklistNotifier());

// ─── Report Issues Provider ───────────────────────────────────────────────────

class ReportIssuesNotifier extends StateNotifier<List<ReportIssueModel>> {
  ReportIssuesNotifier() : super([]);

  String _generateRef() {
    final now = DateTime.now();
    return 'BHR-${now.year}${now.month.toString().padLeft(2, '0')}'
        '-${(state.length + 1001)}';
  }

  ReportIssueModel submit({
    required IssueCategory category,
    required String description,
  }) {
    final issue = ReportIssueModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      referenceId: _generateRef(),
      category: category,
      description: description,
      status: IssueStatus.submitted,
      submittedAt: DateTime.now(),
    );
    state = [...state, issue];
    return issue;
  }

  void updateStatus(String id, IssueStatus status) {
    state = state.map((i) {
      if (i.id == id) {
        return ReportIssueModel(
          id: i.id,
          referenceId: i.referenceId,
          category: i.category,
          description: i.description,
          status: status,
          submittedAt: i.submittedAt,
          resolvedAt: status == IssueStatus.resolved ? DateTime.now() : null,
        );
      }
      return i;
    }).toList();
  }
}

final reportIssuesProvider =
    StateNotifierProvider<ReportIssuesNotifier, List<ReportIssueModel>>(
        (ref) => ReportIssuesNotifier());

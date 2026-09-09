enum IssueCategory { appProblem, incorrectData, safetyConcern, mapLocation, other }
enum IssueStatus { submitted, underReview, resolved }

extension IssueCategoryLabel on IssueCategory {
  String get labelEn {
    switch (this) {
      case IssueCategory.appProblem: return 'App Problem';
      case IssueCategory.incorrectData: return 'Incorrect Data';
      case IssueCategory.safetyConcern: return 'Safety Concern';
      case IssueCategory.mapLocation: return 'Map / Location';
      case IssueCategory.other: return 'Other';
    }
  }
  String get labelAr {
    switch (this) {
      case IssueCategory.appProblem: return 'مشكلة في التطبيق';
      case IssueCategory.incorrectData: return 'بيانات غير صحيحة';
      case IssueCategory.safetyConcern: return 'مخاوف السلامة';
      case IssueCategory.mapLocation: return 'الخريطة / الموقع';
      case IssueCategory.other: return 'أخرى';
    }
  }
}

class ReportIssueModel {
  final String id;
  final String referenceId;
  final IssueCategory category;
  final String description;
  final IssueStatus status;
  final DateTime submittedAt;
  final DateTime? resolvedAt;

  const ReportIssueModel({
    required this.id,
    required this.referenceId,
    required this.category,
    required this.description,
    required this.status,
    required this.submittedAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'referenceId': referenceId,
    'category': category.name,
    'description': description,
    'status': status.name,
    'submittedAt': submittedAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
  };

  factory ReportIssueModel.fromJson(Map<String, dynamic> json) {
    return ReportIssueModel(
      id: json['id'] as String? ?? '',
      referenceId: json['referenceId'] as String? ?? '',
      category: IssueCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => IssueCategory.other,
      ),
      description: json['description'] as String? ?? '',
      status: IssueStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => IssueStatus.submitted,
      ),
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
    );
  }
}

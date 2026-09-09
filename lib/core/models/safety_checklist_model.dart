enum ChecklistItemKey {
  lifeJackets,
  fuel,
  engineCheck,
  navEquipment,
  comms,
  emergencyGear,
  water,
  documents,
  weather,
  floatPlan,
}

class ChecklistItem {
  final ChecklistItemKey key;
  final bool isChecked;

  const ChecklistItem({required this.key, this.isChecked = false});

  ChecklistItem copyWith({bool? isChecked}) =>
      ChecklistItem(key: key, isChecked: isChecked ?? this.isChecked);
}

class SafetyChecklistModel {
  final String id;
  final DateTime createdAt;
  final List<ChecklistItem> items;

  const SafetyChecklistModel({
    required this.id,
    required this.createdAt,
    required this.items,
  });

  int get checkedCount => items.where((i) => i.isChecked).length;
  int get totalCount => items.length;
  bool get isComplete => checkedCount == totalCount;
  double get completionRatio => totalCount == 0 ? 0 : checkedCount / totalCount;

  static SafetyChecklistModel createFresh() {
    return SafetyChecklistModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      items: ChecklistItemKey.values
          .map((k) => ChecklistItem(key: k))
          .toList(),
    );
  }

  SafetyChecklistModel withToggled(ChecklistItemKey key) {
    return SafetyChecklistModel(
      id: id,
      createdAt: createdAt,
      items: items.map((item) {
        if (item.key == key) return item.copyWith(isChecked: !item.isChecked);
        return item;
      }).toList(),
    );
  }

  SafetyChecklistModel withReset() {
    return SafetyChecklistModel(
      id: id,
      createdAt: createdAt,
      items: items.map((i) => i.copyWith(isChecked: false)).toList(),
    );
  }
}

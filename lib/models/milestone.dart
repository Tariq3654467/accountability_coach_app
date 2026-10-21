import 'enums.dart';

class Milestone {
  final String id;
  final String text;
  final bool done;
  final DateTime addedAt;
  final DateTime? doneAt;
  final Tier tier;
  final DateTime dueDate;
  final int weight;
  final List<String> completedDates;
  final List<MilestoneSubtask> subtasks;

  const Milestone({
    required this.id,
    required this.text,
    this.done = false,
    required this.addedAt,
    this.doneAt,
    this.tier = Tier.daily,
    DateTime? dueDate,
    this.weight = 1,
    this.completedDates = const [],
    this.subtasks = const [],
  }) : dueDate = dueDate ?? addedAt;

  bool isDoneOn(DateTime date) {
    final key = _dateKey(date);
    if (tier == Tier.daily) return completedDates.contains(key);
    return done;
  }

  Milestone copyWith({
    String? text,
    bool? done,
    DateTime? doneAt,
    bool clearDoneAt = false,
    Tier? tier,
    DateTime? dueDate,
    int? weight,
    List<String>? completedDates,
    List<MilestoneSubtask>? subtasks,
  }) {
    return Milestone(
      id: id,
      text: text ?? this.text,
      done: done ?? this.done,
      addedAt: addedAt,
      doneAt: clearDoneAt ? null : (doneAt ?? this.doneAt),
      tier: tier ?? this.tier,
      dueDate: dueDate ?? this.dueDate,
      weight: weight ?? this.weight,
      completedDates: completedDates ?? this.completedDates,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'done': done,
        'added_at': addedAt.millisecondsSinceEpoch,
        'done_at': doneAt?.millisecondsSinceEpoch,
        'tier': tier.name,
        'due_date': _dateKey(dueDate),
        'weight': weight,
        'completed_dates': completedDates,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory Milestone.fromJson(Map<String, dynamic> j) {
    final addedAt = DateTime.fromMillisecondsSinceEpoch(
      (j['added_at'] ?? DateTime.now().millisecondsSinceEpoch) as int,
    );
    final rawSubtasks = j['subtasks'];
    final rawCompletedDates = j['completed_dates'] ?? j['completedDates'];
    final rawDoneAt = j['done_at'];
    return Milestone(
      id: j['id'] as String,
      text: (j['text'] ?? j['title'] ?? '') as String,
      done: (j['done'] ?? false) as bool,
      addedAt: addedAt,
      doneAt: rawDoneAt == null
          ? (j['completedAt'] is String && (j['completedAt'] as String).isNotEmpty
              ? DateTime.tryParse(j['completedAt'] as String)
              : null)
          : rawDoneAt is int
              ? DateTime.fromMillisecondsSinceEpoch(rawDoneAt)
              : DateTime.tryParse(rawDoneAt.toString()),
      tier: enumByName(
        Tier.values,
        (j['tier'] as String?)?.toLowerCase(),
        Tier.daily,
      ),
      dueDate: DateTime.tryParse((j['due_date'] ?? j['dueDate'] ?? '') as String) ?? addedAt,
      weight: ((j['weight'] ?? 1) as num).toInt().clamp(1, 10),
      completedDates: (rawCompletedDates is List ? rawCompletedDates : const [])
          .whereType<String>()
          .toSet()
          .toList(),
      subtasks: rawSubtasks is List
          ? rawSubtasks
              .whereType<Map>()
              .map((e) => MilestoneSubtask.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class MilestoneSubtask {
  const MilestoneSubtask({
    required this.id,
    required this.title,
    this.weight = 1,
    this.completedDates = const [],
  });

  final String id;
  final String title;
  final int weight;
  final List<String> completedDates;

  MilestoneSubtask copyWith({String? title, int? weight, List<String>? completedDates}) =>
      MilestoneSubtask(
        id: id,
        title: title ?? this.title,
        weight: weight ?? this.weight,
        completedDates: completedDates ?? this.completedDates,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'weight': weight,
        'completedDates': completedDates,
      };

  factory MilestoneSubtask.fromJson(Map<String, dynamic> j) => MilestoneSubtask(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        weight: ((j['weight'] ?? 1) as num).toInt().clamp(1, 10),
        completedDates: (j['completedDates'] as List? ?? const []).whereType<String>().toSet().toList(),
      );
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

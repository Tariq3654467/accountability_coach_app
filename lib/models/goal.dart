import 'enums.dart';
import 'milestone.dart';

class Goal {
  final String id;
  final String name;
  final String sectorId;
  final GoalType type;
  final String target;
  final DateTime? deadline;
  final Cadence cadence;
  final ReminderStyle reminderStyle;
  final String notes;
  final String status;
  final DateTime createdAt;
  final Map<Tier, List<Milestone>> milestones;

  const Goal({
    required this.id,
    required this.name,
    required this.sectorId,
    this.type = GoalType.routine,
    this.target = '',
    this.deadline,
    this.cadence = Cadence.daily,
    this.reminderStyle = ReminderStyle.gentle,
    this.notes = '',
    this.status = 'active',
    required this.createdAt,
    required this.milestones,
  });

  static Map<Tier, List<Milestone>> emptyTiers() =>
      {for (final t in Tier.values) t: <Milestone>[]};

  List<Milestone> milestonesOf(Tier t) => milestones[t] ?? const [];

  Iterable<Milestone> get allMilestones => Tier.values.expand(milestonesOf);

  int get totalCount => allMilestones.length;
  int get doneCount => allMilestones.fold(
        0,
        (count, milestone) => count +
            (milestone.tier == Tier.daily
                ? milestone.completedDates.length
                : milestone.done
                    ? 1
                    : 0),
      );

  Goal copyWith({
    String? name,
    String? sectorId,
    GoalType? type,
    String? target,
    DateTime? deadline,
    bool clearDeadline = false,
    Cadence? cadence,
    ReminderStyle? reminderStyle,
    String? notes,
    String? status,
    Map<Tier, List<Milestone>>? milestones,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      sectorId: sectorId ?? this.sectorId,
      type: type ?? this.type,
      target: target ?? this.target,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      cadence: cadence ?? this.cadence,
      reminderStyle: reminderStyle ?? this.reminderStyle,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt,
      milestones: milestones ?? this.milestones,
    );
  }

  /// Snake_case map matching the Supabase `goals` table (milestones = jsonb).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sector_id': sectorId,
        'type': type.name,
        'target': target,
        'deadline': deadline?.toIso8601String(),
        'cadence': cadence.name,
        'reminder_style': reminderStyle.name,
        'notes': notes,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'milestones': {
          for (final t in Tier.values)
            t.name: milestonesOf(t).map((m) => m.toJson()).toList(),
        },
      };

  factory Goal.fromJson(Map<String, dynamic> j) {
    final tiers = emptyTiers();
    final raw = j['milestones'];
    if (raw is List) {
      for (final entry in raw.whereType<Map>()) {
        final milestone = Milestone.fromJson(Map<String, dynamic>.from(entry));
        tiers[milestone.tier]!.add(milestone);
      }
    } else if (raw is Map) {
      for (final t in Tier.values) {
        final list = raw[t.name];
        if (list is List) {
          tiers[t] = list.whereType<Map>().map((e) {
            final milestone = Milestone.fromJson(Map<String, dynamic>.from(e));
            return milestone.copyWith(tier: t);
          }).toList();
        }
      }
    }
    final rawDeadline = j['deadline'];
    final rawCreatedAt = j['created_at'] ?? j['createdAt'];
    return Goal(
      id: (j['id'] ?? '') as String,
      name: (j['name'] ?? j['title'] ?? '') as String,
      sectorId: (j['sector_id'] ?? j['sector'] ?? 'custom') as String,
      type: _goalType(j['type'] as String?),
      target: (j['target'] ?? '') as String,
      deadline: rawDeadline == null || rawDeadline.toString().isEmpty
          ? null
          : DateTime.tryParse(rawDeadline.toString()),
      cadence: _cadence(j['cadence'] as String?),
      reminderStyle: _reminderStyle(j['reminder_style'] as String? ?? j['reminderStyle'] as String?),
      notes: (j['notes'] ?? '') as String,
      status: (j['status'] ?? 'active') as String,
      createdAt: rawCreatedAt == null
          ? DateTime.now()
          : DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now(),
      milestones: tiers,
    );
  }

  static GoalType _goalType(String? value) {
    final normalized = value?.toLowerCase();
    switch (normalized) {
      case 'habit':
        return GoalType.habit;
      case 'skill':
        return GoalType.skill;
      case 'project':
        return GoalType.project;
      case 'task':
      case 'milestone':
        return GoalType.task;
      default:
        return enumByName(GoalType.values, normalized, GoalType.routine);
    }
  }

  static Cadence _cadence(String? value) {
    switch (value?.toLowerCase()) {
      case '3x weekly':
        return Cadence.threeWeekly;
      case '5x weekly':
        return Cadence.weekly;
      case 'weekly':
        return Cadence.onceWeekly;
      case 'flexible':
        return Cadence.flexible;
      default:
        return enumByName(Cadence.values, value?.toLowerCase(), Cadence.daily);
    }
  }

  static ReminderStyle _reminderStyle(String? value) {
    switch (value?.toLowerCase()) {
      case 'encouraging':
        return ReminderStyle.encouraging;
      case 'none':
        return ReminderStyle.none;
      default:
        return enumByName(ReminderStyle.values, value?.toLowerCase(), ReminderStyle.gentle);
    }
  }
}

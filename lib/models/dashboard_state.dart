class DashboardSubtask {
  const DashboardSubtask({
    required this.id,
    required this.title,
    this.completedDates = const [],
  });

  final String id;
  final String title;
  final List<String> completedDates;

  bool isDone(String date) => completedDates.contains(date);

  DashboardSubtask copyWith({String? title, List<String>? completedDates}) =>
      DashboardSubtask(
        id: id,
        title: title ?? this.title,
        completedDates: completedDates ?? this.completedDates,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'completedDates': completedDates};

  factory DashboardSubtask.fromJson(Map<String, dynamic> json) =>
      DashboardSubtask(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        completedDates:
            (json['completedDates'] as List? ?? const []).whereType<String>().toSet().toList(),
      );
}

class TaskArea {
  const TaskArea({
    required this.id,
    required this.title,
    this.goalId = '',
    this.completedDates = const [],
    this.subtasks = const [],
  });

  final String id;
  final String title;
  final String goalId;
  final List<String> completedDates;
  final List<DashboardSubtask> subtasks;

  bool isDone(String date) => completedDates.contains(date);

  TaskArea copyWith({
    String? title,
    String? goalId,
    List<String>? completedDates,
    List<DashboardSubtask>? subtasks,
  }) =>
      TaskArea(
        id: id,
        title: title ?? this.title,
        goalId: goalId ?? this.goalId,
        completedDates: completedDates ?? this.completedDates,
        subtasks: subtasks ?? this.subtasks,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'goalId': goalId,
        'completedDates': completedDates,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
      };

  factory TaskArea.fromJson(Map<String, dynamic> json) => TaskArea(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        goalId: json['goalId'] as String? ?? '',
        completedDates:
            (json['completedDates'] as List? ?? const []).whereType<String>().toSet().toList(),
        subtasks: (json['subtasks'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => DashboardSubtask.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class ReminderPreferences {
  const ReminderPreferences({
    this.notificationsEnabled = false,
    this.reminderTime = '09:00',
    this.dailyCheckInsEnabled = false,
    this.dayStartTime = '09:00',
    this.dayEndTime = '20:00',
    this.showPastTasks = false,
  });

  final bool notificationsEnabled;
  final String reminderTime;
  final bool dailyCheckInsEnabled;
  final String dayStartTime;
  final String dayEndTime;
  final bool showPastTasks;

  ReminderPreferences copyWith({
    bool? notificationsEnabled,
    String? reminderTime,
    bool? dailyCheckInsEnabled,
    String? dayStartTime,
    String? dayEndTime,
    bool? showPastTasks,
  }) =>
      ReminderPreferences(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        reminderTime: reminderTime ?? this.reminderTime,
        dailyCheckInsEnabled: dailyCheckInsEnabled ?? this.dailyCheckInsEnabled,
        dayStartTime: dayStartTime ?? this.dayStartTime,
        dayEndTime: dayEndTime ?? this.dayEndTime,
        showPastTasks: showPastTasks ?? this.showPastTasks,
      );

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'reminderTime': reminderTime,
        'dailyCheckInsEnabled': dailyCheckInsEnabled,
        'dayStartTime': dayStartTime,
        'dayEndTime': dayEndTime,
        'showPastTasks': showPastTasks,
      };

  factory ReminderPreferences.fromJson(Map<String, dynamic> json) =>
      ReminderPreferences(
        notificationsEnabled: json['notificationsEnabled'] == true,
        reminderTime: json['reminderTime'] as String? ?? '09:00',
        dailyCheckInsEnabled: json['dailyCheckInsEnabled'] == true,
        dayStartTime: json['dayStartTime'] as String? ?? '09:00',
        dayEndTime: json['dayEndTime'] as String? ?? '20:00',
        showPastTasks: json['showPastTasks'] == true,
      );
}

class DashboardState {
  const DashboardState({
    this.taskAreas = const [],
    this.planReviews = const {'7': '', '15': '', '30': ''},
    this.preferences = const ReminderPreferences(),
  });

  final List<TaskArea> taskAreas;
  final Map<String, String> planReviews;
  final ReminderPreferences preferences;

  DashboardState copyWith({
    List<TaskArea>? taskAreas,
    Map<String, String>? planReviews,
    ReminderPreferences? preferences,
  }) =>
      DashboardState(
        taskAreas: taskAreas ?? this.taskAreas,
        planReviews: planReviews ?? this.planReviews,
        preferences: preferences ?? this.preferences,
      );

  Map<String, dynamic> toJson() => {
        'taskAreas': taskAreas.map((a) => a.toJson()).toList(),
        'planReviews': planReviews,
        'preferences': preferences.toJson(),
      };

  factory DashboardState.fromJson(Map<String, dynamic> json) => DashboardState(
        taskAreas: (json['taskAreas'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => TaskArea.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        planReviews: Map<String, String>.from(
          (json['planReviews'] as Map?)?.map((key, value) => MapEntry('$key', '$value')) ??
              const {'7': '', '15': '', '30': ''},
        ),
        preferences: json['preferences'] is Map
            ? ReminderPreferences.fromJson(Map<String, dynamic>.from(json['preferences'] as Map))
            : const ReminderPreferences(),
      );
}

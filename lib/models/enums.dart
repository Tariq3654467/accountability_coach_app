T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

enum GoalType {
  micro(0.8, 'Micro'),
  routine(1.0, 'Routine'),
  macro(1.3, 'Macro'),
  habit(1.0, 'Habit'),
  skill(1.15, 'Skill'),
  project(1.2, 'Project'),
  task(0.8, 'Task');

  final double weight;
  final String label;
  const GoalType(this.weight, this.label);
}

enum Tier {
  daily(1, 'Daily'),
  weekly(3, 'Weekly'),
  fortnightly(6, 'Fortnightly'),
  monthly(12, 'Monthly'),
  once(1, 'Once');

  final int weight;
  final String label;
  const Tier(this.weight, this.label);
}

enum Cadence {
  hourly('Hourly'),
  fourHour('4× daily'),
  daily('Daily'),
  threeWeekly('3× weekly'),
  weekly('5× weekly'),
  onceWeekly('Weekly'),
  flexible('Flexible');

  final String label;
  const Cadence(this.label);
}

enum ReminderStyle {
  gentle('Gentle'),
  persistent('Persistent'),
  escalating('Escalating'),
  encouraging('Encouraging'),
  none('None');

  final String label;
  const ReminderStyle(this.label);
}

enum Momentum {
  onTrack('On track'),
  slightlyBehind('Slightly behind'),
  behind('Behind schedule');

  final String label;
  const Momentum(this.label);
}

enum MeterColor { green, yellow, red }

enum SkipStatus { onTrack, behind, critical }

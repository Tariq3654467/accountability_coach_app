import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import '../providers/goal_provider.dart';

class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onRebalance,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onRebalance;

  String _key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  List<({Goal goal, Milestone milestone, bool done})> _items(GoalProvider provider, DateTime date) {
    final selected = _dateOnly(date);
    final result = <({Goal goal, Milestone milestone, bool done})>[];
    for (final goal in provider.goals) {
      for (final milestone in goal.allMilestones) {
        final due = _dateOnly(milestone.dueDate);
        final deadline = goal.deadline == null ? null : _dateOnly(goal.deadline!);
        if (milestone.tier == Tier.daily) {
          if (selected.isBefore(due) || (deadline != null && selected.isAfter(deadline))) continue;
          result.add((goal: goal, milestone: milestone, done: milestone.isDoneOn(selected)));
        } else {
          final doneDate = milestone.doneAt == null ? due : _dateOnly(milestone.doneAt!);
          if (selected != due && !(milestone.done && selected == doneDate)) continue;
          result.add((goal: goal, milestone: milestone, done: milestone.done && selected == doneDate));
        }
      }
    }
    result.sort((a, b) => a.milestone.dueDate.compareTo(b.milestone.dueDate));
    return result;
  }

  DateTime _weekStart(DateTime date) {
    final day = _dateOnly(date);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  String _weekday(DateTime date) => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoalProvider>();
    final items = _items(provider, selectedDate);
    final today = _dateOnly(DateTime.now());
    final selected = _dateOnly(selectedDate);
    final showPast = provider.preferences.showPastTasks;
    final weekStart = _weekStart(selected);
    final isOverdue = provider.goals.any((goal) => goal.allMilestones.any((item) =>
        item.tier != Tier.daily && !item.done && _dateOnly(item.dueDate).isBefore(today)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isOverdue)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.yellowBg,
              border: Border.all(color: const Color(0xFFF5E8C9)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync, size: 18, color: Color(0xFFBB841D)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('It’s okay to miss a day. Reschedule overdue tasks when you’re ready.',
                      style: TextStyle(fontSize: 10, color: AppColors.textDim)),
                ),
                TextButton(onPressed: onRebalance, child: const Text('Rebalance plan')),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(13),
            boxShadow: const [BoxShadow(color: Color(0x05241D4B), blurRadius: 12, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily activities', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        SizedBox(height: 3),
                        Text('Review what you planned and completed each day.',
                            style: TextStyle(fontSize: 10, color: AppColors.textDim)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => provider.updatePreferences(
                          provider.preferences.copyWith(showPastTasks: !showPast),
                        ),
                        child: Text(showPast ? 'Hide previous days' : 'Show previous days',
                            style: const TextStyle(fontSize: 10)),
                      ),
                      IconButton(
                        tooltip: 'Previous week',
                        onPressed: showPast ? () => onDateSelected(selected.subtract(const Duration(days: 7))) : null,
                        icon: const Icon(Icons.chevron_left, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        tooltip: 'Next week',
                        onPressed: () => onDateSelected(selected.add(const Duration(days: 7))),
                        icon: const Icon(Icons.chevron_right, size: 18),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(7, (index) {
                  final date = weekStart.add(Duration(days: index));
                  final key = _key(date);
                  final dayItems = _items(provider, date);
                  final count = dayItems.length;
                  final done = dayItems.where((item) => item.done).length;
                  final pastHidden = date.isBefore(today) && !showPast;
                  final isSelected = date == selected;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 6 ? 0 : 5),
                      child: InkWell(
                        onTap: pastHidden ? null : () => onDateSelected(date),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accentBg : AppColors.surface2.withOpacity(.55),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: isSelected ? AppColors.accent : Colors.transparent),
                          ),
                          child: Column(
                            children: [
                              Text(_weekday(date), style: const TextStyle(fontSize: 8, color: AppColors.textDim)),
                              const SizedBox(height: 4),
                              Text('${date.day}', style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.accent : AppColors.text,
                              )),
                              const SizedBox(height: 3),
                              Text(pastHidden ? 'Hidden' : count > 0 ? '$done/$count' : '—',
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 7, color: AppColors.textDim)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Text('${_weekday(selected)}, ${selected.month}/${selected.day} · ${items.where((item) => item.done).length} of ${items.length} activities complete',
                  style: const TextStyle(fontSize: 10, color: AppColors.textDim)),
              const SizedBox(height: 6),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No activities scheduled for this day. Add a task with this due date, or choose Daily to repeat it.',
                      style: TextStyle(fontSize: 10, color: AppColors.textDim)),
                )
              else
                for (final item in items)
                  _ActivityRow(
                    goal: item.goal,
                    milestone: item.milestone,
                    date: selected,
                    isDone: item.done,
                    future: selected.isAfter(today),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.goal,
    required this.milestone,
    required this.date,
    required this.isDone,
    required this.future,
  });

  final Goal goal;
  final Milestone milestone;
  final DateTime date;
  final bool isDone;
  final bool future;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Checkbox(
              value: isDone,
              onChanged: future
                  ? null
                  : (_) => context.read<GoalProvider>().toggleMilestone(
                        goal.id,
                        milestone.tier,
                        milestone.id,
                        date: date,
                      ),
              activeColor: AppColors.green,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(milestone.text, style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.textMute : AppColors.text,
                  )),
                  Text('${goal.name} · ${milestone.tier.label} · Weight ${milestone.weight}/10',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 8, color: AppColors.textDim)),
                ],
              ),
            ),
            Text(isDone ? 'Completed' : future ? 'Planned' : _isBeforeToday(date) ? 'Not completed' : 'To do',
                style: TextStyle(fontSize: 8, color: isDone ? AppColors.green : AppColors.textDim)),
          ],
        ),
      );

  bool _isBeforeToday(DateTime date) {
    final today = DateTime.now();
    return DateTime(date.year, date.month, date.day).isBefore(DateTime(today.year, today.month, today.day));
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/dashboard_state.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import '../providers/goal_provider.dart';

class PlanningPanel extends StatefulWidget {
  const PlanningPanel({super.key, required this.selectedDate});
  final DateTime selectedDate;

  @override
  State<PlanningPanel> createState() => _PlanningPanelState();
}

class _PlanningPanelState extends State<PlanningPanel> {
  int _horizon = 7;
  bool _busy = false;
  String? _status;
  String? _selectedGoalId;
  bool _reviewInitialized = false;
  late final TextEditingController _review = TextEditingController();

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  String _key(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime date) => '${date.month}/${date.day}';

  List<({Goal goal, Milestone milestone, DateTime date, bool done})> _plan(GoalProvider provider) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(Duration(days: _horizon - 1));
    final items = <({Goal goal, Milestone milestone, DateTime date, bool done})>[];
    for (final goal in provider.goals) {
      for (final milestone in goal.allMilestones) {
        if (milestone.tier == Tier.daily) {
          var date = milestone.dueDate.isAfter(start)
              ? DateTime(milestone.dueDate.year, milestone.dueDate.month, milestone.dueDate.day)
              : start;
          final deadline = goal.deadline == null
              ? end
              : DateTime(goal.deadline!.year, goal.deadline!.month, goal.deadline!.day);
          final finalDate = deadline.isBefore(end) ? deadline : end;
          while (!date.isAfter(finalDate)) {
            items.add((goal: goal, milestone: milestone, date: date, done: milestone.isDoneOn(date)));
            date = date.add(const Duration(days: 1));
          }
        } else {
          final date = DateTime(milestone.dueDate.year, milestone.dueDate.month, milestone.dueDate.day);
          if (!date.isBefore(start) && !date.isAfter(end)) {
            items.add((goal: goal, milestone: milestone, date: date, done: milestone.done));
          }
        }
      }
    }
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  Future<void> _recommend(GoalProvider provider, String? goalId) async {
    if (goalId == null || goalId.isEmpty) {
      setState(() => _status = 'Create a goal before asking for task recommendations.');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Creating practical task areas and small next steps…';
    });
    try {
      final message = await provider.recommendTaskAreas(goalId);
      if (mounted) setState(() => _status = message);
    } catch (error) {
      if (mounted) setState(() => _status = 'Couldn’t get recommendations: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoalProvider>();
    final plans = _plan(provider);
    final review = provider.dashboard.planReviews['$_horizon'] ?? '';
    if (!_reviewInitialized) {
      _review.text = review;
      _reviewInitialized = true;
    }
    if (provider.goals.isNotEmpty &&
        !provider.goals.any((goal) => goal.id == _selectedGoalId)) {
      _selectedGoalId = provider.goals.first.id;
    }
    final areas = provider.dashboard.taskAreas;
    return Column(
      children: [
        _PlanCard(
          horizon: _horizon,
          onHorizonChanged: (value) => setState(() {
            _horizon = value;
            _review.text = provider.dashboard.planReviews['$value'] ?? '';
            _reviewInitialized = true;
          }),
          items: plans,
          review: _review,
          onSaveReview: () async {
            await provider.savePlanReview('$_horizon', _review.text.trim());
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review saved.')));
            }
          },
        ),
        const SizedBox(height: 11),
        _TaskAreasCard(
          areas: areas,
          goals: provider.goals,
          selectedGoalId: _selectedGoalId ?? '',
          selectedDate: widget.selectedDate,
          busy: _busy,
          status: _status,
          onAdd: () => provider.addTaskArea(),
          onRecommend: (id) => _recommend(provider, id),
          onGoalSelected: (id) => setState(() => _selectedGoalId = id),
          onUpdateArea: provider.updateTaskArea,
          onDeleteArea: provider.deleteTaskArea,
          onToggleArea: (id, done) => provider.toggleTaskArea(id, widget.selectedDate, done),
          onAddSubtask: provider.addTaskAreaSubtask,
          onUpdateSubtask: provider.updateTaskAreaSubtask,
          onToggleSubtask: (areaId, subtaskId, done) =>
              provider.toggleTaskAreaSubtask(areaId, subtaskId, widget.selectedDate, done),
          onDeleteSubtask: provider.deleteTaskAreaSubtask,
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.horizon,
    required this.onHorizonChanged,
    required this.items,
    required this.review,
    required this.onSaveReview,
  });

  final int horizon;
  final ValueChanged<int> onHorizonChanged;
  final List<({Goal goal, Milestone milestone, DateTime date, bool done})> items;
  final TextEditingController review;
  final VoidCallback onSaveReview;

  @override
  Widget build(BuildContext context) => _Card(
        title: 'Plan & review',
        icon: Icons.auto_awesome,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 7),
            const Text('Choose a horizon for small, achievable steps and a matching retrospective.',
                style: TextStyle(fontSize: 9, color: AppColors.textDim, height: 1.45)),
            const SizedBox(height: 10),
            Row(
              children: [7, 15, 30].map((days) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: days == 30 ? 0 : 5),
                  child: OutlinedButton(
                    onPressed: () => onHorizonChanged(days),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: horizon == days ? AppColors.accentBg : Colors.white,
                      foregroundColor: horizon == days ? AppColors.accent : AppColors.textDim,
                      side: BorderSide(color: horizon == days ? AppColors.accent : AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text('$days days', style: const TextStyle(fontSize: 9)),
                  ),
                ),
              )).toList(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 9, bottom: 6),
              child: Text('Next $horizon days', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            if (items.isEmpty)
              Text('No tasks due in the next $horizon days. Add a small step to one of your goals.',
                  style: const TextStyle(fontSize: 9, color: AppColors.textDim))
            else
              ...items.take(12).map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.done ? Icons.check_circle : Icons.circle_outlined,
                        size: 13, color: item.done ? AppColors.green : AppColors.accent2),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.milestone.text, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                                  decoration: item.done ? TextDecoration.lineThrough : null)),
                          Text('${item.goal.name} · ${_date(item.date)} · Weight ${item.milestone.weight}/10',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 8, color: AppColors.textDim)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            if (items.length > 12)
              Text('+ ${items.length - 12} more scheduled activities',
                  style: const TextStyle(fontSize: 8, color: AppColors.textDim)),
            const Divider(height: 20),
            TextField(
              controller: review,
              maxLength: 1200,
              maxLines: 4,
              style: const TextStyle(fontSize: 10),
              decoration: InputDecoration(
                labelText: 'Retrospective — $horizon-day review',
                hintText: 'What went well? What was difficult? What is one kind adjustment for next time?',
                labelStyle: const TextStyle(fontSize: 9),
                hintStyle: const TextStyle(fontSize: 9),
                counterText: '',
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onSaveReview,
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('Save retrospective', style: TextStyle(fontSize: 9)),
              ),
            ),
          ],
        ),
      );

  static String _date(DateTime d) => '${d.month}/${d.day}';
}

class _TaskAreasCard extends StatelessWidget {
  const _TaskAreasCard({
    required this.areas,
    required this.goals,
    required this.selectedGoalId,
    required this.selectedDate,
    required this.busy,
    required this.status,
    required this.onAdd,
    required this.onRecommend,
    required this.onGoalSelected,
    required this.onUpdateArea,
    required this.onDeleteArea,
    required this.onToggleArea,
    required this.onAddSubtask,
    required this.onUpdateSubtask,
    required this.onToggleSubtask,
    required this.onDeleteSubtask,
  });

  final List<TaskArea> areas;
  final List<Goal> goals;
  final String selectedGoalId;
  final DateTime selectedDate;
  final bool busy;
  final String? status;
  final VoidCallback onAdd;
  final ValueChanged<String> onRecommend;
  final ValueChanged<String> onGoalSelected;
  final Future<void> Function(String, {String? title, String? goalId}) onUpdateArea;
  final Future<void> Function(String) onDeleteArea;
  final Future<void> Function(String, bool) onToggleArea;
  final Future<void> Function(String, String) onAddSubtask;
  final Future<void> Function(String, String, String) onUpdateSubtask;
  final Future<void> Function(String, String, bool) onToggleSubtask;
  final Future<void> Function(String, String) onDeleteSubtask;

  String get _date =>
      '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Recommended task areas',
      icon: Icons.checklist,
      action: IconButton(
        onPressed: onAdd,
        tooltip: 'Add a task area',
        icon: const Icon(Icons.add, size: 17),
        visualDensity: VisualDensity.compact,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 5),
          if (goals.isNotEmpty)
            DropdownButtonFormField<String>(
              value: selectedGoalId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Build recommendations for', labelStyle: TextStyle(fontSize: 9)),
              items: goals.map((goal) => DropdownMenuItem(value: goal.id, child: Text(goal.name,
                  overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9)))).toList(),
              onChanged: (id) {
                if (id != null) onGoalSelected(id);
              },
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: busy || goals.isEmpty ? null : () => onRecommend(selectedGoalId),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.accentBg,
              foregroundColor: AppColors.accent,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(busy ? 'Getting recommendations…' : 'Get AI recommendations',
                style: const TextStyle(fontSize: 9)),
          ),
          Text(status ?? 'AI recommendations are optional. Review and edit every task before using it.',
              style: const TextStyle(fontSize: 8, height: 1.4, color: AppColors.textDim)),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text('Daily checklist · ${selectedDate.month}/${selectedDate.day}. Completion is saved for each day.',
                style: const TextStyle(fontSize: 8, color: AppColors.textDim)),
          ),
          if (areas.isEmpty)
            const Text('No task areas yet. Add one or ask for AI recommendations.',
                style: TextStyle(fontSize: 9, color: AppColors.textDim))
          else
            ...areas.map((area) => _TaskAreaTile(
              area: area,
              date: _date,
              goals: goals,
              onUpdateArea: onUpdateArea,
              onDeleteArea: onDeleteArea,
              onToggleArea: onToggleArea,
              onAddSubtask: onAddSubtask,
              onUpdateSubtask: onUpdateSubtask,
              onToggleSubtask: onToggleSubtask,
              onDeleteSubtask: onDeleteSubtask,
            )),
        ],
      ),
    );
  }
}

class _TaskAreaTile extends StatelessWidget {
  const _TaskAreaTile({
    required this.area,
    required this.date,
    required this.goals,
    required this.onUpdateArea,
    required this.onDeleteArea,
    required this.onToggleArea,
    required this.onAddSubtask,
    required this.onUpdateSubtask,
    required this.onToggleSubtask,
    required this.onDeleteSubtask,
  });

  final TaskArea area;
  final String date;
  final List<Goal> goals;
  final Future<void> Function(String, {String? title, String? goalId}) onUpdateArea;
  final Future<void> Function(String) onDeleteArea;
  final Future<void> Function(String, bool) onToggleArea;
  final Future<void> Function(String, String) onAddSubtask;
  final Future<void> Function(String, String, String) onUpdateSubtask;
  final Future<void> Function(String, String, bool) onToggleSubtask;
  final Future<void> Function(String, String) onDeleteSubtask;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final selected = DateTime.tryParse(date) ?? today;
    final future = selected.isAfter(DateTime(today.year, today.month, today.day));
    String? goalName;
    for (final goal in goals) {
      if (goal.id == area.goalId) {
        goalName = goal.name;
        break;
      }
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(9)),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: area.isDone(date),
                onChanged: future ? null : (value) => onToggleArea(area.id, value ?? false),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: TextFormField(
                  initialValue: area.title,
                  maxLength: 100,
                  decoration: const InputDecoration(hintText: 'Task area', counterText: '', isDense: true),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  onChanged: (value) => onUpdateArea(area.id, title: value),
                ),
              ),
              IconButton(
                onPressed: () => onDeleteArea(area.id),
                icon: const Icon(Icons.close, size: 15),
                tooltip: 'Delete task area',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          if (goalName != null)
            Align(alignment: Alignment.centerLeft, child: Text(goalName,
                style: const TextStyle(fontSize: 8, color: AppColors.textDim))),
          for (final subtask in area.subtasks)
            Row(
              children: [
                Checkbox(
                  value: subtask.isDone(date),
                  onChanged: future ? null : (value) => onToggleSubtask(area.id, subtask.id, value ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: subtask.title,
                    maxLength: 120,
                    decoration: const InputDecoration(hintText: 'Small next step', counterText: '', isDense: true),
                    style: const TextStyle(fontSize: 9),
                    onChanged: (value) => onUpdateSubtask(area.id, subtask.id, value),
                  ),
                ),
                IconButton(
                  onPressed: () => onDeleteSubtask(area.id, subtask.id),
                  icon: const Icon(Icons.close, size: 14),
                  tooltip: 'Delete subtask',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          TextButton.icon(
            onPressed: () => onAddSubtask(area.id, ''),
            icon: const Icon(Icons.add, size: 13),
            label: const Text('Add subtask', style: TextStyle(fontSize: 8)),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.icon, required this.child, this.action});
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
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
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(color: AppColors.accentBg, borderRadius: BorderRadius.circular(7)),
                  child: Icon(icon, size: 12, color: AppColors.accent2),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                if (action != null) action!,
              ],
            ),
            child,
          ],
        ),
      );
}

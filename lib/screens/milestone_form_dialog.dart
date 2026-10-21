import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import '../providers/goal_provider.dart';
import '../utils/date_utils.dart';

Future<void> showMilestoneFormDialog(
  BuildContext context, {
  required Goal goal,
  Milestone? milestone,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _MilestoneFormDialog(goal: goal, milestone: milestone),
    );

class _MilestoneFormDialog extends StatefulWidget {
  const _MilestoneFormDialog({required this.goal, this.milestone});
  final Goal goal;
  final Milestone? milestone;

  @override
  State<_MilestoneFormDialog> createState() => _MilestoneFormDialogState();
}

class _MilestoneFormDialogState extends State<_MilestoneFormDialog> {
  late final TextEditingController _title =
      TextEditingController(text: widget.milestone?.text ?? '');
  late Tier _tier = widget.milestone?.tier ?? Tier.once;
  late DateTime _dueDate = widget.milestone?.dueDate ?? DateTime.now();
  late int _weight = widget.milestone?.weight ?? 1;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    final text = _title.text.trim();
    if (text.isEmpty) return;
    final provider = context.read<GoalProvider>();
    final old = widget.milestone;
    if (old == null) {
      await provider.addMilestone(
        widget.goal.id,
        _tier,
        text,
        dueDate: _dueDate,
        weight: _weight,
      );
    } else {
      await provider.editMilestone(
        widget.goal.id,
        old.tier,
        old.copyWith(text: text, tier: _tier, dueDate: _dueDate, weight: _weight),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(widget.milestone == null ? 'Add a task' : 'Edit task',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 390,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.goal.name, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                const SizedBox(height: 14),
                TextField(
                  controller: _title,
                  maxLength: 120,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Task title'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 11),
                DropdownButtonFormField<Tier>(
                  value: _tier,
                  decoration: const InputDecoration(labelText: 'Schedule'),
                  items: [
                    for (final tier in Tier.values)
                      DropdownMenuItem(value: tier, child: Text(tier.label)),
                  ],
                  onChanged: (value) => setState(() => _tier = value ?? _tier),
                ),
                const SizedBox(height: 11),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event, size: 16),
                  label: Text('Due ${DateUtilsX.inputDate(_dueDate)}'),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Expanded(child: Text('Importance weight', style: TextStyle(fontSize: 11))),
                    DropdownButton<int>(
                      value: _weight,
                      items: [for (var i = 1; i <= 10; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                      onChanged: (value) => setState(() => _weight = value ?? _weight),
                    ),
                  ],
                ),
                const Text('Higher-weight tasks contribute more to progress and the outlook.',
                    style: TextStyle(fontSize: 9, color: AppColors.textDim)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: _title.text.trim().isEmpty ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
            child: Text(widget.milestone == null ? 'Add task' : 'Save changes'),
          ),
        ],
      );
}

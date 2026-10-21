import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';
import '../config/sector_catalog.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import '../providers/goal_provider.dart';
import '../utils/date_utils.dart';
import '../utils/validators.dart';

/// Opens the add/edit sheet. Pass [goal] to edit an existing one.
Future<void> showGoalFormSheet(BuildContext context, {Goal? goal}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GoalFormSheet(goal: goal),
  );
}

class GoalFormSheet extends StatefulWidget {
  const GoalFormSheet({super.key, this.goal});
  final Goal? goal;

  @override
  State<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.goal?.name ?? '');
  late final _target = TextEditingController(text: widget.goal?.target ?? '');
  late final _notes = TextEditingController(text: widget.goal?.notes ?? '');
  late String _sectorId = widget.goal?.sectorId ?? 'language';
  late GoalType _type = widget.goal?.type ?? GoalType.habit;
  late Cadence _cadence = widget.goal?.cadence ?? Cadence.daily;
  late ReminderStyle _style = widget.goal?.reminderStyle ?? ReminderStyle.gentle;
  DateTime? _deadline;
  bool _useAi = false;
  bool _saving = false;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    _deadline = widget.goal?.deadline;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<GoalProvider>();
    String message;
    try {
      if (_isEdit) {
        final edited = widget.goal!.copyWith(
          name: _name.text,
          sectorId: _sectorId,
          type: _type,
          target: _target.text,
          deadline: _deadline,
          clearDeadline: _deadline == null,
          cadence: _cadence,
          reminderStyle: _style,
          notes: _notes.text,
        );
        message = await provider.updateGoal(edited);
      } else {
        message = await provider.addGoal(
          name: _name.text,
          sectorId: _sectorId,
          type: _type,
          target: _target.text,
          deadline: _deadline,
          cadence: _cadence,
          reminderStyle: _style,
          notes: _notes.text,
          useAi: _useAi,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(color: AppColors.borderHi, borderRadius: BorderRadius.circular(5)),
                  ),
                ),
                Text(_isEdit ? AppStrings.editGoal : AppStrings.newGoal,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.5)),
                const SizedBox(height: 4),
                Text(_isEdit ? AppStrings.updateGoal : AppStrings.defineGoal,
                    style: const TextStyle(fontSize: 13, color: AppColors.textDim)),
                const SizedBox(height: 20),

                _label('Goal Name *'),
                TextFormField(
                  controller: _name,
                  maxLength: 80,
                  decoration: const InputDecoration(hintText: 'e.g. Lose 5 kg in 3 months', counterText: ''),
                  validator: Validators.goalName,
                ),
                const SizedBox(height: 14),

                _label('Sector'),
                DropdownButtonFormField<String>(
                  value: _sectorId,
                  isExpanded: true,
                  items: [
                    for (final s in SectorCatalog.all)
                      DropdownMenuItem(value: s.id, child: Text(s.name)),
                  ],
                  onChanged: (v) => setState(() => _sectorId = v ?? _sectorId),
                ),
                const SizedBox(height: 14),

                _label('Goal Type'),
                DropdownButtonFormField<GoalType>(
                  value: _type,
                  items: [
                    for (final t in GoalType.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (value) => setState(() => _type = value ?? _type),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Target'),
                          TextFormField(
                            controller: _target,
                            maxLength: 40,
                            decoration: const InputDecoration(hintText: 'e.g. 5 kg', counterText: ''),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Deadline'),
                          InkWell(
                            onTap: _pickDeadline,
                            child: InputDecorator(
                              decoration: const InputDecoration(),
                              child: Text(_deadline == null ? 'None' : DateUtilsX.inputDate(_deadline!)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Cadence'),
                          DropdownButtonFormField<Cadence>(
                            value: _cadence,
                            isExpanded: true,
                            items: [
                              for (final c in Cadence.values)
                                DropdownMenuItem(value: c, child: Text(c.label)),
                            ],
                            onChanged: (v) => setState(() => _cadence = v ?? _cadence),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Reminder'),
                          DropdownButtonFormField<ReminderStyle>(
                            value: _style,
                            isExpanded: true,
                            items: [
                              for (final s in ReminderStyle.values)
                                DropdownMenuItem(value: s, child: Text(s.label)),
                            ],
                            onChanged: (v) => setState(() => _style = v ?? _style),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _label('Notes'),
                TextFormField(
                  controller: _notes,
                  maxLength: 300,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Why this matters...'),
                ),

                if (!_isEdit) ...[
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: _useAi,
                    onChanged: (v) => setState(() => _useAi = v),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Use AI to break this into milestones',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Falls back to built-in suggestions if AI is unavailable.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textDim)),
                    activeColor: AppColors.accent,
                  ),
                ],

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text(AppStrings.cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Goal', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w700)),
      );

}

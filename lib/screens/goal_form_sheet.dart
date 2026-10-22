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
  if (MediaQuery.sizeOf(context).width >= 700) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 610),
        child: GoalFormSheet(goal: goal, isDialog: true),
      ),
    );
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => GoalFormSheet(goal: goal),
  );
}

class GoalFormSheet extends StatefulWidget {
  const GoalFormSheet({super.key, this.goal, this.isDialog = false});
  final Goal? goal;
  final bool isDialog;

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
    if (widget.isDialog) {
      return AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 610,
              maxHeight: MediaQuery.sizeOf(context).height - 48,
            ),
            child: _formSurface(dialog: true),
          ),
        ),
      );
    }
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _formSurface(
          scrollController: scrollController,
          dialog: false,
        ),
      ),
    );
  }

  Widget _formSurface({ScrollController? scrollController, required bool dialog}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(dialog ? 22 : 28),
        boxShadow: dialog
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 32, offset: const Offset(0, 12))]
            : null,
      ),
      padding: EdgeInsets.fromLTRB(dialog ? 28 : 20, dialog ? 24 : 12, dialog ? 28 : 20, 24),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 500;
            return ListView(
              controller: scrollController,
              shrinkWrap: dialog,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_isEdit ? 'GOAL UPDATE' : 'A NEW BEGINNING',
                              style: const TextStyle(fontSize: 12, letterSpacing: 1.5,
                                  color: AppColors.textDim, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 5),
                          Text(_isEdit ? AppStrings.editGoal : 'Create a goal',
                              style: const TextStyle(fontSize: 25, height: 1.1,
                                  fontWeight: FontWeight.w800, color: AppColors.text)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface2,
                        foregroundColor: AppColors.textDim,
                        fixedSize: const Size(40, 40),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _isEdit ? AppStrings.updateGoal : 'Tasks are small, doable steps toward what matters, not tests of perfection.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.45),
                ),
                const SizedBox(height: 22),
                _label('What would you like to work toward?'),
                TextFormField(
                  controller: _name,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Build a consistent reading habit',
                    counterText: '',
                  ),
                  validator: Validators.goalName,
                ),
                const SizedBox(height: 16),
                _fieldPair(
                  _fieldColumn('Life area', DropdownButtonFormField<String>(
                    value: _sectorId,
                    isExpanded: true,
                    items: [for (final sector in SectorCatalog.all)
                      DropdownMenuItem(value: sector.id, child: Text(sector.name))],
                    onChanged: (value) => setState(() => _sectorId = value ?? _sectorId),
                  )),
                  _fieldColumn('Goal type', DropdownButtonFormField<GoalType>(
                    value: _type,
                    isExpanded: true,
                    items: [for (final type in GoalType.values)
                      DropdownMenuItem(value: type, child: Text(type.label))],
                    onChanged: (value) => setState(() => _type = value ?? _type),
                  )),
                  twoColumns,
                ),
                const SizedBox(height: 16),
                _fieldPair(
                  _fieldColumn('Target', TextFormField(
                    controller: _target,
                    maxLength: 40,
                    decoration: const InputDecoration(hintText: 'e.g. 30 days, B2 level', counterText: ''),
                  )),
                  _fieldColumn('Target date', InkWell(
                    onTap: _pickDeadline,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
                      child: Text(_deadline == null ? 'Choose a date' : DateUtilsX.inputDate(_deadline!)),
                    ),
                  )),
                  twoColumns,
                ),
                const SizedBox(height: 16),
                _fieldPair(
                  _fieldColumn('Cadence', DropdownButtonFormField<Cadence>(
                    value: _cadence,
                    isExpanded: true,
                    items: [for (final cadence in Cadence.values)
                      DropdownMenuItem(value: cadence, child: Text(cadence.label))],
                    onChanged: (value) => setState(() => _cadence = value ?? _cadence),
                  )),
                  _fieldColumn('Reminder style', DropdownButtonFormField<ReminderStyle>(
                    value: _style,
                    isExpanded: true,
                    items: [for (final style in ReminderStyle.values)
                      DropdownMenuItem(value: style, child: Text(style.label))],
                    onChanged: (value) => setState(() => _style = value ?? _style),
                  )),
                  twoColumns,
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.accent),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Start with rule-based ideas, or ask AI for personalized tasks. You can edit them any time.',
                              style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textDim)),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => setState(() => _useAi = !_useAi),
                          icon: Icon(_useAi ? Icons.check_rounded : Icons.auto_awesome, size: 16),
                          label: Text(_useAi ? 'AI on' : 'Ask AI'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            textStyle: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  initiallyExpanded: _notes.text.isNotEmpty,
                  title: const Text('Why this matters (optional)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  children: [
                    TextFormField(
                      controller: _notes,
                      maxLength: 300,
                      maxLines: 3,
                      decoration: const InputDecoration(hintText: 'Add a note about this goal'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: dialog ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (dialog) ...[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.accentBg,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(AppStrings.cancelLabel),
                      ),
                      const SizedBox(width: 10),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(AppStrings.cancelLabel),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (dialog)
                      _saveButton()
                    else
                      Expanded(child: _saveButton()),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _fieldPair(Widget first, Widget second, bool twoColumns) {
    if (!twoColumns) {
      return Column(children: [first, const SizedBox(height: 16), second]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: first), const SizedBox(width: 14), Expanded(child: second)],
    );
  }

  Widget _fieldColumn(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_label(label), field],
      );

  Widget _saveButton() => ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: widget.isDialog ? 20 : 8, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _saving
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(_isEdit ? 'Save changes' : 'Create my goal',
                style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: AppColors.textDim, fontWeight: FontWeight.w700)),
      );

}

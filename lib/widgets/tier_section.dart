import 'package:flutter/material.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';
import '../models/enums.dart';
import '../models/milestone.dart';
import 'milestone_tile.dart';

class TierSection extends StatefulWidget {
  const TierSection({
    super.key,
    required this.tier,
    required this.milestones,
    required this.initiallyOpen,
    required this.onOpenChanged,
    required this.onToggleMilestone,
    required this.onDeleteMilestone,
    required this.onAddMilestone,
    required this.onEditMilestone,
  });

  final Tier tier;
  final List<Milestone> milestones;
  final bool initiallyOpen;
  final ValueChanged<bool> onOpenChanged;
  final ValueChanged<String> onToggleMilestone;
  final ValueChanged<String> onDeleteMilestone;
  final ValueChanged<String> onAddMilestone;
  final ValueChanged<Milestone> onEditMilestone;

  @override
  State<TierSection> createState() => _TierSectionState();
}

class _TierSectionState extends State<TierSection> {
  late bool _open = widget.initiallyOpen;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAddMilestone(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Only daily shows when empty; other tiers hide until they have tasks.
    if (widget.milestones.isEmpty && widget.tier != Tier.daily) {
      return const SizedBox.shrink();
    }
    final done = widget.milestones.where((m) => m.done).length;
    final total = widget.milestones.length;
    final pct = total == 0 ? 0.0 : done / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() => _open = !_open);
              widget.onOpenChanged(_open);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right, size: 16, color: AppColors.textDim),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    child: Text(widget.tier.label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  Text('$done/$total',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDim)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 5,
                        backgroundColor: Colors.black.withOpacity(0.06),
                        valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  for (final m in widget.milestones)
                    MilestoneTile(
                      milestone: m,
                      onToggle: () => widget.onToggleMilestone(m.id),
                      onDelete: () => widget.onDeleteMilestone(m.id),
                      onEdit: () => widget.onEditMilestone(m),
                    ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderHi, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Text('+', style: TextStyle(color: AppColors.textDim, fontSize: 15)),
                        const SizedBox(width: 9),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLength: 120,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              counterText: '',
                              border: InputBorder.none,
                              hintText: AppStrings.fmt(
                                  AppStrings.addTask, {'tier': widget.tier.label.toLowerCase()}),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

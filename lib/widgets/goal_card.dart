import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/sector_catalog.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import '../models/milestone.dart';
import '../providers/goal_provider.dart';
import '../utils/date_utils.dart';
import '../screens/milestone_form_dialog.dart';
import 'dual_meter.dart';
import 'skip_banner.dart';
import 'tier_section.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _typeLabel => goal.type.label;

  String get _cadenceLabel => goal.cadence.label;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GoalProvider>();
    final sector = SectorCatalog.byId(goal.sectorId);
    final challenge = provider.challengeFor(goal);
    final progress = provider.progressFor(goal);
    final impact = provider.skipImpactFor(goal);
    final prediction = provider.predictionFor(goal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [BoxShadow(color: Color(0x05241D4B), blurRadius: 12, offset: Offset(0, 3))],
        border: Border(
          left: BorderSide(color: sector.color, width: 4),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -.4)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: sector.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(sector.icon, size: 13, color: sector.color),
                          const SizedBox(width: 6),
                          Text(sector.name,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sector.color)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textDim),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              _chip(Icons.schedule, _typeLabel),
              _chip(Icons.gps_fixed, _cadenceLabel),
              if (goal.target.isNotEmpty) _chip(Icons.star_outline, goal.target),
              if (goal.deadline != null) _chip(Icons.event, DateUtilsX.shortDate(goal.deadline!)),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                DualMeter(score: challenge.score, color: challenge.color, title: 'Challenge', verdict: challenge.label),
                DualMeter(score: progress.score, color: progress.color, title: 'Progress', verdict: progress.label),
              ],
            ),
          ),
          const SizedBox(height: 11),
          if (impact != null)
            SkipBanner(
              impact: impact,
              busy: provider.isBusy,
              onRebalance: () async {
                final msg = await provider.applyAiBreakdown(goal.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                }
              },
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: AppColors.accentBg, borderRadius: BorderRadius.circular(9)),
            child: Row(
              children: [
                const Icon(Icons.insights, size: 15, color: AppColors.accent2),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${prediction.verdict} (${prediction.percent}%) · ${prediction.detail}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.accent2)),
                ),
              ],
            ),
          ),
          for (final tier in Tier.values)
            TierSection(
              tier: tier,
              milestones: goal.milestonesOf(tier),
              initiallyOpen: provider.isTierOpen(tier),
              onOpenChanged: (open) => provider.setTierOpen(tier, open),
              onToggleMilestone: (id) => provider.toggleMilestone(goal.id, tier, id),
              onDeleteMilestone: (id) => provider.deleteMilestone(goal.id, tier, id),
              onAddMilestone: (text) => provider.addMilestone(goal.id, tier, text),
              onEditMilestone: (milestone) =>
                  showMilestoneFormDialog(context, goal: goal, milestone: milestone),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => showMilestoneFormDialog(context, goal: goal),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add task', style: TextStyle(fontSize: 10)),
              style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textDim),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

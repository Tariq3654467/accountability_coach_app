import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/metrics_service.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.stats});
  final OverallStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: constraints.maxWidth < 430 ? 2 : 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: constraints.maxWidth < 430 ? 1.85 : 1.6,
        children: [
          _Stat(icon: Icons.adjust, iconColor: AppColors.accent, iconBg: AppColors.accentBg,
              value: '${stats.goals}', label: 'Active goals', note: "You're showing up"),
          _Stat(icon: Icons.trending_up, iconColor: AppColors.accent2, iconBg: const Color(0xFFF1EDFF),
              value: '${stats.tasks}', label: 'Tasks', note: 'Small steps, big change'),
          _Stat(icon: Icons.check, iconColor: AppColors.green, iconBg: AppColors.greenBg,
              value: '${stats.done}', label: 'Completed', note: 'Celebrate every win'),
          _Stat(icon: Icons.pie_chart_outline, iconColor: AppColors.accent2, iconBg: AppColors.accentBg,
              value: '${stats.percent}%', label: 'Overall progress', note: 'Across all your goals'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.note,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [BoxShadow(color: Color(0x05241D4B), blurRadius: 12, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w600)),
              ),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 15, color: iconColor),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 4),
          Text(note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: AppColors.textMute)),
        ],
      ),
    );
  }
}

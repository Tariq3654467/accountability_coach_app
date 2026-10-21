import 'package:flutter/material.dart';
import '../config/app_strings.dart';
import '../config/app_theme.dart';
import '../models/enums.dart';
import '../models/goal_metrics.dart';

class SkipBanner extends StatelessWidget {
  const SkipBanner({super.key, required this.impact, this.onRebalance, this.busy = false});

  final SkipImpactResult impact;
  final VoidCallback? onRebalance;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late String emoji;
    late String text;
    var showButton = false;

    switch (impact.status) {
      case SkipStatus.onTrack:
        if (impact.ahead <= 0) return const SizedBox.shrink();
        bg = AppColors.greenBg;
        fg = const Color(0xFF0D7A55);
        emoji = '🟢';
        text = AppStrings.fmt(AppStrings.skipOnTrack, {'d': impact.ahead});
        break;
      case SkipStatus.behind:
        bg = AppColors.yellowBg;
        fg = const Color(0xFF92580A);
        emoji = '🟡';
        text = AppStrings.fmt(AppStrings.skipBehind, {'s': impact.skipped, 'd': impact.projectedDelay});
        showButton = true;
        break;
      case SkipStatus.critical:
        bg = AppColors.redBg;
        fg = const Color(0xFFB91C1C);
        emoji = '🔴';
        text = AppStrings.fmt(AppStrings.skipCritical, {'s': impact.skipped, 'd': impact.projectedDelay});
        showButton = true;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          ),
          if (showButton && onRebalance != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: busy ? null : onRebalance,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: busy
                    ? SizedBox(
                        width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: fg))
                    : Text(AppStrings.rebalance,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

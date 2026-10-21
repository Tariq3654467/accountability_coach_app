import 'dart:math' as math;
import '../config/app_config.dart';
import '../config/app_strings.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import '../models/goal_metrics.dart';

class OverallStats {
  final int goals;
  final int tasks;
  final int done;
  final int percent;
  final int needAttention;
  final int withinReach;
  const OverallStats({
    required this.goals,
    required this.tasks,
    required this.done,
    required this.percent,
    required this.needAttention,
    required this.withinReach,
  });
}

class MetricsService {
  MetricsService._();

  static const _dayMs = 86400000;

  static int _ceilDays(Duration d) => (d.inMilliseconds / _dayMs).ceil();

  static DateTime _end(Goal g) {
    final d = g.deadline;
    if (d != null) return DateTime(d.year, d.month, d.day, 23, 59, 59);
    return g.createdAt.add(const Duration(days: AppConfig.defaultHorizonDays));
  }

  static ChallengeResult challenge(Goal g) {
    var effort = 0;
    for (final tier in Tier.values) {
      effort += g.milestonesOf(tier).fold(0, (sum, milestone) => sum + milestone.weight * tier.weight);
    }

    final daysTotal = g.deadline != null
        ? math.max(1, _ceilDays(_end(g).difference(g.createdAt)))
        : AppConfig.defaultHorizonDays;

    final difficulty = (effort / daysTotal) * g.type.weight * 8;
    final score = (100 - difficulty).round().clamp(0, 100);

    if (score >= 70) return ChallengeResult(score, MeterColor.green, AppStrings.easy);
    if (score >= 40) return ChallengeResult(score, MeterColor.yellow, AppStrings.moderate);
    return ChallengeResult(score, MeterColor.red, AppStrings.veryHard);
  }

  static ProgressResult progress(Goal g, {DateTime? now}) {
    final n = now ?? DateTime.now();
    var weightDone = 0, weightTotal = 0;
    for (final tier in Tier.values) {
      for (final m in g.milestonesOf(tier)) {
        if (tier == Tier.daily) {
          final start = DateTime(m.dueDate.year, m.dueDate.month, m.dueDate.day);
          final endDate = g.deadline != null && g.deadline!.isBefore(n) ? g.deadline! : n;
          final finish = DateTime(endDate.year, endDate.month, endDate.day);
          final days = finish.isBefore(start) ? 0 : finish.difference(start).inDays + 1;
          weightTotal += days * m.weight;
          weightDone += m.completedDates.where((date) {
            final parsed = DateTime.tryParse(date);
            return parsed != null && !parsed.isBefore(start) && !parsed.isAfter(finish);
          }).length * m.weight;
        } else {
          weightTotal += m.weight;
          if (m.done) weightDone += m.weight;
        }
      }
    }
    final raw = weightTotal > 0 ? weightDone / weightTotal : 0.0;

    final elapsed = math.max(0, n.difference(g.createdAt).inMilliseconds);
    final total = math.max(1, _end(g).difference(g.createdAt).inMilliseconds);
    final expected = math.min(1.0, elapsed / total);

    final Momentum momentum;
    final MeterColor color;
    if (raw >= expected) {
      momentum = Momentum.onTrack;
      color = MeterColor.green;
    } else if (raw >= expected * 0.75) {
      momentum = Momentum.slightlyBehind;
      color = MeterColor.yellow;
    } else {
      momentum = Momentum.behind;
      color = MeterColor.red;
    }
    return ProgressResult((raw * 100).round(), (expected * 100).round(), color, momentum);
  }

  /// Returns null when there is nothing to judge yet (day 0 or no daily tasks).
  static SkipImpactResult? skipImpact(Goal g, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final daysElapsed = (n.difference(g.createdAt).inMilliseconds / _dayMs).floor();
    if (daysElapsed <= 0) return null;

    final daily = g.milestonesOf(Tier.daily);
    final scheduled = daily.fold<int>(0, (sum, m) {
      final start = DateTime(m.dueDate.year, m.dueDate.month, m.dueDate.day);
      final endDate = g.deadline != null && g.deadline!.isBefore(n) ? g.deadline! : n;
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      return sum + (end.isBefore(start) ? 0 : end.difference(start).inDays + 1);
    });
    if (scheduled == 0) return null;
    final actualDone = daily.fold<int>(0, (sum, m) => sum + m.completedDates.where((date) {
      final parsed = DateTime.tryParse(date);
      return parsed != null && !parsed.isAfter(n);
    }).length);
    final skipped = math.max(0, scheduled - actualDone);

    final daysRemaining = math.max(0, _ceilDays(_end(g).difference(n)));

    if (skipped <= 0) {
      return SkipImpactResult(
        status: SkipStatus.onTrack,
        daysRemaining: daysRemaining,
        ahead: math.max(0, actualDone - scheduled),
      );
    }
    final critical = skipped > daysRemaining;
    return SkipImpactResult(
      status: critical ? SkipStatus.critical : SkipStatus.behind,
      skipped: skipped,
      daysRemaining: daysRemaining,
      projectedDelay: skipped,
    );
  }

  static OverallStats overall(List<Goal> goals) {
    var tasks = 0, done = 0, attention = 0, reach = 0;
    var totalWeight = 0, completedWeight = 0;
    final today = DateTime.now();
    for (final g in goals) {
      for (final milestone in g.allMilestones) {
        if (milestone.tier == Tier.daily) {
          final start = DateTime(milestone.dueDate.year, milestone.dueDate.month, milestone.dueDate.day);
          final rawEnd = g.deadline != null && g.deadline!.isBefore(today) ? g.deadline! : today;
          final end = DateTime(rawEnd.year, rawEnd.month, rawEnd.day);
          final days = end.isBefore(start) ? 0 : end.difference(start).inDays + 1;
          final completed = milestone.completedDates.where((date) {
            final parsed = DateTime.tryParse(date);
            return parsed != null && !parsed.isBefore(start) && !parsed.isAfter(end);
          }).length;
          tasks += days;
          done += completed;
          totalWeight += days * milestone.weight;
          completedWeight += completed * milestone.weight;
        } else {
          tasks++;
          if (milestone.done) done++;
          totalWeight += milestone.weight;
          if (milestone.done) completedWeight += milestone.weight;
        }
      }
      final imp = skipImpact(g);
      if (imp != null && imp.status != SkipStatus.onTrack) attention++;
      final p = progress(g).score;
      if (p >= 50 && p < 100) reach++;
    }
    return OverallStats(
      goals: goals.length,
      tasks: tasks,
      done: done,
      percent: totalWeight == 0 ? 0 : (completedWeight / totalWeight * 100).round(),
      needAttention: attention,
      withinReach: reach,
    );
  }
}

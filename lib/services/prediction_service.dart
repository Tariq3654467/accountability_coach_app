import 'dart:math' as math;
import '../config/app_config.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import 'metrics_service.dart';

class PredictionResult {
  final double probability; // 0..1
  final String verdict;
  final String detail;
  final DateTime? projectedFinish;
  const PredictionResult(this.probability, this.verdict, this.detail, this.projectedFinish);
  int get percent => (probability * 100).round();
}

class PredictionService {
  PredictionResult predict(Goal g, {DateTime? now}) {
    final n = now ?? DateTime.now();

    var weightDone = 0, weightTotal = 0;
    for (final t in Tier.values) {
      for (final m in g.milestonesOf(t)) {
        weightTotal += t.weight;
        if (m.done) weightDone += t.weight;
      }
    }

    if (weightTotal == 0) {
      return const PredictionResult(0.5, 'Not enough data', 'Add tasks to get a prediction.', null);
    }
    if (weightDone == weightTotal) {
      return PredictionResult(1.0, 'Completed', 'Every task is done. Great work.', n);
    }

    final end = g.deadline != null
        ? DateTime(g.deadline!.year, g.deadline!.month, g.deadline!.day, 23, 59, 59)
        : g.createdAt.add(const Duration(days: AppConfig.defaultHorizonDays));
    final daysRemaining = math.max(0.0, end.difference(n).inHours / 24);
    final elapsedDays = n.difference(g.createdAt).inHours / 24;

    // Day-one goals: lean on how hard the plan looks instead of pace.
    if (elapsedDays < 1) {
      final p = (MetricsService.challenge(g).score / 100).clamp(0.3, 0.9).toDouble();
      return PredictionResult(p, _verdict(p), 'Based on plan difficulty. Check in again tomorrow.', null);
    }

    final rate = weightDone / elapsedDays; // weight units per day
    final remaining = (weightTotal - weightDone).toDouble();
    if (rate <= 0) {
      return PredictionResult(0.02, 'Unlikely', 'No tasks completed yet. Finish one to start your pace.', null);
    }

    final daysNeeded = remaining / rate;
    final ratio = daysRemaining / daysNeeded;
    final p = (1 / (1 + math.exp(-4 * (ratio - 1)))).clamp(0.02, 0.99).toDouble();
    final finish = n.add(Duration(hours: (daysNeeded * 24).round()));

    return PredictionResult(
      p,
      _verdict(p),
      'At your current pace you would finish in about ${daysNeeded.ceil()} days '
      '(${daysRemaining.ceil()} remaining).',
      finish,
    );
  }

  String _verdict(double p) {
    if (p >= 0.8) return 'Very likely';
    if (p >= 0.55) return 'Likely';
    if (p >= 0.3) return 'At risk';
    return 'Unlikely';
  }
}

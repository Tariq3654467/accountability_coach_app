import 'enums.dart';

class ChallengeResult {
  final int score;
  final MeterColor color;
  final String label;
  const ChallengeResult(this.score, this.color, this.label);
}

class ProgressResult {
  final int score;
  final int expected;
  final MeterColor color;
  final Momentum momentum;
  const ProgressResult(this.score, this.expected, this.color, this.momentum);
  String get label => momentum.label;
}

class SkipImpactResult {
  final SkipStatus status;
  final int skipped;
  final int daysRemaining;
  final int ahead;
  final int projectedDelay;
  const SkipImpactResult({
    required this.status,
    this.skipped = 0,
    this.daysRemaining = 0,
    this.ahead = 0,
    this.projectedDelay = 0,
  });
}

import 'package:flutter/material.dart';
import '../models/enums.dart';

class DualMeter extends StatelessWidget {
  const DualMeter({
    super.key,
    required this.score,
    required this.color,
    required this.title,
    required this.verdict,
  });

  final int score;
  final MeterColor color;
  final String title;
  final String verdict;

  Color get _hex {
    switch (color) {
      case MeterColor.green:
        return const Color(0xFF10B981);
      case MeterColor.yellow:
        return const Color(0xFFF59E0B);
      case MeterColor.red:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 78,
          height: 78,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 7,
                  color: Colors.black.withOpacity(0.06),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score / 100),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: value.clamp(0, 1),
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    color: _hex,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              Text('$score%',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _hex)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
                color: Color(0xFF8A8A96))),
        const SizedBox(height: 3),
        Text(verdict,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _hex)),
      ],
    );
  }
}

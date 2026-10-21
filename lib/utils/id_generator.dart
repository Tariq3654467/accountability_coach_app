import 'dart:math' as math;

class IdGenerator {
  IdGenerator._();

  static final _rng = math.Random();
  static int _counter = 0;

  static String next() {
    _counter = (_counter + 1) & 0xFFFF;
    final time = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final count = _counter.toRadixString(36).padLeft(3, '0');
    final rand = _rng.nextInt(1 << 20).toRadixString(36).padLeft(4, '0');
    return '$time$count$rand';
  }
}

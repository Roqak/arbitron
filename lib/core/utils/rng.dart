import 'dart:math';

/// Seeded random for deterministic demo data generation.
class Rng {
  Rng._();
  static final _r = Random(0xC0FFEE);

  static double nextDouble({double min = 0, double max = 1}) =>
      min + _r.nextDouble() * (max - min);

  static int nextInt({required int min, required int max}) =>
      min + _r.nextInt(max - min);

  static bool nextBool({double trueChance = 0.5}) => _r.nextDouble() < trueChance;

  static T pick<T>(List<T> list) => list[_r.nextInt(list.length)];
}
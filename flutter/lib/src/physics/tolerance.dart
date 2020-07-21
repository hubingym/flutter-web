class Tolerance {
  const Tolerance(
      {this.distance = _epsilonDefault,
      this.time = _epsilonDefault,
      this.velocity = _epsilonDefault});

  static const double _epsilonDefault = 1e-3;

  static const Tolerance defaultTolerance = const Tolerance();

  final double distance;

  final double time;

  final double velocity;

  @override
  String toString() =>
      'Tolerance(distance: ±$distance, time: ±$time, velocity: ±$velocity)';
}

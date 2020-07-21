import 'simulation.dart';

class GravitySimulation extends Simulation {
  GravitySimulation(
      double acceleration, double distance, double endDistance, double velocity)
      : assert(acceleration != null),
        assert(distance != null),
        assert(velocity != null),
        assert(endDistance != null),
        assert(endDistance >= 0),
        _a = acceleration,
        _x = distance,
        _v = velocity,
        _end = endDistance;

  final double _x;
  final double _v;
  final double _a;
  final double _end;

  @override
  double x(double time) => _x + _v * time + 0.5 * _a * time * time;

  @override
  double dx(double time) => _v + time * _a;

  @override
  bool isDone(double time) => x(time).abs() >= _end;
}

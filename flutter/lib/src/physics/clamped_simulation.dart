import 'simulation.dart';

class ClampedSimulation extends Simulation {
  ClampedSimulation(
    this.simulation, {
    this.xMin = double.negativeInfinity,
    this.xMax = double.infinity,
    this.dxMin = double.negativeInfinity,
    this.dxMax = double.infinity,
  })  : assert(simulation != null),
        assert(xMax >= xMin),
        assert(dxMax >= dxMin);

  final Simulation simulation;

  final double xMin;

  final double xMax;

  final double dxMin;

  final double dxMax;

  @override
  double x(double time) => simulation.x(time).clamp(xMin, xMax);

  @override
  double dx(double time) => simulation.dx(time).clamp(dxMin, dxMax);

  @override
  bool isDone(double time) => simulation.isDone(time);
}

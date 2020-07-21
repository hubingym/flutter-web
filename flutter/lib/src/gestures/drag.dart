import 'drag_details.dart';

abstract class Drag {
  void update(DragUpdateDetails details) {}

  void end(DragEndDetails details) {}

  void cancel() {}
}

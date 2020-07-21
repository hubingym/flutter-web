import 'arena.dart';
import 'events.dart';
import 'recognizer.dart';

class EagerGestureRecognizer extends OneSequenceGestureRecognizer {
  EagerGestureRecognizer({PointerDeviceKind kind}) : super(kind: kind);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    stopTrackingPointer(event.pointer);
  }

  @override
  String get debugDescription => 'eager';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {}
}

import 'package:flutter_web/foundation.dart';

bool debugPrintHitTestResults = false;

bool debugPrintMouseHoverEvents = false;

bool debugPrintGestureArenaDiagnostics = false;

bool debugPrintRecognizerCallbacksTrace = false;

bool debugAssertAllGesturesVarsUnset(String reason) {
  assert(() {
    if (debugPrintHitTestResults ||
        debugPrintGestureArenaDiagnostics ||
        debugPrintRecognizerCallbacksTrace) throw FlutterError(reason);
    return true;
  }());
  return true;
}

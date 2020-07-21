import 'package:flutter_web/foundation.dart';

bool debugPrintBeginFrameBanner = false;

bool debugPrintEndFrameBanner = false;

bool debugPrintScheduleFrameStacks = false;

bool debugAssertAllSchedulerVarsUnset(String reason) {
  assert(() {
    if (debugPrintBeginFrameBanner || debugPrintEndFrameBanner) {
      throw new FlutterError(reason);
    }
    return true;
  }());
  return true;
}

import 'dart:async';

import 'assertions.dart';
import 'platform.dart';
import 'print.dart';

bool debugAssertAllFoundationVarsUnset(String reason,
    {DebugPrintCallback debugPrintOverride = debugPrintThrottled}) {
  assert(() {
    if (debugPrint != debugPrintOverride ||
        debugDefaultTargetPlatformOverride != null ||
        debugDoublePrecision != null) throw FlutterError(reason);
    return true;
  }());
  return true;
}

bool debugInstrumentationEnabled = false;

Future<T> debugInstrumentAction<T>(String description, Future<T> action()) {
  bool instrument = false;
  assert(() {
    instrument = debugInstrumentationEnabled;
    return true;
  }());
  if (instrument) {
    final Stopwatch stopwatch = Stopwatch()..start();
    return action().whenComplete(() {
      stopwatch.stop();
      debugPrint('Action "$description" took ${stopwatch.elapsed}');
    });
  } else {
    return action();
  }
}

const Map<String, String> timelineWhitelistArguments = <String, String>{
  'mode': 'basic',
};

int debugDoublePrecision;

String debugFormatDouble(double value) {
  if (value == null) {
    return 'null';
  }
  if (debugDoublePrecision != null) {
    return value.toStringAsPrecision(debugDoublePrecision);
  }
  return value.toStringAsFixed(1);
}

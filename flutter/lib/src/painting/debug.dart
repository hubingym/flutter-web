import 'package:flutter_web/foundation.dart';

bool debugDisableShadows = false;

bool debugAssertAllPaintingVarsUnset(String reason,
    {bool debugDisableShadowsOverride = false}) {
  assert(() {
    if (debugDisableShadows != debugDisableShadowsOverride) {
      throw new FlutterError(reason);
    }
    return true;
  }());
  return true;
}

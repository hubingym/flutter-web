import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart';

import 'object.dart';

export 'package:flutter_web/foundation.dart' show debugPrint;

const HSVColor _kDebugDefaultRepaintColor =
    HSVColor.fromAHSV(0.4, 60.0, 1.0, 1.0);

bool debugPaintSizeEnabled = false;

bool debugPaintBaselinesEnabled = false;

bool debugPaintLayerBordersEnabled = false;

bool debugPaintPointersEnabled = false;

bool debugRepaintRainbowEnabled = false;

bool debugRepaintTextRainbowEnabled = false;

bool debugCheckElevationsEnabled = false;

HSVColor debugCurrentRepaintColor = _kDebugDefaultRepaintColor;

bool debugPrintMarkNeedsLayoutStacks = false;

bool debugPrintMarkNeedsPaintStacks = false;

bool debugPrintLayouts = false;

bool debugCheckIntrinsicSizes = false;

bool debugProfilePaintsEnabled = false;

typedef ProfilePaintCallback = void Function(RenderObject renderObject);

ProfilePaintCallback debugOnProfilePaint;

bool debugDisableClipLayers = false;

bool debugDisablePhysicalShapeLayers = false;

bool debugDisableOpacityLayers = false;

void _debugDrawDoubleRect(
    Canvas canvas, Rect outerRect, Rect innerRect, Color color) {
  final Path path = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(outerRect)
    ..addRect(innerRect);
  final Paint paint = Paint()..color = color;
  canvas.drawPath(path, paint);
}

void debugPaintPadding(Canvas canvas, Rect outerRect, Rect innerRect,
    {double outlineWidth = 2.0}) {
  assert(() {
    if (innerRect != null && !innerRect.isEmpty) {
      _debugDrawDoubleRect(
          canvas, outerRect, innerRect, const Color(0x900090FF));
      _debugDrawDoubleRect(
          canvas,
          innerRect.inflate(outlineWidth).intersect(outerRect),
          innerRect,
          const Color(0xFF0090FF));
    } else {
      final Paint paint = Paint()..color = const Color(0x90909090);
      canvas.drawRect(outerRect, paint);
    }
    return true;
  }());
}

bool debugAssertAllRenderVarsUnset(String reason,
    {bool debugCheckIntrinsicSizesOverride = false}) {
  assert(() {
    if (debugPaintSizeEnabled ||
        debugPaintBaselinesEnabled ||
        debugPaintLayerBordersEnabled ||
        debugPaintPointersEnabled ||
        debugRepaintRainbowEnabled ||
        debugRepaintTextRainbowEnabled ||
        debugCurrentRepaintColor != _kDebugDefaultRepaintColor ||
        debugPrintMarkNeedsLayoutStacks ||
        debugPrintMarkNeedsPaintStacks ||
        debugPrintLayouts ||
        debugCheckIntrinsicSizes != debugCheckIntrinsicSizesOverride ||
        debugProfilePaintsEnabled ||
        debugOnProfilePaint != null) {
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}

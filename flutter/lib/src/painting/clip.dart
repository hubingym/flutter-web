import 'package:flutter_web/ui.dart';

abstract class ClipContext {
  Canvas get canvas;

  void _clipAndPaint(void canvasClipCall(bool doAntiAlias), Clip clipBehavior,
      Rect bounds, void painter()) {
    assert(canvasClipCall != null);
    canvas.save();
    switch (clipBehavior) {
      case Clip.none:
        break;
      case Clip.hardEdge:
        canvasClipCall(false);
        break;
      case Clip.antiAlias:
        canvasClipCall(true);
        break;
      case Clip.antiAliasWithSaveLayer:
        canvasClipCall(true);
        canvas.saveLayer(bounds, Paint());
        break;
    }
    painter();
    if (clipBehavior == Clip.antiAliasWithSaveLayer) {
      canvas.restore();
    }
    canvas.restore();
  }

  void clipPathAndPaint(
      Path path, Clip clipBehavior, Rect bounds, void painter()) {
    _clipAndPaint(
        (bool doAntiAias) => canvas.clipPath(path, doAntiAlias: doAntiAias),
        clipBehavior,
        bounds,
        painter);
  }

  void clipRRectAndPaint(
      RRect rrect, Clip clipBehavior, Rect bounds, void painter()) {
    _clipAndPaint(
        (bool doAntiAias) => canvas.clipRRect(rrect, doAntiAlias: doAntiAias),
        clipBehavior,
        bounds,
        painter);
  }

  void clipRectAndPaint(
      Rect rect, Clip clipBehavior, Rect bounds, void painter()) {
    _clipAndPaint(
        (bool doAntiAias) => canvas.clipRect(rect, doAntiAlias: doAntiAias),
        clipBehavior,
        bounds,
        painter);
  }
}

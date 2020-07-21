import 'package:flutter_web/ui.dart' show TextDirection;

export 'package:flutter_web/ui.dart'
    show
        BlendMode,
        BlurStyle,
        Canvas,
        Clip,
        Color,
        ColorFilter,
        FilterQuality,
        FontStyle,
        FontWeight,
        Locale,
        MaskFilter,
        Offset,
        Paint,
        PaintingStyle,
        Path,
        PathFillType,
        PathOperation,
        Radius,
        RRect,
        RSTransform,
        Rect,
        Shader,
        Size,
        StrokeCap,
        StrokeJoin,
        TextAffinity,
        TextAlign,
        TextBaseline,
        TextBox,
        TextDecoration,
        TextDecorationStyle,
        TextDirection,
        TextPosition,
        TileMode,
        VertexMode,
        VoidCallback,
        hashValues,
        hashList;

enum RenderComparison {
  identical,

  metadata,

  paint,

  layout,
}

enum Axis {
  horizontal,

  vertical,
}

Axis flipAxis(Axis direction) {
  assert(direction != null);
  switch (direction) {
    case Axis.horizontal:
      return Axis.vertical;
    case Axis.vertical:
      return Axis.horizontal;
  }
  return null;
}

enum VerticalDirection {
  up,

  down,
}

enum AxisDirection {
  up,

  right,

  down,

  left,
}

Axis axisDirectionToAxis(AxisDirection axisDirection) {
  assert(axisDirection != null);
  switch (axisDirection) {
    case AxisDirection.up:
    case AxisDirection.down:
      return Axis.vertical;
    case AxisDirection.left:
    case AxisDirection.right:
      return Axis.horizontal;
  }
  return null;
}

AxisDirection textDirectionToAxisDirection(TextDirection textDirection) {
  assert(textDirection != null);
  switch (textDirection) {
    case TextDirection.rtl:
      return AxisDirection.left;
    case TextDirection.ltr:
      return AxisDirection.right;
  }
  return null;
}

AxisDirection flipAxisDirection(AxisDirection axisDirection) {
  assert(axisDirection != null);
  switch (axisDirection) {
    case AxisDirection.up:
      return AxisDirection.down;
    case AxisDirection.right:
      return AxisDirection.left;
    case AxisDirection.down:
      return AxisDirection.up;
    case AxisDirection.left:
      return AxisDirection.right;
  }
  return null;
}

bool axisDirectionIsReversed(AxisDirection axisDirection) {
  assert(axisDirection != null);
  switch (axisDirection) {
    case AxisDirection.up:
    case AxisDirection.left:
      return true;
    case AxisDirection.down:
    case AxisDirection.right:
      return false;
  }
  return null;
}

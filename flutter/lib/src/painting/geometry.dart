import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';

import 'basic_types.dart';

Offset positionDependentBox({
  @required Size size,
  @required Size childSize,
  @required Offset target,
  @required bool preferBelow,
  double verticalOffset = 0.0,
  double margin = 10.0,
}) {
  assert(size != null);
  assert(childSize != null);
  assert(target != null);
  assert(verticalOffset != null);
  assert(preferBelow != null);
  assert(margin != null);

  final bool fitsBelow =
      target.dy + verticalOffset + childSize.height <= size.height - margin;
  final bool fitsAbove =
      target.dy - verticalOffset - childSize.height >= margin;
  final bool tooltipBelow =
      preferBelow ? fitsBelow || !fitsAbove : !(fitsAbove || !fitsBelow);
  double y;
  if (tooltipBelow)
    y = math.min(target.dy + verticalOffset, size.height - margin);
  else
    y = math.max(target.dy - verticalOffset - childSize.height, margin);

  double x;
  if (size.width - margin * 2.0 < childSize.width) {
    x = (size.width - childSize.width) / 2.0;
  } else {
    final double normalizedTargetX =
        target.dx.clamp(margin, size.width - margin);
    final double edge = margin + childSize.width / 2.0;
    if (normalizedTargetX < edge) {
      x = margin;
    } else if (normalizedTargetX > size.width - edge) {
      x = size.width - margin - childSize.width;
    } else {
      x = normalizedTargetX - childSize.width / 2.0;
    }
  }
  return new Offset(x, y);
}

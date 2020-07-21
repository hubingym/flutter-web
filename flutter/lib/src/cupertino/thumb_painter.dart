import 'package:flutter_web/painting.dart';

import 'colors.dart';

class CupertinoThumbPainter {
  CupertinoThumbPainter({
    this.color = CupertinoColors.white,
    this.shadowColor = const Color(0x2C000000),
  }) : _shadowPaint = BoxShadow(
          color: shadowColor,
          blurRadius: 1.0,
        ).toPaint();

  final Color color;

  final Color shadowColor;

  final Paint _shadowPaint;

  static const double radius = 14.0;

  static const double extension = 7.0;

  void paint(Canvas canvas, Rect rect) {
    final RRect rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.shortestSide / 2.0),
    );

    canvas.drawRRect(rrect, _shadowPaint);
    canvas.drawRRect(rrect.shift(const Offset(0.0, 3.0)), _shadowPaint);
    canvas.drawRRect(rrect, Paint()..color = color);
  }
}

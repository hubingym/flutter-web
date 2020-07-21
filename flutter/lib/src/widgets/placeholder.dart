import 'package:flutter_web/rendering.dart';
import 'basic.dart';
import 'framework.dart';

class _PlaceholderPainter extends CustomPainter {
  const _PlaceholderPainter({
    this.color,
    this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final Rect rect = Offset.zero & size;
    final Path path = new Path()
      ..addRect(rect)
      ..addPolygon(<Offset>[rect.topRight, rect.bottomLeft], false)
      ..addPolygon(<Offset>[rect.topLeft, rect.bottomRight], false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PlaceholderPainter oldPainter) {
    return oldPainter.color != color || oldPainter.strokeWidth != strokeWidth;
  }

  @override
  bool hitTest(Offset position) => false;
}

class Placeholder extends StatelessWidget {
  const Placeholder({
    Key key,
    this.color = const Color(0xFF455A64),
    this.strokeWidth = 2.0,
    this.fallbackWidth = 400.0,
    this.fallbackHeight = 400.0,
  }) : super(key: key);

  final Color color;

  final double strokeWidth;

  final double fallbackWidth;

  final double fallbackHeight;

  @override
  Widget build(BuildContext context) {
    return new LimitedBox(
      maxWidth: fallbackWidth,
      maxHeight: fallbackHeight,
      child: new CustomPaint(
        size: Size.infinite,
        foregroundPainter: new _PlaceholderPainter(
          color: color,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

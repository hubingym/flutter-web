import 'package:flutter_web/ui.dart' as ui
    show
        Paragraph,
        ParagraphBuilder,
        ParagraphConstraints,
        ParagraphStyle,
        TextStyle;

import 'box.dart';
import 'object.dart';

const double _kMaxWidth = 100000.0;
const double _kMaxHeight = 100000.0;

const String _kLine = '\n\n────────────────────\n\n';

class RenderErrorBox extends RenderBox {
  RenderErrorBox([this.message = '']) {
    try {
      if (message != '') {
        final ui.ParagraphBuilder builder = ui.ParagraphBuilder(paragraphStyle);
        builder.pushStyle(textStyle);
        builder.addText(
            '$message$_kLine$message$_kLine$message$_kLine$message$_kLine$message$_kLine$message$_kLine'
            '$message$_kLine$message$_kLine$message$_kLine$message$_kLine$message$_kLine$message');
        _paragraph = builder.build();
      }
    } catch (e) {}
  }

  final String message;

  ui.Paragraph _paragraph;

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _kMaxWidth;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _kMaxHeight;
  }

  @override
  bool get sizedByParent => true;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void performResize() {
    size = constraints.constrain(const Size(_kMaxWidth, _kMaxHeight));
  }

  static Color backgroundColor = const Color(0xF0900000);

  static ui.TextStyle textStyle = ui.TextStyle(
    color: const Color(0xFFFFFF66),
    fontFamily: 'monospace',
    fontSize: 14.0,
    fontWeight: FontWeight.bold,
  );

  static ui.ParagraphStyle paragraphStyle = ui.ParagraphStyle(
    height: 1.0,
  );

  @override
  void paint(PaintingContext context, Offset offset) {
    try {
      context.canvas.drawRect(offset & size, Paint()..color = backgroundColor);
      double width;
      if (_paragraph != null) {
        if (parent is RenderBox) {
          final RenderBox parentBox = parent;
          width = parentBox.size.width;
        } else {
          width = size.width;
        }
        _paragraph.layout(ui.ParagraphConstraints(width: width));

        context.canvas.drawParagraph(_paragraph, offset);
      }
    } catch (e) {}
  }
}

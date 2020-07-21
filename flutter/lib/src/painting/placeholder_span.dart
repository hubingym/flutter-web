import 'package:flutter_web/ui.dart' as ui show PlaceholderAlignment;

import 'package:flutter_web/foundation.dart';

import 'basic_types.dart';
import 'inline_span.dart';
import 'text_painter.dart';
import 'text_span.dart';
import 'text_style.dart';

abstract class PlaceholderSpan extends InlineSpan {
  const PlaceholderSpan({
    this.alignment = ui.PlaceholderAlignment.bottom,
    this.baseline,
    TextStyle style,
  }) : super(
          style: style,
        );

  final ui.PlaceholderAlignment alignment;

  final TextBaseline baseline;

  @override
  void computeToPlainText(StringBuffer buffer,
      {bool includeSemanticsLabels = true, bool includePlaceholders = true}) {
    if (includePlaceholders) {
      buffer.write('\uFFFC');
    }
  }

  @override
  void computeSemanticsInformation(
      List<InlineSpanSemanticsInformation> collector) {
    collector.add(InlineSpanSemanticsInformation.placeholder);
  }

  @override
  @Deprecated('Use to visitChildren instead')
  bool visitTextSpan(bool visitor(TextSpan span)) {
    assert(false,
        'visitTextSpan is deprecated. Use visitChildren to support InlineSpans');
    return false;
  }

  @override
  void describeSemantics(Accumulator offset, List<int> semanticsOffsets,
      List<dynamic> semanticsElements) {
    semanticsOffsets.add(offset.value);
    semanticsOffsets.add(offset.value + 1);
    semanticsElements.add(null);
    offset.increment(1);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(EnumProperty<ui.PlaceholderAlignment>('alignment', alignment,
        defaultValue: null));
    properties.add(
        EnumProperty<TextBaseline>('baseline', baseline, defaultValue: null));
  }
}

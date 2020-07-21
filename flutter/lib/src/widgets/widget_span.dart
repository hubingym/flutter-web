import 'package:flutter_web/ui.dart' as ui
    show ParagraphBuilder, PlaceholderAlignment;

import 'package:flutter_web/painting.dart';

import 'framework.dart';

@immutable
class WidgetSpan extends PlaceholderSpan {
  const WidgetSpan({
    @required this.child,
    ui.PlaceholderAlignment alignment = ui.PlaceholderAlignment.bottom,
    TextBaseline baseline,
    TextStyle style,
  })  : assert(child != null),
        assert(baseline != null ||
            !(identical(alignment, ui.PlaceholderAlignment.aboveBaseline) ||
                identical(alignment, ui.PlaceholderAlignment.belowBaseline) ||
                identical(alignment, ui.PlaceholderAlignment.baseline))),
        super(
          alignment: alignment,
          baseline: baseline,
          style: style,
        );

  final Widget child;

  @override
  void build(ui.ParagraphBuilder builder,
      {double textScaleFactor = 1.0,
      @required List<PlaceholderDimensions> dimensions}) {
    assert(debugAssertIsValid());
    assert(dimensions != null);
    final bool hasStyle = style != null;
    if (hasStyle) {
      builder.pushStyle(style.getTextStyle(textScaleFactor: textScaleFactor));
    }
    assert(builder.placeholderCount < dimensions.length);
    final PlaceholderDimensions currentDimensions =
        dimensions[builder.placeholderCount];
    builder.addPlaceholder(
      currentDimensions.size.width,
      currentDimensions.size.height,
      alignment,
      scale: textScaleFactor,
      baseline: currentDimensions.baseline,
      baselineOffset: currentDimensions.baselineOffset,
    );
    if (hasStyle) {
      builder.pop();
    }
  }

  @override
  bool visitChildren(InlineSpanVisitor visitor) {
    return visitor(this);
  }

  @override
  InlineSpan getSpanForPositionVisitor(
      TextPosition position, Accumulator offset) {
    return null;
  }

  @override
  int codeUnitAtVisitor(int index, Accumulator offset) {
    return null;
  }

  @override
  RenderComparison compareTo(InlineSpan other) {
    if (identical(this, other)) return RenderComparison.identical;
    if (other.runtimeType != runtimeType) return RenderComparison.layout;
    if ((style == null) != (other.style == null))
      return RenderComparison.layout;
    final WidgetSpan typedOther = other;
    if (child != typedOther.child || alignment != typedOther.alignment) {
      return RenderComparison.layout;
    }
    RenderComparison result = RenderComparison.identical;
    if (style != null) {
      final RenderComparison candidate = style.compareTo(other.style);
      if (candidate.index > result.index) result = candidate;
      if (result == RenderComparison.layout) return result;
    }
    return result;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    if (super != other) return false;
    final WidgetSpan typedOther = other;
    return typedOther.child == child &&
        typedOther.alignment == alignment &&
        typedOther.baseline == baseline;
  }

  @override
  int get hashCode => hashValues(super.hashCode, child, alignment, baseline);

  @override
  InlineSpan getSpanForPosition(TextPosition position) {
    assert(debugAssertIsValid());
    return null;
  }

  @override
  bool debugAssertIsValid() {
    return true;
  }
}

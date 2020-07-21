import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/services.dart';
import 'package:flutter_web/ui.dart' as ui show ParagraphBuilder;

import 'basic_types.dart';
import 'inline_span.dart';
import 'text_painter.dart';
import 'text_style.dart';

@immutable
class TextSpan extends InlineSpan {
  const TextSpan({
    this.text,
    this.children,
    TextStyle style,
    this.recognizer,
    this.semanticsLabel,
  }) : super(
          style: style,
        );

  @override
  final String text;

  @override
  final List<InlineSpan> children;

  @override
  final GestureRecognizer recognizer;

  final String semanticsLabel;

  @override
  void build(ui.ParagraphBuilder builder,
      {double textScaleFactor = 1.0, List<PlaceholderDimensions> dimensions}) {
    assert(debugAssertIsValid());
    final bool hasStyle = style != null;
    if (hasStyle)
      builder.pushStyle(style.getTextStyle(textScaleFactor: textScaleFactor));
    if (text != null) builder.addText(text);
    if (children != null) {
      for (InlineSpan child in children) {
        assert(child != null);
        child.build(builder,
            textScaleFactor: textScaleFactor, dimensions: dimensions);
      }
    }
    if (hasStyle) builder.pop();
  }

  @override
  bool visitChildren(InlineSpanVisitor visitor) {
    if (text != null) {
      if (!visitor(this)) return false;
    }
    if (children != null) {
      for (InlineSpan child in children) {
        if (!child.visitChildren(visitor)) return false;
      }
    }
    return true;
  }

  @override
  @Deprecated('Use to visitChildren instead')
  bool visitTextSpan(bool visitor(TextSpan span)) {
    if (text != null) {
      if (!visitor(this)) return false;
    }
    if (children != null) {
      for (InlineSpan child in children) {
        assert(child is TextSpan,
            'visitTextSpan is deprecated. Use visitChildren to support InlineSpans');
        final TextSpan textSpanChild = child;
        if (!textSpanChild.visitTextSpan(visitor)) return false;
      }
    }
    return true;
  }

  @override
  InlineSpan getSpanForPositionVisitor(
      TextPosition position, Accumulator offset) {
    if (text == null) {
      return null;
    }
    final TextAffinity affinity = position.affinity;
    final int targetOffset = position.offset;
    final int endOffset = offset.value + text.length;
    if (offset.value == targetOffset && affinity == TextAffinity.downstream ||
        offset.value < targetOffset && targetOffset < endOffset ||
        endOffset == targetOffset && affinity == TextAffinity.upstream) {
      return this;
    }
    offset.increment(text.length);
    return null;
  }

  @override
  void computeToPlainText(StringBuffer buffer,
      {bool includeSemanticsLabels = true, bool includePlaceholders = true}) {
    assert(debugAssertIsValid());
    if (semanticsLabel != null && includeSemanticsLabels) {
      buffer.write(semanticsLabel);
    } else if (text != null) {
      buffer.write(text);
    }
    if (children != null) {
      for (InlineSpan child in children) {
        child.computeToPlainText(
          buffer,
          includeSemanticsLabels: includeSemanticsLabels,
          includePlaceholders: includePlaceholders,
        );
      }
    }
  }

  @override
  void computeSemanticsInformation(
      List<InlineSpanSemanticsInformation> collector) {
    assert(debugAssertIsValid());
    if (text != null || semanticsLabel != null) {
      collector.add(InlineSpanSemanticsInformation(
        text,
        semanticsLabel: semanticsLabel,
        recognizer: recognizer,
      ));
    }
    if (children != null) {
      for (InlineSpan child in children) {
        child.computeSemanticsInformation(collector);
      }
    }
  }

  @override
  int codeUnitAtVisitor(int index, Accumulator offset) {
    if (text == null) {
      return null;
    }
    if (index - offset.value < text.length) {
      return text.codeUnitAt(index - offset.value);
    }
    offset.increment(text.length);
    return null;
  }

  @override
  void describeSemantics(Accumulator offset, List<int> semanticsOffsets,
      List<dynamic> semanticsElements) {
    if (recognizer != null &&
        (recognizer is TapGestureRecognizer ||
            recognizer is LongPressGestureRecognizer)) {
      final int length = semanticsLabel?.length ?? text.length;
      semanticsOffsets.add(offset.value);
      semanticsOffsets.add(offset.value + length);
      semanticsElements.add(recognizer);
    }
    offset.increment(text != null ? text.length : 0);
  }

  @override
  bool debugAssertIsValid() {
    assert(() {
      if (children != null) {
        for (InlineSpan child in children) {
          assert(
              child != null,
              'TextSpan contains a null child.\n...'
              'A TextSpan object with a non-null child list should not have any nulls in its child list.\n'
              'The full text in question was:\n'
              '${toStringDeep(prefixLineOne: '  ')}');
          assert(child.debugAssertIsValid());
        }
      }
      return true;
    }());
    return super.debugAssertIsValid();
  }

  @override
  RenderComparison compareTo(InlineSpan other) {
    if (identical(this, other)) return RenderComparison.identical;
    if (other.runtimeType != runtimeType) return RenderComparison.layout;
    final TextSpan textSpan = other;
    if (textSpan.text != text ||
        children?.length != textSpan.children?.length ||
        (style == null) != (textSpan.style == null))
      return RenderComparison.layout;
    RenderComparison result = recognizer == textSpan.recognizer
        ? RenderComparison.identical
        : RenderComparison.metadata;
    if (style != null) {
      final RenderComparison candidate = style.compareTo(textSpan.style);
      if (candidate.index > result.index) result = candidate;
      if (result == RenderComparison.layout) return result;
    }
    if (children != null) {
      for (int index = 0; index < children.length; index += 1) {
        final RenderComparison candidate =
            children[index].compareTo(textSpan.children[index]);
        if (candidate.index > result.index) result = candidate;
        if (result == RenderComparison.layout) return result;
      }
    }
    return result;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    if (!super.equals(other)) return false;
    final TextSpan typedOther = other;
    return typedOther.text == text &&
        typedOther.recognizer == recognizer &&
        typedOther.semanticsLabel == semanticsLabel &&
        listEquals<InlineSpan>(typedOther.children, children);
  }

  @override
  int get hashCode => hashValues(
      super.hashCode, text, recognizer, semanticsLabel, hashList(children));

  @override
  String toStringShort() => '$runtimeType';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
        .add(StringProperty('text', text, showName: false, defaultValue: null));
    if (style == null && text == null && children == null)
      properties.add(DiagnosticsNode.message('(empty)'));

    properties.add(DiagnosticsProperty<GestureRecognizer>(
      'recognizer',
      recognizer,
      description: recognizer?.runtimeType?.toString(),
      defaultValue: null,
    ));

    if (semanticsLabel != null) {
      properties.add(StringProperty('semanticsLabel', semanticsLabel));
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    if (children == null) return const <DiagnosticsNode>[];
    return children.map<DiagnosticsNode>((InlineSpan child) {
      if (child != null) {
        return child.toDiagnosticsNode();
      } else {
        return DiagnosticsNode.message('<null child>');
      }
    }).toList();
  }
}

import 'package:flutter_web/ui.dart' as ui show ParagraphBuilder;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';

import 'basic_types.dart';
import 'text_painter.dart';
import 'text_span.dart';
import 'text_style.dart';

class Accumulator {
  Accumulator([this._value = 0]);

  int get value => _value;
  int _value;

  void increment(int addend) {
    assert(addend >= 0);
    _value += addend;
  }
}

typedef InlineSpanVisitor = bool Function(InlineSpan span);

@immutable
class InlineSpanSemanticsInformation {
  const InlineSpanSemanticsInformation(this.text,
      {this.isPlaceholder = false, this.semanticsLabel, this.recognizer})
      : assert(text != null),
        assert(isPlaceholder != null),
        assert(isPlaceholder == false ||
            (text == '\uFFFC' && semanticsLabel == null && recognizer == null)),
        requiresOwnNode = isPlaceholder || recognizer != null;

  static const InlineSpanSemanticsInformation placeholder =
      InlineSpanSemanticsInformation('\uFFFC', isPlaceholder: true);

  final String text;

  final String semanticsLabel;

  final GestureRecognizer recognizer;

  final bool isPlaceholder;

  final bool requiresOwnNode;

  @override
  bool operator ==(dynamic other) {
    if (other is! InlineSpanSemanticsInformation) {
      return false;
    }
    return other.text == text &&
        other.semanticsLabel == semanticsLabel &&
        other.recognizer == recognizer &&
        other.isPlaceholder == isPlaceholder;
  }

  @override
  int get hashCode =>
      hashValues(text, semanticsLabel, recognizer, isPlaceholder);

  @override
  String toString() =>
      '$runtimeType{text: $text, semanticsLabel: $semanticsLabel, recognizer: $recognizer}';
}

@immutable
abstract class InlineSpan extends DiagnosticableTree {
  const InlineSpan({
    this.style,
  });

  final TextStyle style;

  @Deprecated(
      'InlineSpan does not innately have text. Use TextSpan.text instead.')
  String get text => null;

  @Deprecated(
      'InlineSpan does not innately have children. Use TextSpan.children instead.')
  List<InlineSpan> get children => null;

  @Deprecated(
      'InlineSpan does not innately have a recognizer. Use TextSpan.recognizer instead.')
  GestureRecognizer get recognizer => null;

  void build(ui.ParagraphBuilder builder,
      {double textScaleFactor = 1.0, List<PlaceholderDimensions> dimensions});

  @Deprecated('Use visitChildren instead')
  bool visitTextSpan(bool visitor(TextSpan span));

  bool visitChildren(InlineSpanVisitor visitor);

  InlineSpan getSpanForPosition(TextPosition position) {
    assert(debugAssertIsValid());
    final Accumulator offset = Accumulator();
    InlineSpan result;
    visitChildren((InlineSpan span) {
      result = span.getSpanForPositionVisitor(position, offset);
      return result == null;
    });
    return result;
  }

  @protected
  InlineSpan getSpanForPositionVisitor(
      TextPosition position, Accumulator offset);

  String toPlainText(
      {bool includeSemanticsLabels = true, bool includePlaceholders = true}) {
    final StringBuffer buffer = StringBuffer();
    computeToPlainText(buffer,
        includeSemanticsLabels: includeSemanticsLabels,
        includePlaceholders: includePlaceholders);
    return buffer.toString();
  }

  List<InlineSpanSemanticsInformation> getSemanticsInformation() {
    final List<InlineSpanSemanticsInformation> collector =
        <InlineSpanSemanticsInformation>[];
    computeSemanticsInformation(collector);
    return collector;
  }

  @protected
  void computeSemanticsInformation(
      List<InlineSpanSemanticsInformation> collector);

  @protected
  void computeToPlainText(StringBuffer buffer,
      {bool includeSemanticsLabels = true, bool includePlaceholders = true});

  int codeUnitAt(int index) {
    if (index < 0) return null;
    final Accumulator offset = Accumulator();
    int result;
    visitChildren((InlineSpan span) {
      result = span.codeUnitAtVisitor(index, offset);
      return result == null;
    });
    return result;
  }

  @protected
  int codeUnitAtVisitor(int index, Accumulator offset);

  @Deprecated('Implement computeSemanticsInformation instead.')
  void describeSemantics(Accumulator offset, List<int> semanticsOffsets,
      List<dynamic> semanticsElements);

  bool debugAssertIsValid() => true;

  RenderComparison compareTo(InlineSpan other);

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final InlineSpan typedOther = other;
    return typedOther.style == style;
  }

  bool equals(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final InlineSpan typedOther = other;
    return typedOther.style == style;
  }

  @override
  int get hashCode => style.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace;

    if (style != null) {
      style.debugFillProperties(properties);
    }
  }
}

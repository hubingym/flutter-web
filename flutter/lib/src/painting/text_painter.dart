import 'dart:math' show min, max;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/services.dart';
import 'package:flutter_web/ui.dart' as ui
    show
        Paragraph,
        ParagraphBuilder,
        ParagraphConstraints,
        ParagraphStyle,
        PlaceholderAlignment;

import 'basic_types.dart';
import 'inline_span.dart';
import 'placeholder_span.dart';
import 'strut_style.dart';
import 'text_span.dart';

export 'package:flutter_web/services.dart' show TextRange, TextSelection;

@immutable
class PlaceholderDimensions {
  const PlaceholderDimensions({
    @required this.size,
    @required this.alignment,
    this.baseline,
    this.baselineOffset,
  })  : assert(size != null),
        assert(alignment != null);

  final Size size;

  final ui.PlaceholderAlignment alignment;

  final double baselineOffset;

  final TextBaseline baseline;

  @override
  String toString() {
    return 'PlaceholderDimensions($size, $baseline)';
  }
}

enum TextWidthBasis {
  parent,

  longestLine,
}

class _CaretMetrics {
  const _CaretMetrics({this.offset, this.fullHeight});

  final Offset offset;

  final double fullHeight;
}

class TextPainter {
  TextPainter({
    TextSpan text,
    TextAlign textAlign = TextAlign.start,
    TextDirection textDirection,
    double textScaleFactor = 1.0,
    int maxLines,
    String ellipsis,
    Locale locale,
    StrutStyle strutStyle,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
  })  : assert(text == null || text.debugAssertIsValid()),
        assert(textAlign != null),
        assert(textScaleFactor != null),
        assert(maxLines == null || maxLines > 0),
        assert(textWidthBasis != null),
        _text = text,
        _textAlign = textAlign,
        _textDirection = textDirection,
        _textScaleFactor = textScaleFactor,
        _maxLines = maxLines,
        _ellipsis = ellipsis,
        _locale = locale,
        _strutStyle = strutStyle,
        _textWidthBasis = textWidthBasis;

  ui.Paragraph _paragraph;
  bool _needsLayout = true;

  TextSpan get text => _text;
  TextSpan _text;
  set text(TextSpan value) {
    assert(value == null || value.debugAssertIsValid());
    if (_text == value) return;
    if (_text?.style != value?.style) _layoutTemplate = null;
    _text = value;
    _paragraph = null;
    _needsLayout = true;
  }

  TextAlign get textAlign => _textAlign;
  TextAlign _textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
    if (_textAlign == value) return;
    _textAlign = value;
    _paragraph = null;
    _needsLayout = true;
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _paragraph = null;
    _layoutTemplate = null;
    _needsLayout = true;
  }

  double get textScaleFactor => _textScaleFactor;
  double _textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textScaleFactor == value) return;
    _textScaleFactor = value;
    _paragraph = null;
    _layoutTemplate = null;
    _needsLayout = true;
  }

  String get ellipsis => _ellipsis;
  String _ellipsis;
  set ellipsis(String value) {
    assert(value == null || value.isNotEmpty);
    if (_ellipsis == value) return;
    _ellipsis = value;
    _paragraph = null;
    _needsLayout = true;
  }

  Locale get locale => _locale;
  Locale _locale;
  set locale(Locale value) {
    if (_locale == value) return;
    _locale = value;
    _paragraph = null;
    _needsLayout = true;
  }

  int get maxLines => _maxLines;
  int _maxLines;

  set maxLines(int value) {
    assert(value == null || value > 0);
    if (_maxLines == value) return;
    _maxLines = value;
    _paragraph = null;
    _needsLayout = true;
  }

  StrutStyle get strutStyle => _strutStyle;
  StrutStyle _strutStyle;
  set strutStyle(StrutStyle value) {
    if (_strutStyle == value) return;
    _strutStyle = value;
    _paragraph = null;
    _needsLayout = true;
  }

  TextWidthBasis get textWidthBasis => _textWidthBasis;
  TextWidthBasis _textWidthBasis;
  set textWidthBasis(TextWidthBasis value) {
    assert(value != null);
    if (_textWidthBasis == value) return;
    _textWidthBasis = value;
    _paragraph = null;
    _needsLayout = true;
  }

  ui.Paragraph _layoutTemplate;

  List<TextBox> get inlinePlaceholderBoxes => _inlinePlaceholderBoxes;
  List<TextBox> _inlinePlaceholderBoxes;

  List<double> get inlinePlaceholderScales => _inlinePlaceholderScales;
  List<double> _inlinePlaceholderScales;

  void setPlaceholderDimensions(List<PlaceholderDimensions> value) {
    if (value == null ||
        value.isEmpty ||
        listEquals(value, _placeholderDimensions)) {
      return;
    }
    assert(() {
          int placeholderCount = 0;
          text.visitChildren((InlineSpan span) {
            if (span is PlaceholderSpan) {
              placeholderCount += 1;
            }
            return true;
          });
          return placeholderCount;
        }() ==
        value.length);
    _placeholderDimensions = value;
    _needsLayout = true;
    _paragraph = null;
  }

  List<PlaceholderDimensions> _placeholderDimensions;

  ui.ParagraphStyle _createParagraphStyle(
      [TextDirection defaultTextDirection]) {
    assert(textAlign != null);
    assert(textDirection != null || defaultTextDirection != null,
        'TextPainter.textDirection must be set to a non-null value before using the TextPainter.');
    return _text.style?.getParagraphStyle(
          textAlign: textAlign,
          textDirection: textDirection ?? defaultTextDirection,
          textScaleFactor: textScaleFactor,
          maxLines: _maxLines,
          ellipsis: _ellipsis,
          locale: _locale,
          strutStyle: _strutStyle,
        ) ??
        ui.ParagraphStyle(
          textAlign: textAlign,
          textDirection: textDirection ?? defaultTextDirection,
          maxLines: maxLines,
          ellipsis: ellipsis,
          locale: locale,
        );
  }

  double get preferredLineHeight {
    if (_layoutTemplate == null) {
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(
        _createParagraphStyle(TextDirection.rtl),
      );
      if (text?.style != null)
        builder.pushStyle(
            text.style.getTextStyle(textScaleFactor: textScaleFactor));
      builder.addText(' ');
      _layoutTemplate = builder.build()
        ..layout(const ui.ParagraphConstraints(width: double.infinity));
    }
    return _layoutTemplate.height;
  }

  double _applyFloatingPointHack(double layoutValue) {
    return layoutValue.ceilToDouble();
  }

  double get minIntrinsicWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.minIntrinsicWidth);
  }

  double get maxIntrinsicWidth {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.maxIntrinsicWidth);
  }

  double get width {
    assert(!_needsLayout);
    return _applyFloatingPointHack(
      _paragraph.width,
    );
  }

  double get height {
    assert(!_needsLayout);
    return _applyFloatingPointHack(_paragraph.height);
  }

  Size get size {
    assert(!_needsLayout);
    return Size(width, height);
  }

  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!_needsLayout);
    assert(baseline != null);
    switch (baseline) {
      case TextBaseline.alphabetic:
        return _paragraph.alphabeticBaseline;
      case TextBaseline.ideographic:
        return _paragraph.ideographicBaseline;
    }
    return null;
  }

  bool get didExceedMaxLines {
    assert(!_needsLayout);
    return _paragraph.didExceedMaxLines;
  }

  double _lastMinWidth;
  double _lastMaxWidth;

  void layout({double minWidth = 0.0, double maxWidth = double.infinity}) {
    assert(text != null,
        'TextPainter.text must be set to a non-null value before using the TextPainter.');
    assert(textDirection != null,
        'TextPainter.textDirection must be set to a non-null value before using the TextPainter.');
    if (!_needsLayout && minWidth == _lastMinWidth && maxWidth == _lastMaxWidth)
      return;
    _needsLayout = false;
    if (_paragraph == null) {
      final ui.ParagraphBuilder builder =
          ui.ParagraphBuilder(_createParagraphStyle());
      _text.build(builder, textScaleFactor: textScaleFactor);
      _paragraph = builder.build();
    }
    _lastMinWidth = minWidth;
    _lastMaxWidth = maxWidth;
    _paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    if (minWidth != maxWidth) {
      final double newWidth = maxIntrinsicWidth.clamp(minWidth, maxWidth);
      if (newWidth != width)
        _paragraph.layout(ui.ParagraphConstraints(width: newWidth));
    }
  }

  void paint(Canvas canvas, Offset offset) {
    assert(() {
      if (_needsLayout) {
        throw FlutterError(
            'TextPainter.paint called when text geometry was not yet calculated.\n'
            'Please call layout() before paint() to position the text before painting it.');
      }
      return true;
    }());
    canvas.drawParagraph(_paragraph, offset);
  }

  bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  int getOffsetAfter(int offset) {
    final int nextCodeUnit = _text.codeUnitAt(offset);
    if (nextCodeUnit == null) return null;

    return _isUtf16Surrogate(nextCodeUnit) ? offset + 2 : offset + 1;
  }

  int getOffsetBefore(int offset) {
    final int prevCodeUnit = _text.codeUnitAt(offset - 1);
    if (prevCodeUnit == null) return null;

    return _isUtf16Surrogate(prevCodeUnit) ? offset - 2 : offset - 1;
  }

  static const int _zwjUtf16 = 0x200d;

  Rect _getRectFromUpstream(int offset, Rect caretPrototype) {
    final String flattenedText = _text.toPlainText();
    final int prevCodeUnit = _text.codeUnitAt(max(0, offset - 1));
    if (prevCodeUnit == null) return null;

    final bool needsSearch = _isUtf16Surrogate(prevCodeUnit) ||
        _text.codeUnitAt(offset) == _zwjUtf16;
    int graphemeClusterLength = needsSearch ? 2 : 1;
    List<TextBox> boxes = <TextBox>[];
    while (boxes.isEmpty && flattenedText != null) {
      final int prevRuneOffset = offset - graphemeClusterLength;
      boxes = _paragraph.getBoxesForRange(prevRuneOffset, offset);

      if (boxes.isEmpty) {
        if (!needsSearch) break;
        if (prevRuneOffset < -flattenedText.length) break;

        graphemeClusterLength *= 2;
        continue;
      }
      final TextBox box = boxes.first;

      const int NEWLINE_CODE_UNIT = 10;
      if (prevCodeUnit == NEWLINE_CODE_UNIT) {
        return Rect.fromLTRB(_emptyOffset.dx, box.bottom, _emptyOffset.dx,
            box.bottom + box.bottom - box.top);
      }

      final double caretEnd = box.end;
      final double dx = box.direction == TextDirection.rtl
          ? caretEnd - caretPrototype.width
          : caretEnd;
      return Rect.fromLTRB(min(dx, width), box.top, min(dx, width), box.bottom);
    }
    return null;
  }

  Rect _getRectFromDownstream(int offset, Rect caretPrototype) {
    final String flattenedText = _text.toPlainText();

    final int nextCodeUnit = _text.codeUnitAt(
        min(offset, flattenedText == null ? 0 : flattenedText.length - 1));
    if (nextCodeUnit == null) return null;

    final bool needsSearch =
        _isUtf16Surrogate(nextCodeUnit) || nextCodeUnit == _zwjUtf16;
    int graphemeClusterLength = needsSearch ? 2 : 1;
    List<TextBox> boxes = <TextBox>[];
    while (boxes.isEmpty && flattenedText != null) {
      final int nextRuneOffset = offset + graphemeClusterLength;
      boxes = _paragraph.getBoxesForRange(offset, nextRuneOffset);

      if (boxes.isEmpty) {
        if (!needsSearch) break;
        if (nextRuneOffset >= flattenedText.length << 1) break;

        graphemeClusterLength *= 2;
        continue;
      }
      final TextBox box = boxes.last;
      final double caretStart = box.start;
      final double dx = box.direction == TextDirection.rtl
          ? caretStart - caretPrototype.width
          : caretStart;
      return Rect.fromLTRB(min(dx, width), box.top, min(dx, width), box.bottom);
    }
    return null;
  }

  Offset get _emptyOffset {
    assert(!_needsLayout);
    assert(textAlign != null);
    switch (textAlign) {
      case TextAlign.left:
        return Offset.zero;
      case TextAlign.right:
        return Offset(width, 0.0);
      case TextAlign.center:
        return Offset(width / 2.0, 0.0);
      case TextAlign.justify:
      case TextAlign.start:
        assert(textDirection != null);
        switch (textDirection) {
          case TextDirection.rtl:
            return Offset(width, 0.0);
          case TextDirection.ltr:
            return Offset.zero;
        }
        return null;
      case TextAlign.end:
        assert(textDirection != null);
        switch (textDirection) {
          case TextDirection.rtl:
            return Offset.zero;
          case TextDirection.ltr:
            return Offset(width, 0.0);
        }
        return null;
    }
    return null;
  }

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    _computeCaretMetrics(position, caretPrototype);
    return _caretMetrics.offset;
  }

  double getFullHeightForCaret(TextPosition position, Rect caretPrototype) {
    _computeCaretMetrics(position, caretPrototype);
    return _caretMetrics.fullHeight;
  }

  _CaretMetrics _caretMetrics;

  TextPosition _previousCaretPosition;
  Rect _previousCaretPrototype;

  void _computeCaretMetrics(TextPosition position, Rect caretPrototype) {
    assert(!_needsLayout);
    if (position == _previousCaretPosition &&
        caretPrototype == _previousCaretPrototype) return;
    final int offset = position.offset;
    assert(position.affinity != null);
    Rect rect;
    switch (position.affinity) {
      case TextAffinity.upstream:
        {
          rect = _getRectFromUpstream(offset, caretPrototype) ??
              _getRectFromDownstream(offset, caretPrototype);
          break;
        }
      case TextAffinity.downstream:
        {
          rect = _getRectFromDownstream(offset, caretPrototype) ??
              _getRectFromUpstream(offset, caretPrototype);
          break;
        }
    }
    _caretMetrics = _CaretMetrics(
      offset: rect != null ? Offset(rect.left, rect.top) : _emptyOffset,
      fullHeight: rect != null ? rect.bottom - rect.top : null,
    );
  }

  List<TextBox> getBoxesForSelection(TextSelection selection) {
    assert(!_needsLayout);
    return _paragraph.getBoxesForRange(selection.start, selection.end);
  }

  TextPosition getPositionForOffset(Offset offset) {
    assert(!_needsLayout);
    return _paragraph.getPositionForOffset(offset);
  }

  TextRange getWordBoundary(TextPosition position) {
    assert(!_needsLayout);
    final List<int> indices = _paragraph.getWordBoundary(position.offset);
    return TextRange(start: indices[0], end: indices[1]);
  }
}

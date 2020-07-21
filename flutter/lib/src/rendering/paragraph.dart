import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/semantics.dart';
import 'package:flutter_web/services.dart';
import 'package:flutter_web/ui.dart' as ui
    show Gradient, Shader, TextBox, PlaceholderAlignment;
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'debug.dart';
import 'object.dart';

enum TextOverflow {
  clip,

  fade,

  ellipsis,

  visible,
}

const String _kEllipsis = '\u2026';

class TextParentData extends ContainerBoxParentData<RenderBox> {
  double scale;

  @override
  String toString() {
    final List<String> values = <String>[];
    if (offset != null) values.add('offset=$offset');
    if (scale != null) values.add('scale=$scale');
    values.add(super.toString());
    return values.join('; ');
  }
}

class RenderParagraph extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TextParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TextParentData> {
  RenderParagraph(
    InlineSpan text, {
    TextAlign textAlign = TextAlign.start,
    @required TextDirection textDirection,
    bool softWrap = true,
    TextOverflow overflow = TextOverflow.clip,
    double textScaleFactor = 1.0,
    int maxLines,
    TextWidthBasis textWidthBasis = TextWidthBasis.parent,
    Locale locale,
    StrutStyle strutStyle,
    List<RenderBox> children,
  })  : assert(text != null),
        assert(text.debugAssertIsValid()),
        assert(textAlign != null),
        assert(textDirection != null),
        assert(softWrap != null),
        assert(overflow != null),
        assert(textScaleFactor != null),
        assert(maxLines == null || maxLines > 0),
        assert(textWidthBasis != null),
        _softWrap = softWrap,
        _overflow = overflow,
        _textPainter = TextPainter(
          text: text,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          maxLines: maxLines,
          ellipsis: overflow == TextOverflow.ellipsis ? _kEllipsis : null,
          locale: locale,
          strutStyle: strutStyle,
          textWidthBasis: textWidthBasis,
        ) {
    addAll(children);
    _extractPlaceholderSpans(text);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TextParentData)
      child.parentData = TextParentData();
  }

  final TextPainter _textPainter;

  InlineSpan get text => _textPainter.text;
  set text(InlineSpan value) {
    assert(value != null);
    switch (_textPainter.text.compareTo(value)) {
      case RenderComparison.identical:
      case RenderComparison.metadata:
        return;
      case RenderComparison.paint:
        _textPainter.text = value;
        _extractPlaceholderSpans(value);
        markNeedsPaint();
        markNeedsSemanticsUpdate();
        break;
      case RenderComparison.layout:
        _textPainter.text = value;
        _overflowShader = null;
        _extractPlaceholderSpans(value);
        markNeedsLayout();
        break;
    }
  }

  List<PlaceholderSpan> _placeholderSpans;
  void _extractPlaceholderSpans(InlineSpan span) {
    _placeholderSpans = <PlaceholderSpan>[];
    span.visitChildren((InlineSpan span) {
      if (span is PlaceholderSpan) {
        final PlaceholderSpan placeholderSpan = span;
        _placeholderSpans.add(placeholderSpan);
      }
      return true;
    });
  }

  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
    if (_textPainter.textAlign == value) return;
    _textPainter.textAlign = value;
    markNeedsPaint();
  }

  TextDirection get textDirection => _textPainter.textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textPainter.textDirection == value) return;
    _textPainter.textDirection = value;
    markNeedsLayout();
  }

  bool get softWrap => _softWrap;
  bool _softWrap;
  set softWrap(bool value) {
    assert(value != null);
    if (_softWrap == value) return;
    _softWrap = value;
    markNeedsLayout();
  }

  TextOverflow get overflow => _overflow;
  TextOverflow _overflow;
  set overflow(TextOverflow value) {
    assert(value != null);
    if (_overflow == value) return;
    _overflow = value;
    _textPainter.ellipsis = value == TextOverflow.ellipsis ? _kEllipsis : null;
    markNeedsLayout();
  }

  double get textScaleFactor => _textPainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textPainter.textScaleFactor == value) return;
    _textPainter.textScaleFactor = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  int get maxLines => _textPainter.maxLines;

  set maxLines(int value) {
    assert(value == null || value > 0);
    if (_textPainter.maxLines == value) return;
    _textPainter.maxLines = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  Locale get locale => _textPainter.locale;

  set locale(Locale value) {
    if (_textPainter.locale == value) return;
    _textPainter.locale = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  StrutStyle get strutStyle => _textPainter.strutStyle;

  set strutStyle(StrutStyle value) {
    if (_textPainter.strutStyle == value) return;
    _textPainter.strutStyle = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  TextWidthBasis get textWidthBasis => _textPainter.textWidthBasis;
  set textWidthBasis(TextWidthBasis value) {
    assert(value != null);
    if (_textPainter.textWidthBasis == value) return;
    _textPainter.textWidthBasis = value;
    _overflowShader = null;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (!_canComputeIntrinsics()) {
      return 0.0;
    }
    _computeChildrenWidthWithMinIntrinsics(height);
    _layoutText();
    return _textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (!_canComputeIntrinsics()) {
      return 0.0;
    }
    _computeChildrenWidthWithMaxIntrinsics(height);
    _layoutText();
    return _textPainter.maxIntrinsicWidth;
  }

  double _computeIntrinsicHeight(double width) {
    if (!_canComputeIntrinsics()) {
      return 0.0;
    }
    _computeChildrenHeightWithMinIntrinsics(width);
    _layoutText(minWidth: width, maxWidth: width);
    return _textPainter.height;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    assert(constraints != null);
    assert(constraints.debugAssertIsValid());
    _layoutTextWithConstraints(constraints);

    return _textPainter
        .computeDistanceToActualBaseline(TextBaseline.alphabetic);
  }

  bool _canComputeIntrinsics() {
    for (PlaceholderSpan span in _placeholderSpans) {
      switch (span.alignment) {
        case ui.PlaceholderAlignment.baseline:
        case ui.PlaceholderAlignment.aboveBaseline:
        case ui.PlaceholderAlignment.belowBaseline:
          {
            assert(
                RenderObject.debugCheckingIntrinsics,
                'Intrinsics are not available for PlaceholderAlignment.baseline, '
                'PlaceholderAlignment.aboveBaseline, or PlaceholderAlignment.belowBaseline,');
            return false;
          }
        case ui.PlaceholderAlignment.top:
        case ui.PlaceholderAlignment.middle:
        case ui.PlaceholderAlignment.bottom:
          {
            continue;
          }
      }
    }
    return true;
  }

  void _computeChildrenWidthWithMaxIntrinsics(double height) {
    RenderBox child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>(childCount);
    int childIndex = 0;
    while (child != null) {
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(child.getMaxIntrinsicWidth(height), height),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    _textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  void _computeChildrenWidthWithMinIntrinsics(double height) {
    RenderBox child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>(childCount);
    int childIndex = 0;
    while (child != null) {
      final double intrinsicWidth = child.getMinIntrinsicWidth(height);
      final double intrinsicHeight =
          child.getMinIntrinsicHeight(intrinsicWidth);
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(intrinsicWidth, intrinsicHeight),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    _textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  void _computeChildrenHeightWithMinIntrinsics(double width) {
    RenderBox child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>(childCount);
    int childIndex = 0;
    while (child != null) {
      final double intrinsicHeight = child.getMinIntrinsicHeight(width);
      final double intrinsicWidth = child.getMinIntrinsicWidth(intrinsicHeight);
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: Size(intrinsicWidth, intrinsicHeight),
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    _textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    RenderBox child = firstChild;
    while (child != null) {
      final TextParentData textParentData = child.parentData;
      final Matrix4 transform = Matrix4.translationValues(
          textParentData.offset.dx, textParentData.offset.dy, 0.0)
        ..scale(
            textParentData.scale, textParentData.scale, textParentData.scale);
      final bool isHit = result.addWithPaintTransform(
        transform: transform,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(() {
            final Offset manualPosition =
                (position - textParentData.offset) / textParentData.scale;
            return (transformed.dx - manualPosition.dx).abs() <
                    precisionErrorTolerance &&
                (transformed.dy - manualPosition.dy).abs() <
                    precisionErrorTolerance;
          }());
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childAfter(child);
    }
    return false;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is! PointerDownEvent) return;
    _layoutTextWithConstraints(constraints);
    final Offset offset = entry.localPosition;
    final TextPosition position = _textPainter.getPositionForOffset(offset);
    final TextSpan span = _textPainter.text.getSpanForPosition(position);
    span?.recognizer?.addPointer(event);
  }

  bool _needsClipping = false;
  ui.Shader _overflowShader;

  @visibleForTesting
  bool get debugHasOverflowShader => _overflowShader != null;

  void _layoutText({double minWidth = 0.0, double maxWidth = double.infinity}) {
    final bool widthMatters = softWrap || overflow == TextOverflow.ellipsis;
    _textPainter.layout(
        minWidth: minWidth,
        maxWidth: widthMatters ? maxWidth : double.infinity);
  }

  void _layoutTextWithConstraints(BoxConstraints constraints) {
    _layoutText(minWidth: constraints.minWidth, maxWidth: constraints.maxWidth);
  }

  void _layoutChildren(BoxConstraints constraints) {
    if (childCount == 0) {
      return;
    }
    RenderBox child = firstChild;
    final List<PlaceholderDimensions> placeholderDimensions =
        List<PlaceholderDimensions>(childCount);
    int childIndex = 0;
    while (child != null) {
      child.layout(
          BoxConstraints(
            maxWidth: constraints.maxWidth,
          ),
          parentUsesSize: true);
      double baselineOffset;
      switch (_placeholderSpans[childIndex].alignment) {
        case ui.PlaceholderAlignment.baseline:
          {
            baselineOffset = child
                .getDistanceToBaseline(_placeholderSpans[childIndex].baseline);
            break;
          }
        default:
          {
            baselineOffset = null;
            break;
          }
      }
      placeholderDimensions[childIndex] = PlaceholderDimensions(
        size: child.size,
        alignment: _placeholderSpans[childIndex].alignment,
        baseline: _placeholderSpans[childIndex].baseline,
        baselineOffset: baselineOffset,
      );
      child = childAfter(child);
      childIndex += 1;
    }
    _textPainter.setPlaceholderDimensions(placeholderDimensions);
  }

  void _setParentData() {
    RenderBox child = firstChild;
    int childIndex = 0;
    while (child != null) {
      final TextParentData textParentData = child.parentData;
      textParentData.offset = Offset(
          _textPainter.inlinePlaceholderBoxes[childIndex].left,
          _textPainter.inlinePlaceholderBoxes[childIndex].top);
      textParentData.scale = _textPainter.inlinePlaceholderScales[childIndex];
      child = childAfter(child);
      childIndex += 1;
    }
  }

  @override
  void performLayout() {
    _layoutChildren(constraints);
    _layoutTextWithConstraints(constraints);
    _setParentData();

    final Size textSize = _textPainter.size;
    final bool textDidExceedMaxLines = _textPainter.didExceedMaxLines;
    size = constraints.constrain(textSize);

    final bool didOverflowHeight =
        size.height < textSize.height || textDidExceedMaxLines;
    final bool didOverflowWidth = size.width < textSize.width;

    final bool hasVisualOverflow = didOverflowWidth || didOverflowHeight;
    if (hasVisualOverflow) {
      switch (_overflow) {
        case TextOverflow.visible:
          _needsClipping = false;
          _overflowShader = null;
          break;
        case TextOverflow.clip:
        case TextOverflow.ellipsis:
          _needsClipping = true;
          _overflowShader = null;
          break;
        case TextOverflow.fade:
          assert(textDirection != null);
          _needsClipping = true;
          final TextPainter fadeSizePainter = TextPainter(
            text: TextSpan(style: _textPainter.text.style, text: '\u2026'),
            textDirection: textDirection,
            textScaleFactor: textScaleFactor,
            locale: locale,
          )..layout();
          if (didOverflowWidth) {
            double fadeEnd, fadeStart;
            switch (textDirection) {
              case TextDirection.rtl:
                fadeEnd = 0.0;
                fadeStart = fadeSizePainter.width;
                break;
              case TextDirection.ltr:
                fadeEnd = size.width;
                fadeStart = fadeEnd - fadeSizePainter.width;
                break;
            }
            _overflowShader = ui.Gradient.linear(
              Offset(fadeStart, 0.0),
              Offset(fadeEnd, 0.0),
              <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
            );
          } else {
            final double fadeEnd = size.height;
            final double fadeStart = fadeEnd - fadeSizePainter.height / 2.0;
            _overflowShader = ui.Gradient.linear(
              Offset(0.0, fadeStart),
              Offset(0.0, fadeEnd),
              <Color>[const Color(0xFFFFFFFF), const Color(0x00FFFFFF)],
            );
          }
          break;
      }
    } else {
      _needsClipping = false;
      _overflowShader = null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _layoutTextWithConstraints(constraints);
    final Canvas canvas = context.canvas;

    assert(() {
      if (debugRepaintTextRainbowEnabled) {
        final Paint paint = Paint()..color = debugCurrentRepaintColor.toColor();
        canvas.drawRect(offset & size, paint);
      }
      return true;
    }());

    if (_needsClipping) {
      final Rect bounds = offset & size;
      if (_overflowShader != null) {
        canvas.saveLayer(bounds, Paint());
      } else {
        canvas.save();
      }
      canvas.clipRect(bounds);
    }
    _textPainter.paint(canvas, offset);
    if (_needsClipping) {
      if (_overflowShader != null) {
        canvas.translate(offset.dx, offset.dy);
        final Paint paint = Paint()
          ..blendMode = BlendMode.modulate
          ..shader = _overflowShader;
        canvas.drawRect(Offset.zero & size, paint);
      }
      canvas.restore();
    }
  }

  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getOffsetForCaret(position, caretPrototype);
  }

  List<ui.TextBox> getBoxesForSelection(TextSelection selection) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getBoxesForSelection(selection);
  }

  TextPosition getPositionForOffset(Offset offset) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getPositionForOffset(offset);
  }

  TextRange getWordBoundary(TextPosition position) {
    assert(!debugNeedsLayout);
    _layoutTextWithConstraints(constraints);
    return _textPainter.getWordBoundary(position);
  }

  Size get textSize {
    assert(!debugNeedsLayout);
    return _textPainter.size;
  }

  List<InlineSpanSemanticsInformation> _semanticsInfo;

  List<InlineSpanSemanticsInformation> _combineSemanticsInfo() {
    assert(_semanticsInfo != null);
    final List<InlineSpanSemanticsInformation> combined =
        <InlineSpanSemanticsInformation>[];
    String workingText = '';
    String workingLabel;
    for (InlineSpanSemanticsInformation info in _semanticsInfo) {
      if (info.requiresOwnNode) {
        if (workingText != null) {
          combined.add(InlineSpanSemanticsInformation(
            workingText,
            semanticsLabel: workingLabel ?? workingText,
          ));
          workingText = '';
          workingLabel = null;
        }
        combined.add(info);
      } else {
        workingText += info.text;
        workingLabel ??= '';
        if (info.semanticsLabel != null) {
          workingLabel += info.semanticsLabel;
        } else {
          workingLabel += info.text;
        }
      }
    }
    if (workingText != null) {
      combined.add(InlineSpanSemanticsInformation(
        workingText,
        semanticsLabel: workingLabel,
      ));
    } else {
      assert(workingLabel != null);
    }
    return combined;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _semanticsInfo = text.getSemanticsInformation();

    if (_semanticsInfo.any(
        (InlineSpanSemanticsInformation info) => info.recognizer != null)) {
      config.explicitChildNodes = true;
      config.isSemanticBoundary = true;
    } else {
      final StringBuffer buffer = StringBuffer();
      for (InlineSpanSemanticsInformation info in _semanticsInfo) {
        buffer.write(info.semanticsLabel ?? info.text);
      }
      config.label = buffer.toString();
      config.textDirection = textDirection;
    }
  }

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config,
      Iterable<SemanticsNode> children) {
    assert(_semanticsInfo != null && _semanticsInfo.isNotEmpty);
    final List<SemanticsNode> newChildren = <SemanticsNode>[];
    TextDirection currentDirection = textDirection;
    Rect currentRect;
    double ordinal = 0.0;
    int start = 0;
    int placeholderIndex = 0;
    RenderBox child = firstChild;
    for (InlineSpanSemanticsInformation info in _combineSemanticsInfo()) {
      final TextDirection initialDirection = currentDirection;
      final TextSelection selection = TextSelection(
          baseOffset: start, extentOffset: start + info.text.length);
      final List<ui.TextBox> rects = getBoxesForSelection(selection);
      if (rects.isEmpty) {
        continue;
      }
      Rect rect = rects.first.toRect();
      currentDirection = rects.first.direction;
      for (ui.TextBox textBox in rects.skip(1)) {
        rect = rect.expandToInclude(textBox.toRect());
        currentDirection = textBox.direction;
      }

      rect = Rect.fromLTWH(
        math.max(0.0, rect.left),
        math.max(0.0, rect.top),
        math.min(rect.width, constraints.maxWidth),
        math.min(rect.height, constraints.maxHeight),
      );

      currentRect = Rect.fromLTRB(
        rect.left.floorToDouble() - 4.0,
        rect.top.floorToDouble() - 4.0,
        rect.right.ceilToDouble() + 4.0,
        rect.bottom.ceilToDouble() + 4.0,
      );

      if (info.isPlaceholder) {
        final SemanticsNode childNode = children.elementAt(placeholderIndex++);
        final TextParentData parentData = child.parentData;
        childNode.rect = Rect.fromLTWH(
          childNode.rect.left,
          childNode.rect.top,
          childNode.rect.width * parentData.scale,
          childNode.rect.height * parentData.scale,
        );
        newChildren.add(childNode);
        child = childAfter(child);
      } else {
        final SemanticsConfiguration configuration = SemanticsConfiguration()
          ..sortKey = OrdinalSortKey(ordinal++)
          ..textDirection = initialDirection
          ..label = info.semanticsLabel ?? info.text;
        if (info.recognizer != null) {
          if (info.recognizer is TapGestureRecognizer) {
            final TapGestureRecognizer recognizer = info.recognizer;
            configuration.onTap = recognizer.onTap;
          } else if (info.recognizer is LongPressGestureRecognizer) {
            final LongPressGestureRecognizer recognizer = info.recognizer;
            configuration.onLongPress = recognizer.onLongPress;
          } else {
            assert(false);
          }
        }
        newChildren.add(
          SemanticsNode()
            ..updateWith(config: configuration)
            ..rect = currentRect,
        );
      }
      start += info.text.length;
    }
    node.updateWith(config: config, childrenInInversePaintOrder: newChildren);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      text.toDiagnosticsNode(
          name: 'text', style: DiagnosticsTreeStyle.transition)
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
    properties.add(FlagProperty('softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
        ifFalse: 'no wrapping except at line break characters',
        showName: true));
    properties.add(EnumProperty<TextOverflow>('overflow', overflow));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, ifNull: 'unlimited'));
  }
}

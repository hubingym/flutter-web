import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/src/util.dart';
import 'package:flutter_web/ui.dart';

import 'box.dart';
import 'debug_overflow_indicator.dart';
import 'object.dart';

enum FlexFit {
  tight,

  loose,
}

class FlexParentData extends ContainerBoxParentData<RenderBox> {
  int flex;

  FlexFit fit;

  @override
  String toString() {
    if (assertionsEnabled) {
      return '${super.toString()}; flex=$flex; fit=$fit';
    } else {
      return super.toString();
    }
  }
}

enum MainAxisSize {
  min,

  max,
}

enum MainAxisAlignment {
  start,

  end,

  center,

  spaceBetween,

  spaceAround,

  spaceEvenly,
}

enum CrossAxisAlignment {
  start,

  end,

  center,

  stretch,

  baseline,
}

bool _startIsTopLeft(Axis direction, TextDirection textDirection,
    VerticalDirection verticalDirection) {
  assert(direction != null);

  switch (direction) {
    case Axis.horizontal:
      switch (textDirection) {
        case TextDirection.ltr:
          return true;
        case TextDirection.rtl:
          return false;
      }
      break;
    case Axis.vertical:
      switch (verticalDirection) {
        case VerticalDirection.down:
          return true;
        case VerticalDirection.up:
          return false;
      }
      break;
  }
  return null;
}

typedef _ChildSizingFunction = double Function(RenderBox child, double extent);

class RenderFlex extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FlexParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData>,
        DebugOverflowIndicatorMixin {
  RenderFlex({
    List<RenderBox> children,
    Axis direction = Axis.horizontal,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
  })  : assert(direction != null),
        assert(mainAxisAlignment != null),
        assert(mainAxisSize != null),
        assert(crossAxisAlignment != null),
        _direction = direction,
        _mainAxisAlignment = mainAxisAlignment,
        _mainAxisSize = mainAxisSize,
        _crossAxisAlignment = crossAxisAlignment,
        _textDirection = textDirection,
        _verticalDirection = verticalDirection,
        _textBaseline = textBaseline {
    addAll(children);
  }

  Axis get direction => _direction;
  Axis _direction;
  set direction(Axis value) {
    assert(value != null);
    if (_direction != value) {
      _direction = value;
      markNeedsLayout();
    }
  }

  MainAxisAlignment get mainAxisAlignment => _mainAxisAlignment;
  MainAxisAlignment _mainAxisAlignment;
  set mainAxisAlignment(MainAxisAlignment value) {
    assert(value != null);
    if (_mainAxisAlignment != value) {
      _mainAxisAlignment = value;
      markNeedsLayout();
    }
  }

  MainAxisSize get mainAxisSize => _mainAxisSize;
  MainAxisSize _mainAxisSize;
  set mainAxisSize(MainAxisSize value) {
    assert(value != null);
    if (_mainAxisSize != value) {
      _mainAxisSize = value;
      markNeedsLayout();
    }
  }

  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    assert(value != null);
    if (_crossAxisAlignment != value) {
      _crossAxisAlignment = value;
      markNeedsLayout();
    }
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  VerticalDirection get verticalDirection => _verticalDirection;
  VerticalDirection _verticalDirection;
  set verticalDirection(VerticalDirection value) {
    if (_verticalDirection != value) {
      _verticalDirection = value;
      markNeedsLayout();
    }
  }

  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  set textBaseline(TextBaseline value) {
    assert(_crossAxisAlignment != CrossAxisAlignment.baseline || value != null);
    if (_textBaseline != value) {
      _textBaseline = value;
      markNeedsLayout();
    }
  }

  bool get _debugHasNecessaryDirections {
    assert(direction != null);
    assert(crossAxisAlignment != null);
    if (firstChild != null && lastChild != firstChild) {
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null,
              'Horizontal $runtimeType with multiple children has a null textDirection, so the layout order is undefined.');
          break;
        case Axis.vertical:
          assert(verticalDirection != null,
              'Vertical $runtimeType with multiple children has a null verticalDirection, so the layout order is undefined.');
          break;
      }
    }
    if (mainAxisAlignment == MainAxisAlignment.start ||
        mainAxisAlignment == MainAxisAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(textDirection != null,
              'Horizontal $runtimeType with $mainAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
          break;
        case Axis.vertical:
          assert(verticalDirection != null,
              'Vertical $runtimeType with $mainAxisAlignment has a null verticalDirection, so the alignment cannot be resolved.');
          break;
      }
    }
    if (crossAxisAlignment == CrossAxisAlignment.start ||
        crossAxisAlignment == CrossAxisAlignment.end) {
      switch (direction) {
        case Axis.horizontal:
          assert(verticalDirection != null,
              'Horizontal $runtimeType with $crossAxisAlignment has a null verticalDirection, so the alignment cannot be resolved.');
          break;
        case Axis.vertical:
          assert(textDirection != null,
              'Vertical $runtimeType with $crossAxisAlignment has a null textDirection, so the alignment cannot be resolved.');
          break;
      }
    }
    return true;
  }

  double _overflow;

  bool get _hasOverflow => _overflow > precisionErrorTolerance;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FlexParentData)
      child.parentData = FlexParentData();
  }

  double _getIntrinsicSize({
    Axis sizingDirection,
    double extent,
    _ChildSizingFunction childSize,
  }) {
    if (_direction == sizingDirection) {
      double totalFlex = 0.0;
      double inflexibleSpace = 0.0;
      double maxFlexFractionSoFar = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        totalFlex += flex;
        if (flex > 0) {
          final double flexFraction =
              childSize(child, extent) / _getFlex(child);
          maxFlexFractionSoFar = math.max(maxFlexFractionSoFar, flexFraction);
        } else {
          inflexibleSpace += childSize(child, extent);
        }
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
      return maxFlexFractionSoFar * totalFlex + inflexibleSpace;
    } else {
      final double availableMainSpace = extent;
      int totalFlex = 0;
      double inflexibleSpace = 0.0;
      double maxCrossSize = 0.0;
      RenderBox child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        totalFlex += flex;
        double mainSize;
        double crossSize;
        if (flex == 0) {
          switch (_direction) {
            case Axis.horizontal:
              mainSize = child.getMaxIntrinsicWidth(double.infinity);
              crossSize = childSize(child, mainSize);
              break;
            case Axis.vertical:
              mainSize = child.getMaxIntrinsicHeight(double.infinity);
              crossSize = childSize(child, mainSize);
              break;
          }
          inflexibleSpace += mainSize;
          maxCrossSize = math.max(maxCrossSize, crossSize);
        }
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }

      final double spacePerFlex =
          math.max(0.0, (availableMainSpace - inflexibleSpace) / totalFlex);

      child = firstChild;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0)
          maxCrossSize =
              math.max(maxCrossSize, childSize(child, spacePerFlex * flex));
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }

      return maxCrossSize;
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) =>
          child.getMinIntrinsicWidth(extent),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicSize(
      sizingDirection: Axis.horizontal,
      extent: height,
      childSize: (RenderBox child, double extent) =>
          child.getMaxIntrinsicWidth(extent),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) =>
          child.getMinIntrinsicHeight(extent),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicSize(
      sizingDirection: Axis.vertical,
      extent: width,
      childSize: (RenderBox child, double extent) =>
          child.getMaxIntrinsicHeight(extent),
    );
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (_direction == Axis.horizontal)
      return defaultComputeDistanceToHighestActualBaseline(baseline);
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  int _getFlex(RenderBox child) {
    final FlexParentData childParentData = child.parentData;
    return childParentData.flex ?? 0;
  }

  FlexFit _getFit(RenderBox child) {
    final FlexParentData childParentData = child.parentData;
    return childParentData.fit ?? FlexFit.tight;
  }

  double _getCrossSize(RenderBox child) {
    switch (_direction) {
      case Axis.horizontal:
        return child.size.height;
      case Axis.vertical:
        return child.size.width;
    }
    return null;
  }

  double _getMainSize(RenderBox child) {
    switch (_direction) {
      case Axis.horizontal:
        return child.size.width;
      case Axis.vertical:
        return child.size.height;
    }
    return null;
  }

  @override
  void performLayout() {
    assert(_debugHasNecessaryDirections);

    int totalFlex = 0;
    int totalChildren = 0;
    assert(constraints != null);
    final double maxMainSize = _direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;
    final bool canFlex = maxMainSize < double.infinity;

    double crossSize = 0.0;
    double allocatedSize = 0.0;
    RenderBox child = firstChild;
    RenderBox lastFlexChild;
    while (child != null) {
      final FlexParentData childParentData = child.parentData;
      totalChildren++;
      final int flex = _getFlex(child);
      if (flex > 0) {
        assert(() {
          final String identity =
              _direction == Axis.horizontal ? 'row' : 'column';
          final String axis =
              _direction == Axis.horizontal ? 'horizontal' : 'vertical';
          final String dimension =
              _direction == Axis.horizontal ? 'width' : 'height';
          DiagnosticsNode error, message;
          final List<DiagnosticsNode> addendum = <DiagnosticsNode>[];
          if (!canFlex &&
              (mainAxisSize == MainAxisSize.max ||
                  _getFit(child) == FlexFit.tight)) {
            error = ErrorSummary(
                'RenderFlex children have non-zero flex but incoming $dimension constraints are unbounded.');
            message = ErrorDescription(
                'When a $identity is in a parent that does not provide a finite $dimension constraint, for example '
                'if it is in a $axis scrollable, it will try to shrink-wrap its children along the $axis '
                'axis. Setting a flex on a child (e.g. using Expanded) indicates that the child is to '
                'expand to fill the remaining space in the $axis direction.');
            RenderBox node = this;
            switch (_direction) {
              case Axis.horizontal:
                while (!node.constraints.hasBoundedWidth &&
                    node.parent is RenderBox) node = node.parent;
                if (!node.constraints.hasBoundedWidth) node = null;
                break;
              case Axis.vertical:
                while (!node.constraints.hasBoundedHeight &&
                    node.parent is RenderBox) node = node.parent;
                if (!node.constraints.hasBoundedHeight) node = null;
                break;
            }
            if (node != null) {
              addendum.add(node.describeForError(
                  'The nearest ancestor providing an unbounded width constraint is'));
            }
            addendum.add(ErrorHint('See also: https://flutter.dev/layout/'));
          } else {
            return true;
          }
          throw FlutterError.fromParts(<DiagnosticsNode>[
            error,
            message,
            ErrorDescription(
                'These two directives are mutually exclusive. If a parent is to shrink-wrap its child, the child '
                'cannot simultaneously expand to fit its parent.'),
            ErrorHint(
                'Consider setting mainAxisSize to MainAxisSize.min and using FlexFit.loose fits for the flexible '
                'children (using Flexible rather than Expanded). This will allow the flexible children '
                'to size themselves to less than the infinite remaining space they would otherwise be '
                'forced to take, and then will cause the RenderFlex to shrink-wrap the children '
                'rather than expanding to fit the maximum constraints provided by the parent.'),
            ErrorDescription(
                'If this message did not help you determine the problem, consider using debugDumpRenderTree():\n'
                '  https://flutter.dev/debugging/#rendering-layer\n'
                '  http://docs.flutter.io/flutter/rendering/debugDumpRenderTree.html'),
            describeForError('The affected RenderFlex is',
                style: DiagnosticsTreeStyle.errorProperty),
            DiagnosticsProperty<dynamic>(
                'The creator information is set to', debugCreator,
                style: DiagnosticsTreeStyle.errorProperty)
          ]
            ..addAll(addendum)
            ..add(ErrorDescription(
                'If none of the above helps enough to fix this problem, please don\'t hesitate to file a bug:\n'
                '  https://github.com/flutter/flutter/issues/new?template=BUG.md')));
        }());
        totalFlex += childParentData.flex;
        lastFlexChild = child;
      } else {
        BoxConstraints innerConstraints;
        if (crossAxisAlignment == CrossAxisAlignment.stretch) {
          switch (_direction) {
            case Axis.horizontal:
              innerConstraints = BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxHeight: constraints.maxHeight);
              break;
            case Axis.vertical:
              innerConstraints = BoxConstraints(
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth);
              break;
          }
        } else {
          switch (_direction) {
            case Axis.horizontal:
              innerConstraints =
                  BoxConstraints(maxHeight: constraints.maxHeight);
              break;
            case Axis.vertical:
              innerConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
              break;
          }
        }
        child.layout(innerConstraints, parentUsesSize: true);
        allocatedSize += _getMainSize(child);
        crossSize = math.max(crossSize, _getCrossSize(child));
      }
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }

    final double freeSpace =
        math.max(0.0, (canFlex ? maxMainSize : 0.0) - allocatedSize);
    double allocatedFlexSpace = 0.0;
    double maxBaselineDistance = 0.0;
    if (totalFlex > 0 || crossAxisAlignment == CrossAxisAlignment.baseline) {
      final double spacePerFlex =
          canFlex && totalFlex > 0 ? (freeSpace / totalFlex) : double.nan;
      child = firstChild;
      double maxSizeAboveBaseline = 0;
      double maxSizeBelowBaseline = 0;
      while (child != null) {
        final int flex = _getFlex(child);
        if (flex > 0) {
          final double maxChildExtent = canFlex
              ? (child == lastFlexChild
                  ? (freeSpace - allocatedFlexSpace)
                  : spacePerFlex * flex)
              : double.infinity;
          double minChildExtent;
          switch (_getFit(child)) {
            case FlexFit.tight:
              assert(maxChildExtent < double.infinity);
              minChildExtent = maxChildExtent;
              break;
            case FlexFit.loose:
              minChildExtent = 0.0;
              break;
          }
          assert(minChildExtent != null);
          BoxConstraints innerConstraints;
          if (crossAxisAlignment == CrossAxisAlignment.stretch) {
            switch (_direction) {
              case Axis.horizontal:
                innerConstraints = BoxConstraints(
                    minWidth: minChildExtent,
                    maxWidth: maxChildExtent,
                    minHeight: constraints.maxHeight,
                    maxHeight: constraints.maxHeight);
                break;
              case Axis.vertical:
                innerConstraints = BoxConstraints(
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                    minHeight: minChildExtent,
                    maxHeight: maxChildExtent);
                break;
            }
          } else {
            switch (_direction) {
              case Axis.horizontal:
                innerConstraints = BoxConstraints(
                    minWidth: minChildExtent,
                    maxWidth: maxChildExtent,
                    maxHeight: constraints.maxHeight);
                break;
              case Axis.vertical:
                innerConstraints = BoxConstraints(
                    maxWidth: constraints.maxWidth,
                    minHeight: minChildExtent,
                    maxHeight: maxChildExtent);
                break;
            }
          }
          child.layout(innerConstraints, parentUsesSize: true);
          final double childSize = _getMainSize(child);
          assert(childSize <= maxChildExtent);
          allocatedSize += childSize;
          allocatedFlexSpace += maxChildExtent;
          crossSize = math.max(crossSize, _getCrossSize(child));
        }
        if (crossAxisAlignment == CrossAxisAlignment.baseline) {
          assert(() {
            if (textBaseline == null)
              throw FlutterError(
                  'To use FlexAlignItems.baseline, you must also specify which baseline to use using the "baseline" argument.');
            return true;
          }());
          final double distance =
              child.getDistanceToBaseline(textBaseline, onlyReal: true);
          if (distance != null) {
            maxBaselineDistance = math.max(maxBaselineDistance, distance);
            maxSizeAboveBaseline = math.max(
              distance,
              maxSizeAboveBaseline,
            );
            maxSizeBelowBaseline = math.max(
              child.size.height - distance,
              maxSizeBelowBaseline,
            );
            crossSize = maxSizeAboveBaseline + maxSizeBelowBaseline;
          }
        }
        final FlexParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
    }

    final double idealSize = canFlex && mainAxisSize == MainAxisSize.max
        ? maxMainSize
        : allocatedSize;
    double actualSize;
    double actualSizeDelta;
    switch (_direction) {
      case Axis.horizontal:
        size = constraints.constrain(Size(idealSize, crossSize));
        actualSize = size.width;
        crossSize = size.height;
        break;
      case Axis.vertical:
        size = constraints.constrain(Size(crossSize, idealSize));
        actualSize = size.height;
        crossSize = size.width;
        break;
    }
    actualSizeDelta = actualSize - allocatedSize;
    _overflow = math.max(0.0, -actualSizeDelta);
    final double remainingSpace = math.max(0.0, actualSizeDelta);
    double leadingSpace;
    double betweenSpace;

    final bool flipMainAxis =
        !(_startIsTopLeft(direction, textDirection, verticalDirection) ?? true);
    switch (_mainAxisAlignment) {
      case MainAxisAlignment.start:
        leadingSpace = 0.0;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.end:
        leadingSpace = remainingSpace;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.center:
        leadingSpace = remainingSpace / 2.0;
        betweenSpace = 0.0;
        break;
      case MainAxisAlignment.spaceBetween:
        leadingSpace = 0.0;
        betweenSpace =
            totalChildren > 1 ? remainingSpace / (totalChildren - 1) : 0.0;
        break;
      case MainAxisAlignment.spaceAround:
        betweenSpace = totalChildren > 0 ? remainingSpace / totalChildren : 0.0;
        leadingSpace = betweenSpace / 2.0;
        break;
      case MainAxisAlignment.spaceEvenly:
        betweenSpace =
            totalChildren > 0 ? remainingSpace / (totalChildren + 1) : 0.0;
        leadingSpace = betweenSpace;
        break;
    }

    double childMainPosition =
        flipMainAxis ? actualSize - leadingSpace : leadingSpace;
    child = firstChild;
    while (child != null) {
      final FlexParentData childParentData = child.parentData;
      double childCrossPosition;
      switch (_crossAxisAlignment) {
        case CrossAxisAlignment.start:
        case CrossAxisAlignment.end:
          childCrossPosition = _startIsTopLeft(
                      flipAxis(direction), textDirection, verticalDirection) ==
                  (_crossAxisAlignment == CrossAxisAlignment.start)
              ? 0.0
              : crossSize - _getCrossSize(child);
          break;
        case CrossAxisAlignment.center:
          childCrossPosition = crossSize / 2.0 - _getCrossSize(child) / 2.0;
          break;
        case CrossAxisAlignment.stretch:
          childCrossPosition = 0.0;
          break;
        case CrossAxisAlignment.baseline:
          childCrossPosition = 0.0;
          if (_direction == Axis.horizontal) {
            assert(textBaseline != null);
            final double distance =
                child.getDistanceToBaseline(textBaseline, onlyReal: true);
            if (distance != null)
              childCrossPosition = maxBaselineDistance - distance;
          }
          break;
      }
      if (flipMainAxis) childMainPosition -= _getMainSize(child);
      switch (_direction) {
        case Axis.horizontal:
          childParentData.offset =
              Offset(childMainPosition, childCrossPosition);
          break;
        case Axis.vertical:
          childParentData.offset =
              Offset(childCrossPosition, childMainPosition);
          break;
      }
      if (flipMainAxis) {
        childMainPosition -= betweenSpace;
      } else {
        childMainPosition += _getMainSize(child) + betweenSpace;
      }
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_hasOverflow) {
      defaultPaint(context, offset);
      return;
    }

    if (size.isEmpty) return;

    context.pushClipRect(
        needsCompositing, offset, Offset.zero & size, defaultPaint);

    assert(() {
      final List<DiagnosticsNode> debugOverflowHints = <DiagnosticsNode>[
        ErrorDescription(
            'The overflowing $runtimeType has an orientation of $_direction.'),
        ErrorDescription(
            'The edge of the $runtimeType that is overflowing has been marked '
            'in the rendering with a yellow and black striped pattern. This is '
            'usually caused by the contents being too big for the $runtimeType.'),
        ErrorHint(
            'Consider applying a flex factor (e.g. using an Expanded widget) to '
            'force the children of the $runtimeType to fit within the available '
            'space instead of being sized to their natural size.'),
        ErrorHint(
            'This is considered an error condition because it indicates that there '
            'is content that cannot be seen. If the content is legitimately bigger '
            'than the available space, consider clipping it with a ClipRect widget '
            'before putting it in the flex, or using a scrollable container rather '
            'than a Flex, like a ListView.')
      ];

      Rect overflowChildRect;
      switch (_direction) {
        case Axis.horizontal:
          overflowChildRect =
              Rect.fromLTWH(0.0, 0.0, size.width + _overflow, 0.0);
          break;
        case Axis.vertical:
          overflowChildRect =
              Rect.fromLTWH(0.0, 0.0, 0.0, size.height + _overflow);
          break;
      }
      paintOverflowIndicator(
          context, offset, Offset.zero & size, overflowChildRect,
          overflowHints: debugOverflowHints);
      return true;
    }());
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) =>
      _hasOverflow ? Offset.zero & size : null;

  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (_overflow is double && _hasOverflow) header += ' OVERFLOWING';
    return header;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<MainAxisAlignment>(
        'mainAxisAlignment', mainAxisAlignment));
    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize));
    properties.add(EnumProperty<CrossAxisAlignment>(
        'crossAxisAlignment', crossAxisAlignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>(
        'verticalDirection', verticalDirection,
        defaultValue: null));
    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline,
        defaultValue: null));
  }
}

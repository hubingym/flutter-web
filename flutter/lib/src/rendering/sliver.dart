import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:vector_math/vector_math_64.dart';

import 'binding.dart';
import 'box.dart';
import 'debug.dart';
import 'object.dart';
import 'viewport_offset.dart';

enum GrowthDirection {
  forward,

  reverse,
}

AxisDirection applyGrowthDirectionToAxisDirection(
    AxisDirection axisDirection, GrowthDirection growthDirection) {
  assert(axisDirection != null);
  assert(growthDirection != null);
  switch (growthDirection) {
    case GrowthDirection.forward:
      return axisDirection;
    case GrowthDirection.reverse:
      return flipAxisDirection(axisDirection);
  }
  return null;
}

ScrollDirection applyGrowthDirectionToScrollDirection(
    ScrollDirection scrollDirection, GrowthDirection growthDirection) {
  assert(scrollDirection != null);
  assert(growthDirection != null);
  switch (growthDirection) {
    case GrowthDirection.forward:
      return scrollDirection;
    case GrowthDirection.reverse:
      return flipScrollDirection(scrollDirection);
  }
  return null;
}

class SliverConstraints extends Constraints {
  const SliverConstraints({
    @required this.axisDirection,
    @required this.growthDirection,
    @required this.userScrollDirection,
    @required this.scrollOffset,
    @required this.precedingScrollExtent,
    @required this.overlap,
    @required this.remainingPaintExtent,
    @required this.crossAxisExtent,
    @required this.crossAxisDirection,
    @required this.viewportMainAxisExtent,
    @required this.remainingCacheExtent,
    @required this.cacheOrigin,
  })  : assert(axisDirection != null),
        assert(growthDirection != null),
        assert(userScrollDirection != null),
        assert(scrollOffset != null),
        assert(precedingScrollExtent != null),
        assert(overlap != null),
        assert(remainingPaintExtent != null),
        assert(crossAxisExtent != null),
        assert(crossAxisDirection != null),
        assert(viewportMainAxisExtent != null),
        assert(remainingCacheExtent != null),
        assert(cacheOrigin != null);

  SliverConstraints copyWith({
    AxisDirection axisDirection,
    GrowthDirection growthDirection,
    ScrollDirection userScrollDirection,
    double scrollOffset,
    double precedingScrollExtent,
    double overlap,
    double remainingPaintExtent,
    double crossAxisExtent,
    AxisDirection crossAxisDirection,
    double viewportMainAxisExtent,
    double remainingCacheExtent,
    double cacheOrigin,
  }) {
    return SliverConstraints(
      axisDirection: axisDirection ?? this.axisDirection,
      growthDirection: growthDirection ?? this.growthDirection,
      userScrollDirection: userScrollDirection ?? this.userScrollDirection,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      precedingScrollExtent:
          precedingScrollExtent ?? this.precedingScrollExtent,
      overlap: overlap ?? this.overlap,
      remainingPaintExtent: remainingPaintExtent ?? this.remainingPaintExtent,
      crossAxisExtent: crossAxisExtent ?? this.crossAxisExtent,
      crossAxisDirection: crossAxisDirection ?? this.crossAxisDirection,
      viewportMainAxisExtent:
          viewportMainAxisExtent ?? this.viewportMainAxisExtent,
      remainingCacheExtent: remainingCacheExtent ?? this.remainingCacheExtent,
      cacheOrigin: cacheOrigin ?? this.cacheOrigin,
    );
  }

  final AxisDirection axisDirection;

  final GrowthDirection growthDirection;

  final ScrollDirection userScrollDirection;

  final double scrollOffset;

  final double precedingScrollExtent;

  final double overlap;

  final double remainingPaintExtent;

  final double crossAxisExtent;

  final AxisDirection crossAxisDirection;

  final double viewportMainAxisExtent;

  final double cacheOrigin;

  final double remainingCacheExtent;

  Axis get axis => axisDirectionToAxis(axisDirection);

  GrowthDirection get normalizedGrowthDirection {
    assert(axisDirection != null);
    switch (axisDirection) {
      case AxisDirection.down:
      case AxisDirection.right:
        return growthDirection;
      case AxisDirection.up:
      case AxisDirection.left:
        switch (growthDirection) {
          case GrowthDirection.forward:
            return GrowthDirection.reverse;
          case GrowthDirection.reverse:
            return GrowthDirection.forward;
        }
        return null;
    }
    return null;
  }

  @override
  bool get isTight => false;

  @override
  bool get isNormalized {
    return scrollOffset >= 0.0 &&
        crossAxisExtent >= 0.0 &&
        axisDirectionToAxis(axisDirection) !=
            axisDirectionToAxis(crossAxisDirection) &&
        viewportMainAxisExtent >= 0.0 &&
        remainingPaintExtent >= 0.0;
  }

  BoxConstraints asBoxConstraints({
    double minExtent = 0.0,
    double maxExtent = double.infinity,
    double crossAxisExtent,
  }) {
    crossAxisExtent ??= this.crossAxisExtent;
    switch (axis) {
      case Axis.horizontal:
        return BoxConstraints(
          minHeight: crossAxisExtent,
          maxHeight: crossAxisExtent,
          minWidth: minExtent,
          maxWidth: maxExtent,
        );
      case Axis.vertical:
        return BoxConstraints(
          minWidth: crossAxisExtent,
          maxWidth: crossAxisExtent,
          minHeight: minExtent,
          maxHeight: maxExtent,
        );
    }
    return null;
  }

  @override
  bool debugAssertIsValid({
    bool isAppliedConstraint = false,
    InformationCollector informationCollector,
  }) {
    assert(() {
      void verify(bool check, String message) {
        if (check) return;
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType is not valid: $message'),
          if (informationCollector != null) ...informationCollector(),
          DiagnosticsProperty<SliverConstraints>(
              'The offending constraints were', this,
              style: DiagnosticsTreeStyle.errorProperty)
        ]);
      }

      verify(axis != null, 'The "axis" is null.');
      verify(growthDirection != null, 'The "growthDirection" is null.');
      verify(scrollOffset != null, 'The "scrollOffset" is null.');
      verify(overlap != null, 'The "overlap" is null.');
      verify(
          remainingPaintExtent != null, 'The "remainingPaintExtent" is null.');
      verify(crossAxisExtent != null, 'The "crossAxisExtent" is null.');
      verify(viewportMainAxisExtent != null,
          'The "viewportMainAxisExtent" is null.');
      verify(scrollOffset >= 0.0, 'The "scrollOffset" is negative.');
      verify(crossAxisExtent >= 0.0, 'The "crossAxisExtent" is negative.');
      verify(crossAxisDirection != null, 'The "crossAxisDirection" is null.');
      verify(
          axisDirectionToAxis(axisDirection) !=
              axisDirectionToAxis(crossAxisDirection),
          'The "axisDirection" and the "crossAxisDirection" are along the same axis.');
      verify(viewportMainAxisExtent >= 0.0,
          'The "viewportMainAxisExtent" is negative.');
      verify(remainingPaintExtent >= 0.0,
          'The "remainingPaintExtent" is negative.');
      verify(remainingCacheExtent >= 0.0,
          'The "remainingCacheExtent" is negative.');
      verify(cacheOrigin <= 0.0, 'The "cacheOrigin" is positive.');
      verify(isNormalized, 'The constraints are not normalized.');
      return true;
    }());
    return true;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! SliverConstraints) return false;
    final SliverConstraints typedOther = other;
    assert(typedOther.debugAssertIsValid());
    return typedOther.axisDirection == axisDirection &&
        typedOther.growthDirection == growthDirection &&
        typedOther.scrollOffset == scrollOffset &&
        typedOther.overlap == overlap &&
        typedOther.remainingPaintExtent == remainingPaintExtent &&
        typedOther.crossAxisExtent == crossAxisExtent &&
        typedOther.crossAxisDirection == crossAxisDirection &&
        typedOther.viewportMainAxisExtent == viewportMainAxisExtent &&
        typedOther.remainingCacheExtent == remainingCacheExtent &&
        typedOther.cacheOrigin == cacheOrigin;
  }

  @override
  int get hashCode {
    return hashValues(
      axisDirection,
      growthDirection,
      scrollOffset,
      overlap,
      remainingPaintExtent,
      crossAxisExtent,
      crossAxisDirection,
      viewportMainAxisExtent,
      remainingCacheExtent,
      cacheOrigin,
    );
  }

  @override
  String toString() {
    return 'SliverConstraints('
            '$axisDirection, '
            '$growthDirection, '
            '$userScrollDirection, '
            'scrollOffset: ${scrollOffset.toStringAsFixed(1)}, '
            'remainingPaintExtent: ${remainingPaintExtent.toStringAsFixed(1)}, ' +
        (overlap != 0.0 ? 'overlap: ${overlap.toStringAsFixed(1)}, ' : '') +
        'crossAxisExtent: ${crossAxisExtent.toStringAsFixed(1)}, '
            'crossAxisDirection: $crossAxisDirection, '
            'viewportMainAxisExtent: ${viewportMainAxisExtent.toStringAsFixed(1)}, '
            'remainingCacheExtent: ${remainingCacheExtent.toStringAsFixed(1)} '
            'cacheOrigin: ${cacheOrigin.toStringAsFixed(1)} '
            ')';
  }
}

@immutable
class SliverGeometry extends Diagnosticable {
  const SliverGeometry({
    this.scrollExtent = 0.0,
    this.paintExtent = 0.0,
    this.paintOrigin = 0.0,
    double layoutExtent,
    this.maxPaintExtent = 0.0,
    this.maxScrollObstructionExtent = 0.0,
    double hitTestExtent,
    bool visible,
    this.hasVisualOverflow = false,
    this.scrollOffsetCorrection,
    double cacheExtent,
  })  : assert(scrollExtent != null),
        assert(paintExtent != null),
        assert(paintOrigin != null),
        assert(maxPaintExtent != null),
        assert(hasVisualOverflow != null),
        assert(scrollOffsetCorrection != 0.0),
        layoutExtent = layoutExtent ?? paintExtent,
        hitTestExtent = hitTestExtent ?? paintExtent,
        cacheExtent = cacheExtent ?? layoutExtent ?? paintExtent,
        visible = visible ?? paintExtent > 0.0;

  static const SliverGeometry zero = SliverGeometry();

  final double scrollExtent;

  final double paintOrigin;

  final double paintExtent;

  final double layoutExtent;

  final double maxPaintExtent;

  final double maxScrollObstructionExtent;

  final double hitTestExtent;

  final bool visible;

  final bool hasVisualOverflow;

  final double scrollOffsetCorrection;

  final double cacheExtent;

  bool debugAssertIsValid({
    InformationCollector informationCollector,
  }) {
    assert(() {
      void verify(bool check, String summary, {List<DiagnosticsNode> details}) {
        if (check) return;
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType is not valid: $summary'),
          ...?details,
          if (informationCollector != null) ...informationCollector(),
        ]);
      }

      verify(scrollExtent != null, 'The "scrollExtent" is null.');
      verify(scrollExtent >= 0.0, 'The "scrollExtent" is negative.');
      verify(paintExtent != null, 'The "paintExtent" is null.');
      verify(paintExtent >= 0.0, 'The "paintExtent" is negative.');
      verify(paintOrigin != null, 'The "paintOrigin" is null.');
      verify(layoutExtent != null, 'The "layoutExtent" is null.');
      verify(layoutExtent >= 0.0, 'The "layoutExtent" is negative.');
      verify(cacheExtent >= 0.0, 'The "cacheExtent" is negative.');
      if (layoutExtent > paintExtent) {
        verify(
          false,
          'The "layoutExtent" exceeds the "paintExtent".',
          details: _debugCompareFloats(
              'paintExtent', paintExtent, 'layoutExtent', layoutExtent),
        );
      }
      verify(maxPaintExtent != null, 'The "maxPaintExtent" is null.');

      if (paintExtent - maxPaintExtent > precisionErrorTolerance) {
        verify(false, 'The "maxPaintExtent" is less than the "paintExtent".',
            details: _debugCompareFloats(
                'maxPaintExtent', maxPaintExtent, 'paintExtent', paintExtent)
              ..add(ErrorDescription(
                  'By definition, a sliver can\'t paint more than the maximum that it can paint!')));
      }
      verify(hitTestExtent != null, 'The "hitTestExtent" is null.');
      verify(hitTestExtent >= 0.0, 'The "hitTestExtent" is negative.');
      verify(visible != null, 'The "visible" property is null.');
      verify(hasVisualOverflow != null, 'The "hasVisualOverflow" is null.');
      verify(scrollOffsetCorrection != 0.0,
          'The "scrollOffsetCorrection" is zero.');
      return true;
    }());
    return true;
  }

  @override
  String toStringShort() => '$runtimeType';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('scrollExtent', scrollExtent));
    if (paintExtent > 0.0) {
      properties.add(DoubleProperty('paintExtent', paintExtent,
          unit: visible ? null : ' but not painting'));
    } else if (paintExtent == 0.0) {
      if (visible) {
        properties.add(DoubleProperty('paintExtent', paintExtent,
            unit: visible ? null : ' but visible'));
      }
      properties
          .add(FlagProperty('visible', value: visible, ifFalse: 'hidden'));
    } else {
      properties.add(DoubleProperty('paintExtent', paintExtent, tooltip: '!'));
    }
    properties
        .add(DoubleProperty('paintOrigin', paintOrigin, defaultValue: 0.0));
    properties.add(DoubleProperty('layoutExtent', layoutExtent,
        defaultValue: paintExtent));
    properties.add(DoubleProperty('maxPaintExtent', maxPaintExtent));
    properties.add(DoubleProperty('hitTestExtent', hitTestExtent,
        defaultValue: paintExtent));
    properties.add(DiagnosticsProperty<bool>(
        'hasVisualOverflow', hasVisualOverflow,
        defaultValue: false));
    properties.add(DoubleProperty(
        'scrollOffsetCorrection', scrollOffsetCorrection,
        defaultValue: null));
    properties
        .add(DoubleProperty('cacheExtent', cacheExtent, defaultValue: 0.0));
  }
}

typedef SliverHitTest = bool Function(SliverHitTestResult result,
    {@required double mainAxisPosition, @required double crossAxisPosition});

class SliverHitTestResult extends HitTestResult {
  SliverHitTestResult() : super();

  SliverHitTestResult.wrap(HitTestResult result) : super.wrap(result);

  bool addWithAxisOffset({
    @required Offset paintOffset,
    @required double mainAxisOffset,
    @required double crossAxisOffset,
    @required double mainAxisPosition,
    @required double crossAxisPosition,
    @required SliverHitTest hitTest,
  }) {
    assert(mainAxisOffset != null);
    assert(crossAxisOffset != null);
    assert(mainAxisPosition != null);
    assert(crossAxisPosition != null);
    assert(hitTest != null);
    if (paintOffset != null) {
      pushTransform(
          Matrix4.translationValues(paintOffset.dx, paintOffset.dy, 0));
    }
    final bool isHit = hitTest(
      this,
      mainAxisPosition: mainAxisPosition - mainAxisOffset,
      crossAxisPosition: crossAxisPosition - crossAxisOffset,
    );
    if (paintOffset != null) {
      popTransform();
    }
    return isHit;
  }
}

class SliverHitTestEntry extends HitTestEntry {
  SliverHitTestEntry(
    RenderSliver target, {
    @required this.mainAxisPosition,
    @required this.crossAxisPosition,
  })  : assert(mainAxisPosition != null),
        assert(crossAxisPosition != null),
        super(target);

  @override
  RenderSliver get target => super.target;

  final double mainAxisPosition;

  final double crossAxisPosition;

  @override
  String toString() =>
      '${target.runtimeType}@(mainAxis: $mainAxisPosition, crossAxis: $crossAxisPosition)';
}

class SliverLogicalParentData extends ParentData {
  double layoutOffset = 0.0;

  @override
  String toString() => 'layoutOffset=${layoutOffset.toStringAsFixed(1)}';
}

class SliverLogicalContainerParentData extends SliverLogicalParentData
    with ContainerParentDataMixin<RenderSliver> {}

class SliverPhysicalParentData extends ParentData {
  Offset paintOffset = Offset.zero;

  void applyPaintTransform(Matrix4 transform) {
    transform.translate(paintOffset.dx, paintOffset.dy);
  }

  @override
  String toString() => 'paintOffset=$paintOffset';
}

class SliverPhysicalContainerParentData extends SliverPhysicalParentData
    with ContainerParentDataMixin<RenderSliver> {}

List<DiagnosticsNode> _debugCompareFloats(
    String labelA, double valueA, String labelB, double valueB) {
  final List<DiagnosticsNode> information = <DiagnosticsNode>[];
  if (valueA.toStringAsFixed(1) != valueB.toStringAsFixed(1)) {
    information
      ..add(ErrorDescription('The $labelA is ${valueA.toStringAsFixed(1)}, but '
          'the $labelB is ${valueB.toStringAsFixed(1)}.'));
  } else {
    information
      ..add(ErrorDescription(
          'The $labelA is $valueA, but the $labelB is $valueB.'))
      ..add(ErrorHint(
          'Maybe you have fallen prey to floating point rounding errors, and should explicitly '
          'apply the min() or max() functions, or the clamp() method, to the $labelB?'));
  }
  return information;
}

abstract class RenderSliver extends RenderObject {
  @override
  SliverConstraints get constraints => super.constraints;

  SliverGeometry get geometry => _geometry;
  SliverGeometry _geometry;
  set geometry(SliverGeometry value) {
    assert(!(debugDoingThisResize && debugDoingThisLayout));
    assert(sizedByParent || !debugDoingThisResize);
    assert(() {
      if ((sizedByParent && debugDoingThisResize) ||
          (!sizedByParent && debugDoingThisLayout)) return true;
      assert(!debugDoingThisResize);
      DiagnosticsNode contract, violation, hint;
      if (debugDoingThisLayout) {
        assert(sizedByParent);
        violation = ErrorDescription(
            'It appears that the geometry setter was called from performLayout().');
      } else {
        violation = ErrorDescription(
            'The geometry setter was called from outside layout (neither performResize() nor performLayout() were being run for this object).');
        if (owner != null && owner.debugDoingLayout)
          hint = ErrorDescription(
              'Only the object itself can set its geometry. It is a contract violation for other objects to set it.');
      }
      if (sizedByParent)
        contract = ErrorDescription(
            'Because this RenderSliver has sizedByParent set to true, it must set its geometry in performResize().');
      else
        contract = ErrorDescription(
            'Because this RenderSliver has sizedByParent set to false, it must set its geometry in performLayout().');

      final List<DiagnosticsNode> information = <DiagnosticsNode>[
        ErrorSummary('RenderSliver geometry setter called incorrectly.'),
        violation
      ];
      if (hint != null) information.add(hint);
      information.add(contract);
      information.add(describeForError('The RenderSliver in question is'));

      throw FlutterError.fromParts(information);
    }());
    _geometry = value;
  }

  @override
  Rect get semanticBounds => paintBounds;

  @override
  Rect get paintBounds {
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        return Rect.fromLTWH(
          0.0,
          0.0,
          geometry.paintExtent,
          constraints.crossAxisExtent,
        );
      case Axis.vertical:
        return Rect.fromLTWH(
          0.0,
          0.0,
          constraints.crossAxisExtent,
          geometry.paintExtent,
        );
    }
    return null;
  }

  @override
  void debugResetSize() {}

  @override
  void debugAssertDoesMeetConstraints() {
    assert(geometry.debugAssertIsValid(informationCollector: () sync* {
      yield describeForError(
          'The RenderSliver that returned the offending geometry was');
    }));
    assert(() {
      if (geometry.paintExtent > constraints.remainingPaintExtent) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'SliverGeometry has a paintOffset that exceeds the remainingPaintExtent from the constraints.'),
          describeForError(
              'The render object whose geometry violates the constraints is the following'),
          ..._debugCompareFloats(
            'remainingPaintExtent',
            constraints.remainingPaintExtent,
            'paintExtent',
            geometry.paintExtent,
          ),
          ErrorDescription(
            'The paintExtent must cause the child sliver to paint within the viewport, and so '
            'cannot exceed the remainingPaintExtent.',
          ),
        ]);
      }
      return true;
    }());
  }

  @override
  void performResize() {
    assert(false);
  }

  double get centerOffsetAdjustment => 0.0;

  bool hitTest(SliverHitTestResult result,
      {@required double mainAxisPosition, @required double crossAxisPosition}) {
    if (mainAxisPosition >= 0.0 &&
        mainAxisPosition < geometry.hitTestExtent &&
        crossAxisPosition >= 0.0 &&
        crossAxisPosition < constraints.crossAxisExtent) {
      if (hitTestChildren(result,
              mainAxisPosition: mainAxisPosition,
              crossAxisPosition: crossAxisPosition) ||
          hitTestSelf(
              mainAxisPosition: mainAxisPosition,
              crossAxisPosition: crossAxisPosition)) {
        result.add(SliverHitTestEntry(
          this,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        ));
        return true;
      }
    }
    return false;
  }

  @protected
  bool hitTestSelf(
          {@required double mainAxisPosition,
          @required double crossAxisPosition}) =>
      false;

  @protected
  bool hitTestChildren(SliverHitTestResult result,
          {@required double mainAxisPosition,
          @required double crossAxisPosition}) =>
      false;

  double calculatePaintOffset(SliverConstraints constraints,
      {@required double from, @required double to}) {
    assert(from <= to);
    final double a = constraints.scrollOffset;
    final double b =
        constraints.scrollOffset + constraints.remainingPaintExtent;

    return (to.clamp(a, b) - from.clamp(a, b))
        .clamp(0.0, constraints.remainingPaintExtent);
  }

  double calculateCacheOffset(SliverConstraints constraints,
      {@required double from, @required double to}) {
    assert(from <= to);
    final double a = constraints.scrollOffset + constraints.cacheOrigin;
    final double b =
        constraints.scrollOffset + constraints.remainingCacheExtent;

    return (to.clamp(a, b) - from.clamp(a, b))
        .clamp(0.0, constraints.remainingCacheExtent);
  }

  @protected
  double childMainAxisPosition(covariant RenderObject child) {
    assert(() {
      throw FlutterError('$runtimeType does not implement childPosition.');
    }());
    return 0.0;
  }

  @protected
  double childCrossAxisPosition(covariant RenderObject child) => 0.0;

  double childScrollOffset(covariant RenderObject child) {
    assert(child.parent == this);
    return 0.0;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(() {
      throw FlutterError(
          '$runtimeType does not implement applyPaintTransform.');
    }());
  }

  @protected
  Size getAbsoluteSizeRelativeToOrigin() {
    assert(geometry != null);
    assert(!debugNeedsLayout);
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        return Size(constraints.crossAxisExtent, -geometry.paintExtent);
      case AxisDirection.right:
        return Size(geometry.paintExtent, constraints.crossAxisExtent);
      case AxisDirection.down:
        return Size(constraints.crossAxisExtent, geometry.paintExtent);
      case AxisDirection.left:
        return Size(-geometry.paintExtent, constraints.crossAxisExtent);
    }
    return null;
  }

  void _debugDrawArrow(Canvas canvas, Paint paint, Offset p0, Offset p1,
      GrowthDirection direction) {
    assert(() {
      if (p0 == p1) return true;
      assert(p0.dx == p1.dx || p0.dy == p1.dy);
      final double d = (p1 - p0).distance * 0.2;
      Offset temp;
      double dx1, dx2, dy1, dy2;
      switch (direction) {
        case GrowthDirection.forward:
          dx1 = dx2 = dy1 = dy2 = d;
          break;
        case GrowthDirection.reverse:
          temp = p0;
          p0 = p1;
          p1 = temp;
          dx1 = dx2 = dy1 = dy2 = -d;
          break;
      }
      if (p0.dx == p1.dx) {
        dx2 = -dx2;
      } else {
        dy2 = -dy2;
      }
      canvas.drawPath(
        Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(p1.dx, p1.dy)
          ..moveTo(p1.dx - dx1, p1.dy - dy1)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p1.dx - dx2, p1.dy - dy2),
        paint,
      );
      return true;
    }());
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(() {
      if (debugPaintSizeEnabled) {
        final double strokeWidth = math.min(4.0, geometry.paintExtent / 30.0);
        final Paint paint = Paint()
          ..color = const Color(0xFF33CC33)
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..maskFilter = MaskFilter.blur(BlurStyle.solid, strokeWidth);
        final double arrowExtent = geometry.paintExtent;
        final double padding = math.max(2.0, strokeWidth);
        final Canvas canvas = context.canvas;
        canvas.drawCircle(
          offset.translate(padding, padding),
          padding * 0.5,
          paint,
        );
        switch (constraints.axis) {
          case Axis.vertical:
            canvas.drawLine(
              offset,
              offset.translate(constraints.crossAxisExtent, 0.0),
              paint,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(
                  constraints.crossAxisExtent * 1.0 / 4.0, padding),
              offset.translate(constraints.crossAxisExtent * 1.0 / 4.0,
                  arrowExtent - padding),
              constraints.normalizedGrowthDirection,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(
                  constraints.crossAxisExtent * 3.0 / 4.0, padding),
              offset.translate(constraints.crossAxisExtent * 3.0 / 4.0,
                  arrowExtent - padding),
              constraints.normalizedGrowthDirection,
            );
            break;
          case Axis.horizontal:
            canvas.drawLine(
              offset,
              offset.translate(0.0, constraints.crossAxisExtent),
              paint,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(
                  padding, constraints.crossAxisExtent * 1.0 / 4.0),
              offset.translate(arrowExtent - padding,
                  constraints.crossAxisExtent * 1.0 / 4.0),
              constraints.normalizedGrowthDirection,
            );
            _debugDrawArrow(
              canvas,
              paint,
              offset.translate(
                  padding, constraints.crossAxisExtent * 3.0 / 4.0),
              offset.translate(arrowExtent - padding,
                  constraints.crossAxisExtent * 3.0 / 4.0),
              constraints.normalizedGrowthDirection,
            );
            break;
        }
      }
      return true;
    }());
  }

  @override
  void handleEvent(PointerEvent event, SliverHitTestEntry entry) {}

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SliverGeometry>('geometry', geometry));
  }
}

abstract class RenderSliverHelpers implements RenderSliver {
  bool _getRightWayUp(SliverConstraints constraints) {
    assert(constraints != null);
    assert(constraints.axisDirection != null);
    bool rightWayUp;
    switch (constraints.axisDirection) {
      case AxisDirection.up:
      case AxisDirection.left:
        rightWayUp = false;
        break;
      case AxisDirection.down:
      case AxisDirection.right:
        rightWayUp = true;
        break;
    }
    assert(constraints.growthDirection != null);
    switch (constraints.growthDirection) {
      case GrowthDirection.forward:
        break;
      case GrowthDirection.reverse:
        rightWayUp = !rightWayUp;
        break;
    }
    assert(rightWayUp != null);
    return rightWayUp;
  }

  @protected
  bool hitTestBoxChild(BoxHitTestResult result, RenderBox child,
      {@required double mainAxisPosition, @required double crossAxisPosition}) {
    final bool rightWayUp = _getRightWayUp(constraints);
    double delta = childMainAxisPosition(child);
    final double crossAxisDelta = childCrossAxisPosition(child);
    double absolutePosition = mainAxisPosition - delta;
    final double absoluteCrossAxisPosition = crossAxisPosition - crossAxisDelta;
    Offset paintOffset, transformedPosition;
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        if (!rightWayUp) {
          absolutePosition = child.size.width - absolutePosition;
          delta = geometry.paintExtent - child.size.width - delta;
        }
        paintOffset = Offset(delta, crossAxisDelta);
        transformedPosition =
            Offset(absolutePosition, absoluteCrossAxisPosition);
        break;
      case Axis.vertical:
        if (!rightWayUp) {
          absolutePosition = child.size.height - absolutePosition;
          delta = geometry.paintExtent - child.size.height - delta;
        }
        paintOffset = Offset(crossAxisDelta, delta);
        transformedPosition =
            Offset(absoluteCrossAxisPosition, absolutePosition);
        break;
    }
    assert(paintOffset != null);
    assert(transformedPosition != null);
    return result.addWithPaintOffset(
      offset: paintOffset,
      position: null,
      hitTest: (BoxHitTestResult result, Offset _) {
        return child.hitTest(result, position: transformedPosition);
      },
    );
  }

  @protected
  void applyPaintTransformForBoxChild(RenderBox child, Matrix4 transform) {
    final bool rightWayUp = _getRightWayUp(constraints);
    double delta = childMainAxisPosition(child);
    final double crossAxisDelta = childCrossAxisPosition(child);
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        if (!rightWayUp)
          delta = geometry.paintExtent - child.size.width - delta;
        transform.translate(delta, crossAxisDelta);
        break;
      case Axis.vertical:
        if (!rightWayUp)
          delta = geometry.paintExtent - child.size.height - delta;
        transform.translate(crossAxisDelta, delta);
        break;
    }
  }
}

abstract class RenderSliverSingleBoxAdapter extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  RenderSliverSingleBoxAdapter({
    RenderBox child,
  }) {
    this.child = child;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData)
      child.parentData = SliverPhysicalParentData();
  }

  @protected
  void setChildParentData(RenderObject child, SliverConstraints constraints,
      SliverGeometry geometry) {
    final SliverPhysicalParentData childParentData = child.parentData;
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        childParentData.paintOffset = Offset(
            0.0,
            -(geometry.scrollExtent -
                (geometry.paintExtent + constraints.scrollOffset)));
        break;
      case AxisDirection.right:
        childParentData.paintOffset = Offset(-constraints.scrollOffset, 0.0);
        break;
      case AxisDirection.down:
        childParentData.paintOffset = Offset(0.0, -constraints.scrollOffset);
        break;
      case AxisDirection.left:
        childParentData.paintOffset = Offset(
            -(geometry.scrollExtent -
                (geometry.paintExtent + constraints.scrollOffset)),
            0.0);
        break;
    }
    assert(childParentData.paintOffset != null);
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {@required double mainAxisPosition, @required double crossAxisPosition}) {
    assert(geometry.hitTestExtent > 0.0);
    if (child != null)
      return hitTestBoxChild(BoxHitTestResult.wrap(result), child,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition);
    return false;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return -constraints.scrollOffset;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child == this.child);
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry.visible) {
      final SliverPhysicalParentData childParentData = child.parentData;
      context.paintChild(child, offset + childParentData.paintOffset);
    }
  }
}

class RenderSliverToBoxAdapter extends RenderSliverSingleBoxAdapter {
  RenderSliverToBoxAdapter({
    RenderBox child,
  }) : super(child: child);

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child.size.width;
        break;
      case Axis.vertical:
        childExtent = child.size.height;
        break;
    }
    assert(childExtent != null);
    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    final double cacheExtent =
        calculateCacheOffset(constraints, from: 0.0, to: childExtent);

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );
    setChildParentData(child, constraints, geometry);
  }
}

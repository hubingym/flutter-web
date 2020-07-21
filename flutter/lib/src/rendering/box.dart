import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/ui.dart' as ui show lerpDouble;
import 'package:flutter_web/src/util.dart';

import 'debug.dart';
import 'object.dart';

class _DebugSize extends Size {
  _DebugSize(Size source, this._owner, this._canBeUsedByParent)
      : super.copy(source);
  final RenderBox _owner;
  final bool _canBeUsedByParent;
}

class BoxConstraints extends Constraints {
  const BoxConstraints({
    this.minWidth = 0.0,
    this.maxWidth = double.infinity,
    this.minHeight = 0.0,
    this.maxHeight = double.infinity,
  });

  BoxConstraints.tight(Size size)
      : minWidth = size.width,
        maxWidth = size.width,
        minHeight = size.height,
        maxHeight = size.height;

  const BoxConstraints.tightFor({
    double width,
    double height,
  })  : minWidth = width ?? 0.0,
        maxWidth = width ?? double.infinity,
        minHeight = height ?? 0.0,
        maxHeight = height ?? double.infinity;

  const BoxConstraints.tightForFinite({
    double width = double.infinity,
    double height = double.infinity,
  })  : minWidth = width != double.infinity ? width : 0.0,
        maxWidth = width != double.infinity ? width : double.infinity,
        minHeight = height != double.infinity ? height : 0.0,
        maxHeight = height != double.infinity ? height : double.infinity;

  BoxConstraints.loose(Size size)
      : minWidth = 0.0,
        maxWidth = size.width,
        minHeight = 0.0,
        maxHeight = size.height;

  const BoxConstraints.expand({
    double width,
    double height,
  })  : minWidth = width ?? double.infinity,
        maxWidth = width ?? double.infinity,
        minHeight = height ?? double.infinity,
        maxHeight = height ?? double.infinity;

  final double minWidth;

  final double maxWidth;

  final double minHeight;

  final double maxHeight;

  BoxConstraints copyWith({
    double minWidth,
    double maxWidth,
    double minHeight,
    double maxHeight,
  }) {
    return BoxConstraints(
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }

  BoxConstraints deflate(EdgeInsets edges) {
    assert(edges != null);
    assert(debugAssertIsValid());
    final double horizontal = edges.horizontal;
    final double vertical = edges.vertical;
    final double deflatedMinWidth = math.max(0.0, minWidth - horizontal);
    final double deflatedMinHeight = math.max(0.0, minHeight - vertical);
    return BoxConstraints(
      minWidth: deflatedMinWidth,
      maxWidth: math.max(deflatedMinWidth, maxWidth - horizontal),
      minHeight: deflatedMinHeight,
      maxHeight: math.max(deflatedMinHeight, maxHeight - vertical),
    );
  }

  BoxConstraints loosen() {
    assert(debugAssertIsValid());
    return BoxConstraints(
      minWidth: 0.0,
      maxWidth: maxWidth,
      minHeight: 0.0,
      maxHeight: maxHeight,
    );
  }

  BoxConstraints enforce(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: minWidth.clamp(constraints.minWidth, constraints.maxWidth),
      maxWidth: maxWidth.clamp(constraints.minWidth, constraints.maxWidth),
      minHeight: minHeight.clamp(constraints.minHeight, constraints.maxHeight),
      maxHeight: maxHeight.clamp(constraints.minHeight, constraints.maxHeight),
    );
  }

  BoxConstraints tighten({double width, double height}) {
    return BoxConstraints(
        minWidth: width == null ? minWidth : width.clamp(minWidth, maxWidth),
        maxWidth: width == null ? maxWidth : width.clamp(minWidth, maxWidth),
        minHeight:
            height == null ? minHeight : height.clamp(minHeight, maxHeight),
        maxHeight:
            height == null ? maxHeight : height.clamp(minHeight, maxHeight));
  }

  BoxConstraints get flipped {
    return BoxConstraints(
      minWidth: minHeight,
      maxWidth: maxHeight,
      minHeight: minWidth,
      maxHeight: maxWidth,
    );
  }

  BoxConstraints widthConstraints() =>
      BoxConstraints(minWidth: minWidth, maxWidth: maxWidth);

  BoxConstraints heightConstraints() =>
      BoxConstraints(minHeight: minHeight, maxHeight: maxHeight);

  double constrainWidth([double width = double.infinity]) {
    assert(debugAssertIsValid());
    return width.clamp(minWidth, maxWidth);
  }

  double constrainHeight([double height = double.infinity]) {
    assert(debugAssertIsValid());
    return height.clamp(minHeight, maxHeight);
  }

  Size _debugPropagateDebugSize(Size size, Size result) {
    assert(() {
      if (size is _DebugSize)
        result = _DebugSize(result, size._owner, size._canBeUsedByParent);
      return true;
    }());
    return result;
  }

  Size constrain(Size size) {
    Size result =
        Size(constrainWidth(size.width), constrainHeight(size.height));
    assert(() {
      result = _debugPropagateDebugSize(size, result);
      return true;
    }());
    return result;
  }

  Size constrainDimensions(double width, double height) {
    return Size(constrainWidth(width), constrainHeight(height));
  }

  Size constrainSizeAndAttemptToPreserveAspectRatio(Size size) {
    if (isTight) {
      Size result = smallest;
      assert(() {
        result = _debugPropagateDebugSize(size, result);
        return true;
      }());
      return result;
    }

    double width = size.width;
    double height = size.height;
    assert(width > 0.0);
    assert(height > 0.0);
    final double aspectRatio = width / height;

    if (width > maxWidth) {
      width = maxWidth;
      height = width / aspectRatio;
    }

    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }

    if (width < minWidth) {
      width = minWidth;
      height = width / aspectRatio;
    }

    if (height < minHeight) {
      height = minHeight;
      width = height * aspectRatio;
    }

    Size result = Size(constrainWidth(width), constrainHeight(height));
    assert(() {
      result = _debugPropagateDebugSize(size, result);
      return true;
    }());
    return result;
  }

  Size get biggest => Size(constrainWidth(), constrainHeight());

  Size get smallest => Size(constrainWidth(0.0), constrainHeight(0.0));

  bool get hasTightWidth => minWidth >= maxWidth;

  bool get hasTightHeight => minHeight >= maxHeight;

  @override
  bool get isTight => hasTightWidth && hasTightHeight;

  bool get hasBoundedWidth => maxWidth < double.infinity;

  bool get hasBoundedHeight => maxHeight < double.infinity;

  bool get hasInfiniteWidth => minWidth >= double.infinity;

  bool get hasInfiniteHeight => minHeight >= double.infinity;

  bool isSatisfiedBy(Size size) {
    assert(debugAssertIsValid());
    return (minWidth <= size.width) &&
        (size.width <= maxWidth) &&
        (minHeight <= size.height) &&
        (size.height <= maxHeight);
  }

  BoxConstraints operator *(double factor) {
    return BoxConstraints(
      minWidth: minWidth * factor,
      maxWidth: maxWidth * factor,
      minHeight: minHeight * factor,
      maxHeight: maxHeight * factor,
    );
  }

  BoxConstraints operator /(double factor) {
    return BoxConstraints(
      minWidth: minWidth / factor,
      maxWidth: maxWidth / factor,
      minHeight: minHeight / factor,
      maxHeight: maxHeight / factor,
    );
  }

  BoxConstraints operator ~/(double factor) {
    return BoxConstraints(
      minWidth: (minWidth ~/ factor).toDouble(),
      maxWidth: (maxWidth ~/ factor).toDouble(),
      minHeight: (minHeight ~/ factor).toDouble(),
      maxHeight: (maxHeight ~/ factor).toDouble(),
    );
  }

  BoxConstraints operator %(double value) {
    return BoxConstraints(
      minWidth: minWidth % value,
      maxWidth: maxWidth % value,
      minHeight: minHeight % value,
      maxHeight: maxHeight % value,
    );
  }

  static BoxConstraints lerp(BoxConstraints a, BoxConstraints b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b * t;
    if (b == null) return a * (1.0 - t);
    assert(a.debugAssertIsValid());
    assert(b.debugAssertIsValid());
    assert(
        (a.minWidth.isFinite && b.minWidth.isFinite) ||
            (a.minWidth == double.infinity && b.minWidth == double.infinity),
        'Cannot interpolate between finite constraints and unbounded constraints.');
    assert(
        (a.maxWidth.isFinite && b.maxWidth.isFinite) ||
            (a.maxWidth == double.infinity && b.maxWidth == double.infinity),
        'Cannot interpolate between finite constraints and unbounded constraints.');
    assert(
        (a.minHeight.isFinite && b.minHeight.isFinite) ||
            (a.minHeight == double.infinity && b.minHeight == double.infinity),
        'Cannot interpolate between finite constraints and unbounded constraints.');
    assert(
        (a.maxHeight.isFinite && b.maxHeight.isFinite) ||
            (a.maxHeight == double.infinity && b.maxHeight == double.infinity),
        'Cannot interpolate between finite constraints and unbounded constraints.');
    return BoxConstraints(
      minWidth: a.minWidth.isFinite
          ? ui.lerpDouble(a.minWidth, b.minWidth, t)
          : double.infinity,
      maxWidth: a.maxWidth.isFinite
          ? ui.lerpDouble(a.maxWidth, b.maxWidth, t)
          : double.infinity,
      minHeight: a.minHeight.isFinite
          ? ui.lerpDouble(a.minHeight, b.minHeight, t)
          : double.infinity,
      maxHeight: a.maxHeight.isFinite
          ? ui.lerpDouble(a.maxHeight, b.maxHeight, t)
          : double.infinity,
    );
  }

  @override
  bool get isNormalized {
    return minWidth >= 0.0 &&
        minWidth <= maxWidth &&
        minHeight >= 0.0 &&
        minHeight <= maxHeight;
  }

  @override
  bool debugAssertIsValid({
    bool isAppliedConstraint = false,
    InformationCollector informationCollector,
  }) {
    assert(() {
      void throwError(DiagnosticsNode message) {
        final List<DiagnosticsNode> information = <DiagnosticsNode>[message];
        if (informationCollector != null) {
          information.addAll(informationCollector());
        }

        information.add(DiagnosticsProperty<BoxConstraints>(
            'The offending constraints were', this,
            style: DiagnosticsTreeStyle.errorProperty));
        throw FlutterError.fromParts(information);
      }

      if (minWidth.isNaN ||
          maxWidth.isNaN ||
          minHeight.isNaN ||
          maxHeight.isNaN) {
        final List<String> affectedFieldsList = <String>[];
        if (minWidth.isNaN) affectedFieldsList.add('minWidth');
        if (maxWidth.isNaN) affectedFieldsList.add('maxWidth');
        if (minHeight.isNaN) affectedFieldsList.add('minHeight');
        if (maxHeight.isNaN) affectedFieldsList.add('maxHeight');
        assert(affectedFieldsList.isNotEmpty);
        if (affectedFieldsList.length > 1)
          affectedFieldsList.add('and ${affectedFieldsList.removeLast()}');
        String whichFields = '';
        if (affectedFieldsList.length > 2) {
          whichFields = affectedFieldsList.join(', ');
        } else if (affectedFieldsList.length == 2) {
          whichFields = affectedFieldsList.join(' ');
        } else {
          whichFields = affectedFieldsList.single;
        }
        throwError(ErrorSummary(
            'BoxConstraints has ${affectedFieldsList.length == 1 ? 'a NaN value' : 'NaN values'} in $whichFields.'));
      }
      if (minWidth < 0.0 && minHeight < 0.0)
        throwError(ErrorSummary(
            'BoxConstraints has both a negative minimum width and a negative minimum height.'));
      if (minWidth < 0.0)
        throwError(
            ErrorSummary('BoxConstraints has a negative minimum width.'));
      if (minHeight < 0.0)
        throwError(
            ErrorSummary('BoxConstraints has a negative minimum height.'));
      if (maxWidth < minWidth && maxHeight < minHeight)
        throwError(ErrorSummary(
            'BoxConstraints has both width and height constraints non-normalized.'));
      if (maxWidth < minWidth)
        throwError(ErrorSummary(
            'BoxConstraints has non-normalized width constraints.'));
      if (maxHeight < minHeight)
        throwError(ErrorSummary(
            'BoxConstraints has non-normalized height constraints.'));
      if (isAppliedConstraint) {
        if (minWidth.isInfinite && minHeight.isInfinite)
          throwError(ErrorSummary(
              'BoxConstraints forces an infinite width and infinite height.'));
        if (minWidth.isInfinite)
          throwError(ErrorSummary('BoxConstraints forces an infinite width.'));
        if (minHeight.isInfinite)
          throwError(ErrorSummary('BoxConstraints forces an infinite height.'));
      }
      assert(isNormalized);
      return true;
    }());
    return isNormalized;
  }

  BoxConstraints normalize() {
    if (isNormalized) return this;
    final double minWidth = this.minWidth >= 0.0 ? this.minWidth : 0.0;
    final double minHeight = this.minHeight >= 0.0 ? this.minHeight : 0.0;
    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: minWidth > maxWidth ? minWidth : maxWidth,
      minHeight: minHeight,
      maxHeight: minHeight > maxHeight ? minHeight : maxHeight,
    );
  }

  @override
  bool operator ==(dynamic other) {
    assert(debugAssertIsValid());
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final BoxConstraints typedOther = other;
    assert(typedOther.debugAssertIsValid());
    return minWidth == typedOther.minWidth &&
        maxWidth == typedOther.maxWidth &&
        minHeight == typedOther.minHeight &&
        maxHeight == typedOther.maxHeight;
  }

  @override
  int get hashCode {
    assert(debugAssertIsValid());
    return hashValues(minWidth, maxWidth, minHeight, maxHeight);
  }

  @override
  String toString() {
    if (assertionsEnabled) {
      final String annotation = isNormalized ? '' : '; NOT NORMALIZED';
      if (minWidth == double.infinity && minHeight == double.infinity)
        return 'BoxConstraints(biggest$annotation)';
      if (minWidth == 0 &&
          maxWidth == double.infinity &&
          minHeight == 0 &&
          maxHeight == double.infinity)
        return 'BoxConstraints(unconstrained$annotation)';
      String describe(double min, double max, String dim) {
        if (min == max) return '$dim=${min.toStringAsFixed(1)}';
        return '${min.toStringAsFixed(1)}<=$dim<=${max.toStringAsFixed(1)}';
      }

      final String width = describe(minWidth, maxWidth, 'w');
      final String height = describe(minHeight, maxHeight, 'h');
      return 'BoxConstraints($width, $height$annotation)';
    }
    return super.toString();
  }
}

typedef BoxHitTest = bool Function(BoxHitTestResult result, Offset position);

class BoxHitTestResult extends HitTestResult {
  BoxHitTestResult() : super();

  BoxHitTestResult.wrap(HitTestResult result) : super.wrap(result);

  bool addWithPaintTransform({
    @required Matrix4 transform,
    @required Offset position,
    @required BoxHitTest hitTest,
  }) {
    assert(hitTest != null);
    if (transform != null) {
      transform =
          Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(transform));
      if (transform == null) {
        return false;
      }
    }
    return addWithRawTransform(
      transform: transform,
      position: position,
      hitTest: hitTest,
    );
  }

  bool addWithPaintOffset({
    @required Offset offset,
    @required Offset position,
    @required BoxHitTest hitTest,
  }) {
    assert(hitTest != null);
    return addWithRawTransform(
      transform: offset != null
          ? Matrix4.translationValues(-offset.dx, -offset.dy, 0.0)
          : null,
      position: position,
      hitTest: hitTest,
    );
  }

  bool addWithRawTransform({
    @required Matrix4 transform,
    @required Offset position,
    @required BoxHitTest hitTest,
  }) {
    assert(hitTest != null);
    final Offset transformedPosition = position == null || transform == null
        ? position
        : MatrixUtils.transformPoint(transform, position);
    if (transform != null) {
      pushTransform(transform);
    }
    final bool isHit = hitTest(this, transformedPosition);
    if (transform != null) {
      popTransform();
    }
    return isHit;
  }
}

class BoxHitTestEntry extends HitTestEntry {
  BoxHitTestEntry(RenderBox target, this.localPosition)
      : assert(localPosition != null),
        super(target);

  @override
  RenderBox get target => super.target;

  final Offset localPosition;

  @override
  String toString() => '${describeIdentity(target)}@$localPosition';
}

class BoxParentData extends ParentData {
  Offset offset = Offset.zero;

  @override
  String toString() => 'offset=$offset';
}

abstract class ContainerBoxParentData<ChildType extends RenderObject>
    extends BoxParentData with ContainerParentDataMixin<ChildType> {}

enum _IntrinsicDimension { minWidth, maxWidth, minHeight, maxHeight }

@immutable
class _IntrinsicDimensionsCacheEntry {
  const _IntrinsicDimensionsCacheEntry(this.dimension, this.argument);

  final _IntrinsicDimension dimension;
  final double argument;

  @override
  bool operator ==(dynamic other) {
    if (other is! _IntrinsicDimensionsCacheEntry) return false;
    final _IntrinsicDimensionsCacheEntry typedOther = other;
    return dimension == typedOther.dimension && argument == typedOther.argument;
  }

  @override
  int get hashCode => hashValues(dimension, argument);
}

abstract class RenderBox extends RenderObject {
  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  Map<_IntrinsicDimensionsCacheEntry, double> _cachedIntrinsicDimensions;

  double _computeIntrinsicDimension(_IntrinsicDimension dimension,
      double argument, double computer(double argument)) {
    assert(RenderObject.debugCheckingIntrinsics || !debugDoingThisResize);
    bool shouldCache = true;
    assert(() {
      if (RenderObject.debugCheckingIntrinsics) shouldCache = false;
      return true;
    }());
    if (shouldCache) {
      _cachedIntrinsicDimensions ??= <_IntrinsicDimensionsCacheEntry, double>{};
      return _cachedIntrinsicDimensions.putIfAbsent(
        _IntrinsicDimensionsCacheEntry(dimension, argument),
        () => computer(argument),
      );
    }
    return computer(argument);
  }

  @mustCallSuper
  double getMinIntrinsicWidth(double height) {
    assert(() {
      if (height == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('The height argument to getMinIntrinsicWidth was null.'),
          ErrorDescription(
              'The argument to getMinIntrinsicWidth must not be negative or null.'),
          ErrorHint(
              'If you do not have a specific height in mind, then pass double.infinity instead.')
        ]);
      }
      if (height < 0.0) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'The height argument to getMinIntrinsicWidth was negative.'),
          ErrorDescription(
              'The argument to getMinIntrinsicWidth must not be negative or null.'),
          ErrorHint(
              'If you perform computations on another height before passing it to '
              'getMinIntrinsicWidth, consider using math.max() or double.clamp() '
              'to force the value into the valid range.'),
        ]);
      }
      return true;
    }());
    return _computeIntrinsicDimension(
        _IntrinsicDimension.minWidth, height, computeMinIntrinsicWidth);
  }

  @protected
  double computeMinIntrinsicWidth(double height) {
    return 0.0;
  }

  @mustCallSuper
  double getMaxIntrinsicWidth(double height) {
    assert(() {
      if (height == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('The height argument to getMaxIntrinsicWidth was null.'),
          ErrorDescription(
              'The argument to getMaxIntrinsicWidth must not be negative or null.'),
          ErrorHint(
              'If you do not have a specific height in mind, then pass double.infinity instead.')
        ]);
      }
      if (height < 0.0) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'The height argument to getMaxIntrinsicWidth was negative.'),
          ErrorDescription(
              'The argument to getMaxIntrinsicWidth must not be negative or null.'),
          ErrorHint(
              'If you perform computations on another height before passing it to '
              'getMaxIntrinsicWidth, consider using math.max() or double.clamp() '
              'to force the value into the valid range.')
        ]);
      }
      return true;
    }());
    return _computeIntrinsicDimension(
        _IntrinsicDimension.maxWidth, height, computeMaxIntrinsicWidth);
  }

  @protected
  double computeMaxIntrinsicWidth(double height) {
    return 0.0;
  }

  @mustCallSuper
  double getMinIntrinsicHeight(double width) {
    assert(() {
      if (width == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('The width argument to getMinIntrinsicHeight was null.'),
          ErrorDescription(
              'The argument to getMinIntrinsicHeight must not be negative or null.'),
          ErrorHint(
              'If you do not have a specific width in mind, then pass double.infinity instead.')
        ]);
      }
      if (width < 0.0) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'The width argument to getMinIntrinsicHeight was negative.'),
          ErrorDescription(
              'The argument to getMinIntrinsicHeight must not be negative or null.'),
          ErrorHint(
              'If you perform computations on another width before passing it to '
              'getMinIntrinsicHeight, consider using math.max() or double.clamp() '
              'to force the value into the valid range.')
        ]);
      }
      return true;
    }());
    return _computeIntrinsicDimension(
        _IntrinsicDimension.minHeight, width, computeMinIntrinsicHeight);
  }

  @protected
  double computeMinIntrinsicHeight(double width) {
    return 0.0;
  }

  @mustCallSuper
  double getMaxIntrinsicHeight(double width) {
    assert(() {
      if (width == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('The width argument to getMaxIntrinsicHeight was null.'),
          ErrorDescription(
              'The argument to getMaxIntrinsicHeight must not be negative or null.'),
          ErrorHint(
              'If you do not have a specific width in mind, then pass double.infinity instead.')
        ]);
      }
      if (width < 0.0) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'The width argument to getMaxIntrinsicHeight was negative.'),
          ErrorDescription(
              'The argument to getMaxIntrinsicHeight must not be negative or null.'),
          ErrorHint(
              'If you perform computations on another width before passing it to '
              'getMaxIntrinsicHeight, consider using math.max() or double.clamp() '
              'to force the value into the valid range.')
        ]);
      }
      return true;
    }());
    return _computeIntrinsicDimension(
        _IntrinsicDimension.maxHeight, width, computeMaxIntrinsicHeight);
  }

  @protected
  double computeMaxIntrinsicHeight(double width) {
    return 0.0;
  }

  bool get hasSize => _size != null;

  Size get size {
    assert(hasSize, 'RenderBox was not laid out: ${toString()}');
    assert(() {
      if (_size is _DebugSize) {
        final _DebugSize _size = this._size;
        assert(_size._owner == this);
        if (RenderObject.debugActiveLayout != null) {
          assert(debugDoingThisResize ||
              debugDoingThisLayout ||
              (RenderObject.debugActiveLayout == parent &&
                  _size._canBeUsedByParent));
        }
        assert(_size == this._size);
      }
      return true;
    }());
    return _size;
  }

  Size _size;

  @protected
  set size(Size value) {
    assert(!(debugDoingThisResize && debugDoingThisLayout));
    assert(sizedByParent || !debugDoingThisResize);
    assert(() {
      if ((sizedByParent && debugDoingThisResize) ||
          (!sizedByParent && debugDoingThisLayout)) return true;
      assert(!debugDoingThisResize);
      final List<DiagnosticsNode> information = <DiagnosticsNode>[];
      information
          .add(ErrorSummary('RenderBox size setter called incorrectly.'));
      if (debugDoingThisLayout) {
        assert(sizedByParent);
        information.add(ErrorDescription(
            'It appears that the size setter was called from performLayout().'));
      } else {
        information.add(ErrorDescription(
            'The size setter was called from outside layout (neither performResize() nor performLayout() were being run for this object).'));
        if (owner != null && owner.debugDoingLayout)
          information.add(ErrorDescription(
              'Only the object itself can set its size. It is a contract violation for other objects to set it.'));
      }
      if (sizedByParent)
        information.add(ErrorDescription(
            'Because this RenderBox has sizedByParent set to true, it must set its size in performResize().'));
      else
        information.add(ErrorDescription(
            'Because this RenderBox has sizedByParent set to false, it must set its size in performLayout().'));
      throw FlutterError.fromParts(information);
    }());
    assert(() {
      value = debugAdoptSize(value);
      return true;
    }());
    _size = value;
    assert(() {
      debugAssertDoesMeetConstraints();
      return true;
    }());
  }

  Size debugAdoptSize(Size value) {
    Size result = value;
    assert(() {
      if (value is _DebugSize) {
        if (value._owner != this) {
          if (value._owner.parent != this) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary(
                  'The size property was assigned a size inappropriately.'),
              describeForError('The following render object'),
              value._owner
                  .describeForError('...was assigned a size obtained from'),
              ErrorDescription(
                  'However, this second render object is not, or is no longer, a '
                  'child of the first, and it is therefore a violation of the '
                  'RenderBox layout protocol to use that size in the layout of the '
                  'first render object.'),
              ErrorHint(
                  'If the size was obtained at a time where it was valid to read '
                  'the size (because the second render object above was a child '
                  'of the first at the time), then it should be adopted using '
                  'debugAdoptSize at that time.'),
              ErrorHint(
                  'If the size comes from a grandchild or a render object from an '
                  'entirely different part of the render tree, then there is no '
                  'way to be notified when the size changes and therefore attempts '
                  'to read that size are almost certainly a source of bugs. A different '
                  'approach should be used.'),
            ]);
          }
          if (!value._canBeUsedByParent) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary(
                  'A child\'s size was used without setting parentUsesSize.'),
              describeForError('The following render object'),
              value._owner.describeForError(
                  '...was assigned a size obtained from its child'),
              ErrorDescription(
                  'However, when the child was laid out, the parentUsesSize argument '
                  'was not set or set to false. Subsequently this transpired to be '
                  'inaccurate: the size was nonetheless used by the parent.\n'
                  'It is important to tell the framework if the size will be used or not '
                  'as several important performance optimizations can be made if the '
                  'size will not be used by the parent.')
            ]);
          }
        }
      }
      result = _DebugSize(value, this, debugCanParentUseSize);
      return true;
    }());
    return result;
  }

  @override
  Rect get semanticBounds => Offset.zero & size;

  @override
  void debugResetSize() {
    size = size;
  }

  Map<TextBaseline, double> _cachedBaselines;
  static bool _debugDoingBaseline = false;
  static bool _debugSetDoingBaseline(bool value) {
    _debugDoingBaseline = value;
    return true;
  }

  double getDistanceToBaseline(TextBaseline baseline, {bool onlyReal = false}) {
    assert(!_debugDoingBaseline,
        'Please see the documentation for computeDistanceToActualBaseline for the required calling conventions of this method.');
    assert(!debugNeedsLayout);
    assert(() {
      final RenderObject parent = this.parent;
      if (owner.debugDoingLayout)
        return (RenderObject.debugActiveLayout == parent) &&
            parent.debugDoingThisLayout;
      if (owner.debugDoingPaint)
        return ((RenderObject.debugActivePaint == parent) &&
                parent.debugDoingThisPaint) ||
            ((RenderObject.debugActivePaint == this) && debugDoingThisPaint);
      assert(parent == this.parent);
      return false;
    }());
    assert(_debugSetDoingBaseline(true));
    final double result = getDistanceToActualBaseline(baseline);
    assert(_debugSetDoingBaseline(false));
    if (result == null && !onlyReal) return size.height;
    return result;
  }

  @protected
  @mustCallSuper
  double getDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugDoingBaseline,
        'Please see the documentation for computeDistanceToActualBaseline for the required calling conventions of this method.');
    _cachedBaselines ??= <TextBaseline, double>{};
    _cachedBaselines.putIfAbsent(
        baseline, () => computeDistanceToActualBaseline(baseline));
    return _cachedBaselines[baseline];
  }

  @protected
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(_debugDoingBaseline,
        'Please see the documentation for computeDistanceToActualBaseline for the required calling conventions of this method.');
    return null;
  }

  @override
  BoxConstraints get constraints => super.constraints;

  @override
  void debugAssertDoesMeetConstraints() {
    assert(constraints != null);
    assert(() {
      if (!hasSize) {
        assert(!debugNeedsLayout);
        DiagnosticsNode contract;
        if (sizedByParent)
          contract = ErrorDescription(
              'Because this RenderBox has sizedByParent set to true, it must set its size in performResize().');
        else
          contract = ErrorDescription(
              'Because this RenderBox has sizedByParent set to false, it must set its size in performLayout().');
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('RenderBox did not set its size during layout.'),
          contract,
          ErrorDescription(
              'It appears that this did not happen; layout completed, but the size property is still null.'),
          DiagnosticsProperty<RenderBox>('The RenderBox in question is', this,
              style: DiagnosticsTreeStyle.errorProperty)
        ]);
      }

      if (!_size.isFinite) {
        final List<DiagnosticsNode> information = <DiagnosticsNode>[
          ErrorSummary(
              '$runtimeType object was given an infinite size during layout.'),
          ErrorDescription(
              'This probably means that it is a render object that tries to be '
              'as big as possible, but it was put inside another render object '
              'that allows its children to pick their own size.')
        ];
        if (!constraints.hasBoundedWidth) {
          RenderBox node = this;
          while (!node.constraints.hasBoundedWidth && node.parent is RenderBox)
            node = node.parent;

          information.add(node.describeForError(
              'The nearest ancestor providing an unbounded width constraint is'));
        }
        if (!constraints.hasBoundedHeight) {
          RenderBox node = this;
          while (!node.constraints.hasBoundedHeight && node.parent is RenderBox)
            node = node.parent;

          information.add(node.describeForError(
              'The nearest ancestor providing an unbounded height constraint is'));
        }
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ...information,
          DiagnosticsProperty<BoxConstraints>(
              'The constraints that applied to the $runtimeType were',
              constraints,
              style: DiagnosticsTreeStyle.errorProperty),
          DiagnosticsProperty<Size>('The exact size it was given was', _size,
              style: DiagnosticsTreeStyle.errorProperty),
          ErrorHint(
              'See https://flutter.dev/docs/development/ui/layout/box-constraints for more information.'),
        ]);
      }

      if (!constraints.isSatisfiedBy(_size)) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType does not meet its constraints.'),
          DiagnosticsProperty<BoxConstraints>('Constraints', constraints,
              style: DiagnosticsTreeStyle.errorProperty),
          DiagnosticsProperty<Size>('Size', _size,
              style: DiagnosticsTreeStyle.errorProperty),
          ErrorHint(
              'If you are not writing your own RenderBox subclass, then this is not '
              'your fault. Contact support: https://github.com/flutter/flutter/issues/new?template=BUG.md'),
        ]);
      }
      if (debugCheckIntrinsicSizes) {
        assert(!RenderObject.debugCheckingIntrinsics);
        RenderObject.debugCheckingIntrinsics = true;
        final List<DiagnosticsNode> failures = <DiagnosticsNode>[];

        double testIntrinsic(
            double function(double extent), String name, double constraint) {
          final double result = function(constraint);
          if (result < 0) {
            failures.add(ErrorDescription(
                ' * $name($constraint) returned a negative value: $result'));
          }
          if (!result.isFinite) {
            failures.add(ErrorDescription(
                ' * $name($constraint) returned a non-finite value: $result'));
          }
          return result;
        }

        void testIntrinsicsForValues(double getMin(double extent),
            double getMax(double extent), String name, double constraint) {
          final double min =
              testIntrinsic(getMin, 'getMinIntrinsic$name', constraint);
          final double max =
              testIntrinsic(getMax, 'getMaxIntrinsic$name', constraint);
          if (min > max) {
            failures.add(ErrorDescription(
                ' * getMinIntrinsic$name($constraint) returned a larger value ($min) than getMaxIntrinsic$name($constraint) ($max)'));
          }
        }

        testIntrinsicsForValues(getMinIntrinsicWidth, getMaxIntrinsicWidth,
            'Width', double.infinity);
        testIntrinsicsForValues(getMinIntrinsicHeight, getMaxIntrinsicHeight,
            'Height', double.infinity);
        if (constraints.hasBoundedWidth)
          testIntrinsicsForValues(getMinIntrinsicWidth, getMaxIntrinsicWidth,
              'Width', constraints.maxHeight);
        if (constraints.hasBoundedHeight)
          testIntrinsicsForValues(getMinIntrinsicHeight, getMaxIntrinsicHeight,
              'Height', constraints.maxWidth);

        RenderObject.debugCheckingIntrinsics = false;
        if (failures.isNotEmpty) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                'The intrinsic dimension methods of the $runtimeType class returned values that violate the intrinsic protocol contract.'),
            ErrorDescription(
                'The following ${failures.length > 1 ? "failures" : "failure"} was detected:'),
            ...failures,
            ErrorHint(
                'If you are not writing your own RenderBox subclass, then this is not\n'
                'your fault. Contact support: https://github.com/flutter/flutter/issues/new?template=BUG.md'),
          ]);
        }
      }
      return true;
    }());
  }

  @override
  void markNeedsLayout() {
    if ((_cachedBaselines != null && _cachedBaselines.isNotEmpty) ||
        (_cachedIntrinsicDimensions != null &&
            _cachedIntrinsicDimensions.isNotEmpty)) {
      _cachedBaselines?.clear();
      _cachedIntrinsicDimensions?.clear();
      if (parent is RenderObject) {
        markParentNeedsLayout();
        return;
      }
    }
    super.markNeedsLayout();
  }

  @override
  void performResize() {
    size = constraints.smallest;
    assert(size.isFinite);
  }

  @override
  void performLayout() {
    assert(() {
      if (!sizedByParent) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType did not implement performLayout().'),
          ErrorHint(
              'RenderBox subclasses need to either override performLayout() to '
              'set a size and lay out any children, or, set sizedByParent to true '
              'so that performResize() sizes the render object.')
        ]);
      }
      return true;
    }());
  }

  bool hitTest(BoxHitTestResult result, {@required Offset position}) {
    assert(() {
      if (!hasSize) {
        if (debugNeedsLayout) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                'Cannot hit test a render box that has never been laid out.'),
            describeForError(
                'The hitTest() method was called on this RenderBox'),
            ErrorDescription(
                'Unfortunately, this object\'s geometry is not known at this time, '
                'probably because it has never been laid out. '
                'This means it cannot be accurately hit-tested.'),
            ErrorHint('If you are trying '
                'to perform a hit test during the layout phase itself, make sure '
                'you only hit test nodes that have completed layout (e.g. the node\'s '
                'children, after their layout() method has been called).')
          ]);
        }
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot hit test a render box with no size.'),
          describeForError('The hitTest() method was called on this RenderBox'),
          ErrorDescription(
              'Although this node is not marked as needing layout, '
              'its size is not set.'),
          ErrorHint('A RenderBox object must have an '
              'explicit size before it can be hit-tested. Make sure '
              'that the RenderBox in question sets its size during layout.'),
        ]);
      }
      return true;
    }());
    if (_size.contains(position)) {
      if (hitTestChildren(result, position: position) ||
          hitTestSelf(position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }

  @protected
  bool hitTestSelf(Offset position) => false;

  @protected
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) => false;

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child.parent == this);
    assert(() {
      if (child.parentData is! BoxParentData) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType does not implement applyPaintTransform.'),
          describeForError('The following $runtimeType object'),
          child.describeForError(
              '...did not use a BoxParentData class for the parentData field of the following child'),
          ErrorDescription('The $runtimeType class inherits from RenderBox.'),
          ErrorHint(
              'The default applyPaintTransform implementation provided by RenderBox assumes that the '
              'children all use BoxParentData objects for their parentData field. '
              'Since $runtimeType does not in fact use that ParentData class for its children, it must '
              'provide an implementation of applyPaintTransform that supports the specific ParentData '
              'subclass used by its children (which apparently is ${child.parentData.runtimeType}).')
        ]);
      }
      return true;
    }());
    final BoxParentData childParentData = child.parentData;
    final Offset offset = childParentData.offset;
    transform.translate(offset.dx, offset.dy);
  }

  Offset globalToLocal(Offset point, {RenderObject ancestor}) {
    final Matrix4 transform = getTransformTo(ancestor);
    final double det = transform.invert();
    if (det == 0.0) return Offset.zero;
    final Vector3 n = Vector3(0.0, 0.0, 1.0);
    final Vector3 i = transform.perspectiveTransform(Vector3(0.0, 0.0, 0.0));
    final Vector3 d =
        transform.perspectiveTransform(Vector3(0.0, 0.0, 1.0)) - i;
    final Vector3 s =
        transform.perspectiveTransform(Vector3(point.dx, point.dy, 0.0));
    final Vector3 p = s - d * (n.dot(s) / n.dot(d));
    return Offset(p.x, p.y);
  }

  Offset localToGlobal(Offset point, {RenderObject ancestor}) {
    return MatrixUtils.transformPoint(getTransformTo(ancestor), point);
  }

  @override
  Rect get paintBounds => Offset.zero & size;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    super.handleEvent(event, entry);
  }

  int _debugActivePointers = 0;

  bool debugHandleEvent(PointerEvent event, HitTestEntry entry) {
    assert(() {
      if (debugPaintPointersEnabled) {
        if (event is PointerDownEvent) {
          _debugActivePointers += 1;
        } else if (event is PointerUpEvent || event is PointerCancelEvent) {
          _debugActivePointers -= 1;
        }
        markNeedsPaint();
      }
      return true;
    }());
    return true;
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(() {
      if (debugPaintSizeEnabled) debugPaintSize(context, offset);
      if (debugPaintBaselinesEnabled) debugPaintBaselines(context, offset);
      if (debugPaintPointersEnabled) debugPaintPointers(context, offset);
      return true;
    }());
  }

  @protected
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF00FFFF);
      context.canvas.drawRect((offset & size).deflate(0.5), paint);
      return true;
    }());
  }

  @protected
  void debugPaintBaselines(PaintingContext context, Offset offset) {
    assert(() {
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.25;
      Path path;

      final double baselineI =
          getDistanceToBaseline(TextBaseline.ideographic, onlyReal: true);
      if (baselineI != null) {
        paint.color = const Color(0xFFFFD000);
        path = Path();
        path.moveTo(offset.dx, offset.dy + baselineI);
        path.lineTo(offset.dx + size.width, offset.dy + baselineI);
        context.canvas.drawPath(path, paint);
      }

      final double baselineA =
          getDistanceToBaseline(TextBaseline.alphabetic, onlyReal: true);
      if (baselineA != null) {
        paint.color = const Color(0xFF00FF00);
        path = Path();
        path.moveTo(offset.dx, offset.dy + baselineA);
        path.lineTo(offset.dx + size.width, offset.dy + baselineA);
        context.canvas.drawPath(path, paint);
      }
      return true;
    }());
  }

  @protected
  void debugPaintPointers(PaintingContext context, Offset offset) {
    assert(() {
      if (_debugActivePointers > 0) {
        final Paint paint = Paint()
          ..color = Color(0x00BBBB | ((0x04000000 * depth) & 0xFF000000));
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<Size>('size', _size, missingIfNull: true));
  }
}

mixin RenderBoxContainerDefaultsMixin<ChildType extends RenderBox,
        ParentDataType extends ContainerBoxParentData<ChildType>>
    implements ContainerRenderObjectMixin<ChildType, ParentDataType> {
  double defaultComputeDistanceToFirstActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    ChildType child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      final double result = child.getDistanceToActualBaseline(baseline);
      if (result != null) return result + childParentData.offset.dy;
      child = childParentData.nextSibling;
    }
    return null;
  }

  double defaultComputeDistanceToHighestActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    double result;
    ChildType child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      double candidate = child.getDistanceToActualBaseline(baseline);
      if (candidate != null) {
        candidate += childParentData.offset.dy;
        if (result != null)
          result = math.min(result, candidate);
        else
          result = candidate;
      }
      child = childParentData.nextSibling;
    }
    return result;
  }

  bool defaultHitTestChildren(BoxHitTestResult result, {Offset position}) {
    ChildType child = lastChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
      child = childParentData.previousSibling;
    }
    return false;
  }

  void defaultPaint(PaintingContext context, Offset offset) {
    ChildType child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }

  List<ChildType> getChildrenAsList() {
    final List<ChildType> result = <ChildType>[];
    RenderBox child = firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      result.add(child);
      child = childParentData.nextSibling;
    }
    return result;
  }
}

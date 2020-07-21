import 'dart:math' as math;
import 'package:flutter_web/ui.dart' as ui;

import 'package:flutter_web/widgets.dart';
import 'package:flutter_web/rendering.dart';

import 'button.dart';
import 'colors.dart';
import 'localizations.dart';

const Color _kHandlesColor = Color(0xFF136FE0);
const double _kSelectionHandleOverlap = 1.5;
const double _kSelectionHandleRadius = 5.5;

const double _kToolbarScreenPadding = 8.0;

const double _kArrowScreenPadding = 26.0;

const double _kToolbarContentDistance = 8.0;

const double _kToolbarHeight = 43.0;
const Color _kToolbarBackgroundColor = Color(0xEB202020);
const Color _kToolbarDividerColor = Color(0xFF808080);
const Size _kToolbarArrowSize = Size(14.0, 7.0);
const EdgeInsets _kToolbarButtonPadding =
    EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0);
const Radius _kToolbarBorderRadius = Radius.circular(8);

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.white,
);

@visibleForTesting
class CupertinoTextSelectionToolbar extends SingleChildRenderObjectWidget {
  const CupertinoTextSelectionToolbar._({
    Key key,
    double barTopY,
    double arrowTipX,
    bool isArrowPointingDown,
    Widget child,
  })  : _barTopY = barTopY,
        _arrowTipX = arrowTipX,
        _isArrowPointingDown = isArrowPointingDown,
        super(key: key, child: child);

  final double _barTopY;

  final double _arrowTipX;

  final bool _isArrowPointingDown;

  @override
  _ToolbarRenderBox createRenderObject(BuildContext context) =>
      _ToolbarRenderBox(_barTopY, _arrowTipX, _isArrowPointingDown, null);

  @override
  void updateRenderObject(
      BuildContext context, _ToolbarRenderBox renderObject) {
    renderObject
      ..barTopY = _barTopY
      ..arrowTipX = _arrowTipX
      ..isArrowPointingDown = _isArrowPointingDown;
  }
}

class _ToolbarParentData extends BoxParentData {
  double arrowXOffsetFromCenter;
  @override
  String toString() =>
      'offset=$offset, arrowXOffsetFromCenter=$arrowXOffsetFromCenter';
}

class _ToolbarRenderBox extends RenderShiftedBox {
  _ToolbarRenderBox(
    this._barTopY,
    this._arrowTipX,
    this._isArrowPointingDown,
    RenderBox child,
  ) : super(child);

  @override
  bool get isRepaintBoundary => true;

  double _barTopY;
  set barTopY(double value) {
    if (_barTopY == value) {
      return;
    }
    _barTopY = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  double _arrowTipX;
  set arrowTipX(double value) {
    if (_arrowTipX == value) {
      return;
    }
    _arrowTipX = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  bool _isArrowPointingDown;
  set isArrowPointingDown(bool value) {
    if (_isArrowPointingDown == value) {
      return;
    }
    _isArrowPointingDown = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  final BoxConstraints heightConstraint =
      const BoxConstraints.tightFor(height: _kToolbarHeight);

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _ToolbarParentData) {
      child.parentData = _ToolbarParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    if (child == null) {
      return;
    }
    final BoxConstraints enforcedConstraint = constraints
        .deflate(const EdgeInsets.symmetric(horizontal: _kToolbarScreenPadding))
        .loosen();

    child.layout(
      heightConstraint.enforce(enforcedConstraint),
      parentUsesSize: true,
    );
    final _ToolbarParentData childParentData = child.parentData;

    final Offset localTopCenter = globalToLocal(Offset(_arrowTipX, _barTopY));

    final double lowerBound = child.size.width / 2 + _kToolbarScreenPadding;
    final double upperBound =
        size.width - child.size.width / 2 - _kToolbarScreenPadding;
    final double adjustedCenterX =
        localTopCenter.dx.clamp(lowerBound, upperBound);

    childParentData.offset =
        Offset(adjustedCenterX - child.size.width / 2, localTopCenter.dy);
    childParentData.arrowXOffsetFromCenter =
        localTopCenter.dx - adjustedCenterX;
  }

  Path _clipPath() {
    final _ToolbarParentData childParentData = child.parentData;
    final Path rrect = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset(
                0,
                _isArrowPointingDown ? 0 : _kToolbarArrowSize.height,
              ) &
              Size(child.size.width,
                  child.size.height - _kToolbarArrowSize.height),
          _kToolbarBorderRadius,
        ),
      );

    final double arrowTipX =
        child.size.width / 2 + childParentData.arrowXOffsetFromCenter;

    final double arrowBottomY = _isArrowPointingDown
        ? child.size.height - _kToolbarArrowSize.height
        : _kToolbarArrowSize.height;

    final double arrowTipY = _isArrowPointingDown ? child.size.height : 0;

    final Path arrow = Path()
      ..moveTo(arrowTipX, arrowTipY)
      ..lineTo(arrowTipX - _kToolbarArrowSize.width / 2, arrowBottomY)
      ..lineTo(arrowTipX + _kToolbarArrowSize.width / 2, arrowBottomY)
      ..close();

    return Path.combine(PathOperation.union, rrect, arrow);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    final _ToolbarParentData childParentData = child.parentData;
    context.pushClipPath(
      needsCompositing,
      offset + childParentData.offset,
      Offset.zero & child.size,
      _clipPath(),
      (PaintingContext innerContext, Offset innerOffset) =>
          innerContext.paintChild(child, innerOffset),
    );
  }

  Paint _debugPaint;

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      if (child == null) {
        return true;
      }

      _debugPaint ??= Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0.0, 0.0),
          const Offset(10.0, 10.0),
          <Color>[
            const Color(0x00000000),
            const Color(0xFFFF00FF),
            const Color(0xFFFF00FF),
            const Color(0x00000000)
          ],
          <double>[0.25, 0.25, 0.75, 0.75],
          TileMode.repeated,
        )
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final _ToolbarParentData childParentData = child.parentData;
      context.canvas.drawPath(
          _clipPath().shift(offset + childParentData.offset), _debugPaint);
      return true;
    }());
  }
}

class _TextSelectionHandlePainter extends CustomPainter {
  const _TextSelectionHandlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = _kHandlesColor
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      const Offset(_kSelectionHandleRadius, _kSelectionHandleRadius),
      _kSelectionHandleRadius,
      paint,
    );

    canvas.drawLine(
      const Offset(
        _kSelectionHandleRadius,
        2 * _kSelectionHandleRadius - _kSelectionHandleOverlap,
      ),
      Offset(
        _kSelectionHandleRadius,
        size.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) => false;
}

class _CupertinoTextSelectionControls extends TextSelectionControls {
  @override
  Size getHandleSize(double textLineHeight) {
    return Size(
      _kSelectionHandleRadius * 2,
      textLineHeight + _kSelectionHandleRadius * 2 - _kSelectionHandleOverlap,
    );
  }

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
  ) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final bool isArrowPointingDown = mediaQuery.padding.top +
            _kToolbarScreenPadding +
            _kToolbarHeight +
            _kToolbarContentDistance <=
        globalEditableRegion.top + endpoints.first.point.dy - textLineHeight;

    final double arrowTipX = (position.dx + globalEditableRegion.left).clamp(
      _kArrowScreenPadding + mediaQuery.padding.left,
      mediaQuery.size.width - mediaQuery.padding.right - _kArrowScreenPadding,
    );

    final double localBarTopY = isArrowPointingDown
        ? endpoints.first.point.dy -
            textLineHeight -
            _kToolbarContentDistance -
            _kToolbarHeight
        : endpoints.last.point.dy + _kToolbarContentDistance;

    final List<Widget> items = <Widget>[];
    final Widget onePhysicalPixelVerticalDivider =
        SizedBox(width: 1.0 / MediaQuery.of(context).devicePixelRatio);
    final CupertinoLocalizations localizations =
        CupertinoLocalizations.of(context);
    final EdgeInsets arrowPadding = isArrowPointingDown
        ? EdgeInsets.only(bottom: _kToolbarArrowSize.height)
        : EdgeInsets.only(top: _kToolbarArrowSize.height);

    void addToolbarButtonIfNeeded(
        String text,
        bool Function(TextSelectionDelegate) predicate,
        void Function(TextSelectionDelegate) onPressed) {
      if (!predicate(delegate)) {
        return;
      }

      if (items.isNotEmpty) {
        items.add(onePhysicalPixelVerticalDivider);
      }

      items.add(CupertinoButton(
        child: Text(text, style: _kToolbarButtonFontStyle),
        color: _kToolbarBackgroundColor,
        minSize: _kToolbarHeight,
        padding: _kToolbarButtonPadding.add(arrowPadding),
        borderRadius: null,
        pressedOpacity: 0.7,
        onPressed: () => onPressed(delegate),
      ));
    }

    addToolbarButtonIfNeeded(localizations.cutButtonLabel, canCut, handleCut);
    addToolbarButtonIfNeeded(
        localizations.copyButtonLabel, canCopy, handleCopy);
    addToolbarButtonIfNeeded(
        localizations.pasteButtonLabel, canPaste, handlePaste);
    addToolbarButtonIfNeeded(
        localizations.selectAllButtonLabel, canSelectAll, handleSelectAll);

    return CupertinoTextSelectionToolbar._(
      barTopY: localBarTopY + globalEditableRegion.top,
      arrowTipX: arrowTipX,
      isArrowPointingDown: isArrowPointingDown,
      child: items.isEmpty
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(color: _kToolbarDividerColor),
              child: Row(mainAxisSize: MainAxisSize.min, children: items),
            ),
    );
  }

  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type,
      double textLineHeight) {
    final Size desiredSize = getHandleSize(textLineHeight);

    final Widget handle = SizedBox.fromSize(
      size: desiredSize,
      child: const CustomPaint(
        painter: _TextSelectionHandlePainter(),
      ),
    );

    switch (type) {
      case TextSelectionHandleType.left:
        return handle;
      case TextSelectionHandleType.right:
        return Transform(
          transform: Matrix4.identity()
            ..translate(desiredSize.width / 2, desiredSize.height / 2)
            ..rotateZ(math.pi)
            ..translate(-desiredSize.width / 2, -desiredSize.height / 2),
          child: handle,
        );

      case TextSelectionHandleType.collapsed:
        return const SizedBox();
    }
    assert(type != null);
    return null;
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    final Size handleSize = getHandleSize(textLineHeight);
    switch (type) {
      case TextSelectionHandleType.left:
        return Offset(
          handleSize.width / 2,
          handleSize.height,
        );

      case TextSelectionHandleType.right:
        return Offset(
          handleSize.width / 2,
          handleSize.height -
              2 * _kSelectionHandleRadius +
              _kSelectionHandleOverlap,
        );

      default:
        return Offset(
          handleSize.width / 2,
          textLineHeight + (handleSize.height - textLineHeight) / 2,
        );
    }
  }
}

final TextSelectionControls cupertinoTextSelectionControls =
    _CupertinoTextSelectionControls();

import 'dart:math' as math;

import 'package:flutter_web/rendering.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';

class NavigationToolbar extends StatelessWidget {
  const NavigationToolbar({
    Key key,
    this.leading,
    this.middle,
    this.trailing,
    this.centerMiddle = true,
    this.middleSpacing = kMiddleSpacing,
  })  : assert(centerMiddle != null),
        assert(middleSpacing != null),
        super(key: key);

  static const double kMiddleSpacing = 16.0;

  final Widget leading;

  final Widget middle;

  final Widget trailing;

  final bool centerMiddle;

  final double middleSpacing;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    final List<Widget> children = <Widget>[];

    if (leading != null)
      children.add(LayoutId(id: _ToolbarSlot.leading, child: leading));

    if (middle != null)
      children.add(LayoutId(id: _ToolbarSlot.middle, child: middle));

    if (trailing != null)
      children.add(LayoutId(id: _ToolbarSlot.trailing, child: trailing));

    final TextDirection textDirection = Directionality.of(context);
    return CustomMultiChildLayout(
      delegate: _ToolbarLayout(
        centerMiddle: centerMiddle,
        middleSpacing: middleSpacing,
        textDirection: textDirection,
      ),
      children: children,
    );
  }
}

enum _ToolbarSlot {
  leading,
  middle,
  trailing,
}

class _ToolbarLayout extends MultiChildLayoutDelegate {
  _ToolbarLayout({
    this.centerMiddle,
    @required this.middleSpacing,
    @required this.textDirection,
  })  : assert(middleSpacing != null),
        assert(textDirection != null);

  final bool centerMiddle;

  final double middleSpacing;

  final TextDirection textDirection;

  @override
  void performLayout(Size size) {
    double leadingWidth = 0.0;
    double trailingWidth = 0.0;

    if (hasChild(_ToolbarSlot.leading)) {
      final BoxConstraints constraints = BoxConstraints(
        minWidth: 0.0,
        maxWidth: size.width / 3.0,
        minHeight: size.height,
        maxHeight: size.height,
      );
      leadingWidth = layoutChild(_ToolbarSlot.leading, constraints).width;
      double leadingX;
      switch (textDirection) {
        case TextDirection.rtl:
          leadingX = size.width - leadingWidth;
          break;
        case TextDirection.ltr:
          leadingX = 0.0;
          break;
      }
      positionChild(_ToolbarSlot.leading, Offset(leadingX, 0.0));
    }

    if (hasChild(_ToolbarSlot.trailing)) {
      final BoxConstraints constraints = BoxConstraints.loose(size);
      final Size trailingSize = layoutChild(_ToolbarSlot.trailing, constraints);
      double trailingX;
      switch (textDirection) {
        case TextDirection.rtl:
          trailingX = 0.0;
          break;
        case TextDirection.ltr:
          trailingX = size.width - trailingSize.width;
          break;
      }
      final double trailingY = (size.height - trailingSize.height) / 2.0;
      trailingWidth = trailingSize.width;
      positionChild(_ToolbarSlot.trailing, Offset(trailingX, trailingY));
    }

    if (hasChild(_ToolbarSlot.middle)) {
      final double maxWidth = math.max(
          size.width - leadingWidth - trailingWidth - middleSpacing * 2.0, 0.0);
      final BoxConstraints constraints =
          BoxConstraints.loose(size).copyWith(maxWidth: maxWidth);
      final Size middleSize = layoutChild(_ToolbarSlot.middle, constraints);

      final double middleStartMargin = leadingWidth + middleSpacing;
      double middleStart = middleStartMargin;
      final double middleY = (size.height - middleSize.height) / 2.0;

      if (centerMiddle) {
        middleStart = (size.width - middleSize.width) / 2.0;
        if (middleStart + middleSize.width > size.width - trailingWidth)
          middleStart = size.width - trailingWidth - middleSize.width;
        else if (middleStart < middleStartMargin)
          middleStart = middleStartMargin;
      }

      double middleX;
      switch (textDirection) {
        case TextDirection.rtl:
          middleX = size.width - middleSize.width - middleStart;
          break;
        case TextDirection.ltr:
          middleX = middleStart;
          break;
      }

      positionChild(_ToolbarSlot.middle, Offset(middleX, middleY));
    }
  }

  @override
  bool shouldRelayout(_ToolbarLayout oldDelegate) {
    return oldDelegate.centerMiddle != centerMiddle ||
        oldDelegate.middleSpacing != middleSpacing ||
        oldDelegate.textDirection != textDirection;
  }
}

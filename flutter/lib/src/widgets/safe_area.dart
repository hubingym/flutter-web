import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'media_query.dart';

class SafeArea extends StatelessWidget {
  const SafeArea({
    Key key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    @required this.child,
  })  : assert(left != null),
        assert(top != null),
        assert(right != null),
        assert(bottom != null),
        super(key: key);

  final bool left;

  final bool top;

  final bool right;

  final bool bottom;

  final EdgeInsets minimum;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final EdgeInsets padding = MediaQuery.of(context).padding;
    return Padding(
      padding: EdgeInsets.only(
        left: math.max(left ? padding.left : 0.0, minimum.left),
        top: math.max(top ? padding.top : 0.0, minimum.top),
        right: math.max(right ? padding.right : 0.0, minimum.right),
        bottom: math.max(bottom ? padding.bottom : 0.0, minimum.bottom),
      ),
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: left,
        removeTop: top,
        removeRight: right,
        removeBottom: bottom,
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(FlagProperty('left', value: left, ifTrue: 'avoid left padding'));
    properties
        .add(FlagProperty('top', value: left, ifTrue: 'avoid top padding'));
    properties
        .add(FlagProperty('right', value: left, ifTrue: 'avoid right padding'));
    properties.add(
        FlagProperty('bottom', value: left, ifTrue: 'avoid bottom padding'));
  }
}

class SliverSafeArea extends StatelessWidget {
  const SliverSafeArea({
    Key key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    @required this.sliver,
  })  : assert(left != null),
        assert(top != null),
        assert(right != null),
        assert(bottom != null),
        super(key: key);

  final bool left;

  final bool top;

  final bool right;

  final bool bottom;

  final EdgeInsets minimum;

  final Widget sliver;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final EdgeInsets padding = MediaQuery.of(context).padding;
    return SliverPadding(
      padding: EdgeInsets.only(
        left: math.max(left ? padding.left : 0.0, minimum.left),
        top: math.max(top ? padding.top : 0.0, minimum.top),
        right: math.max(right ? padding.right : 0.0, minimum.right),
        bottom: math.max(bottom ? padding.bottom : 0.0, minimum.bottom),
      ),
      sliver: MediaQuery.removePadding(
        context: context,
        removeLeft: left,
        removeTop: top,
        removeRight: right,
        removeBottom: bottom,
        child: sliver,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(FlagProperty('left', value: left, ifTrue: 'avoid left padding'));
    properties
        .add(FlagProperty('top', value: left, ifTrue: 'avoid top padding'));
    properties
        .add(FlagProperty('right', value: left, ifTrue: 'avoid right padding'));
    properties.add(
        FlagProperty('bottom', value: left, ifTrue: 'avoid bottom padding'));
  }
}

import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'constants.dart';
import 'theme.dart';

enum CollapseMode {
  parallax,

  pin,

  none,
}

class FlexibleSpaceBar extends StatefulWidget {
  const FlexibleSpaceBar(
      {Key key,
      this.title,
      this.background,
      this.centerTitle,
      this.collapseMode = CollapseMode.parallax})
      : assert(collapseMode != null),
        super(key: key);

  final Widget title;

  final Widget background;

  final bool centerTitle;

  final CollapseMode collapseMode;

  static Widget createSettings({
    double toolbarOpacity,
    double minExtent,
    double maxExtent,
    @required double currentExtent,
    @required Widget child,
  }) {
    assert(currentExtent != null);
    return _FlexibleSpaceBarSettings(
      toolbarOpacity: toolbarOpacity ?? 1.0,
      minExtent: minExtent ?? currentExtent,
      maxExtent: maxExtent ?? currentExtent,
      currentExtent: currentExtent,
      child: child,
    );
  }

  @override
  _FlexibleSpaceBarState createState() => _FlexibleSpaceBarState();
}

class _FlexibleSpaceBarState extends State<FlexibleSpaceBar> {
  bool _getEffectiveCenterTitle(ThemeData theme) {
    if (widget.centerTitle != null) return widget.centerTitle;
    assert(theme.platform != null);
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return false;
      case TargetPlatform.iOS:
        return true;
    }
    return null;
  }

  Alignment _getTitleAlignment(bool effectiveCenterTitle) {
    if (effectiveCenterTitle) return Alignment.bottomCenter;
    final TextDirection textDirection = Directionality.of(context);
    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.rtl:
        return Alignment.bottomRight;
      case TextDirection.ltr:
        return Alignment.bottomLeft;
    }
    return null;
  }

  double _getCollapsePadding(double t, _FlexibleSpaceBarSettings settings) {
    switch (widget.collapseMode) {
      case CollapseMode.pin:
        return -(settings.maxExtent - settings.currentExtent);
      case CollapseMode.none:
        return 0.0;
      case CollapseMode.parallax:
        final double deltaExtent = settings.maxExtent - settings.minExtent;
        return -Tween<double>(begin: 0.0, end: deltaExtent / 4.0).transform(t);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final _FlexibleSpaceBarSettings settings =
        context.inheritFromWidgetOfExactType(_FlexibleSpaceBarSettings);
    assert(settings != null,
        'A FlexibleSpaceBar must be wrapped in the widget returned by FlexibleSpaceBar.createSettings().');

    final List<Widget> children = <Widget>[];

    final double deltaExtent = settings.maxExtent - settings.minExtent;

    final double t =
        (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent)
            .clamp(0.0, 1.0);

    if (widget.background != null) {
      final double fadeStart =
          math.max(0.0, 1.0 - kToolbarHeight / deltaExtent);
      const double fadeEnd = 1.0;
      assert(fadeStart <= fadeEnd);
      final double opacity = 1.0 - Interval(fadeStart, fadeEnd).transform(t);
      if (opacity > 0.0) {
        children.add(Positioned(
            top: _getCollapsePadding(t, settings),
            left: 0.0,
            right: 0.0,
            height: settings.maxExtent,
            child: Opacity(opacity: opacity, child: widget.background)));
      }
    }

    if (widget.title != null) {
      Widget title;
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          title = widget.title;
          break;
        case TargetPlatform.fuchsia:
        case TargetPlatform.android:
          title = Semantics(
            namesRoute: true,
            child: widget.title,
          );
      }

      final ThemeData theme = Theme.of(context);
      final double opacity = settings.toolbarOpacity;
      if (opacity > 0.0) {
        TextStyle titleStyle = theme.primaryTextTheme.title;
        titleStyle =
            titleStyle.copyWith(color: titleStyle.color.withOpacity(opacity));
        final bool effectiveCenterTitle = _getEffectiveCenterTitle(theme);
        final double scaleValue =
            Tween<double>(begin: 1.5, end: 1.0).transform(t);
        final Matrix4 scaleTransform = Matrix4.identity()
          ..scale(scaleValue, scaleValue, 1.0);
        final Alignment titleAlignment =
            _getTitleAlignment(effectiveCenterTitle);
        children.add(Container(
            padding: EdgeInsetsDirectional.only(
                start: effectiveCenterTitle ? 0.0 : 72.0, bottom: 16.0),
            child: Transform(
                alignment: titleAlignment,
                transform: scaleTransform,
                child: Align(
                    alignment: titleAlignment,
                    child: DefaultTextStyle(
                      style: titleStyle,
                      child: title,
                    )))));
      }
    }

    return ClipRect(child: Stack(children: children));
  }
}

class _FlexibleSpaceBarSettings extends InheritedWidget {
  const _FlexibleSpaceBarSettings({
    Key key,
    this.toolbarOpacity,
    this.minExtent,
    this.maxExtent,
    this.currentExtent,
    Widget child,
  }) : super(key: key, child: child);

  final double toolbarOpacity;
  final double minExtent;
  final double maxExtent;
  final double currentExtent;

  @override
  bool updateShouldNotify(_FlexibleSpaceBarSettings oldWidget) {
    return toolbarOpacity != oldWidget.toolbarOpacity ||
        minExtent != oldWidget.minExtent ||
        maxExtent != oldWidget.maxExtent ||
        currentExtent != oldWidget.currentExtent;
  }
}

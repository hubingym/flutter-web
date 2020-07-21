import 'package:flutter_web/widgets.dart';

import 'constants.dart';
import 'theme.dart';
import 'theme_data.dart';

class CircleAvatar extends StatelessWidget {
  const CircleAvatar({
    Key key,
    this.child,
    this.backgroundColor,
    this.backgroundImage,
    this.foregroundColor,
    this.radius,
    this.minRadius,
    this.maxRadius,
  })  : assert(radius == null || (minRadius == null && maxRadius == null)),
        super(key: key);

  final Widget child;

  final Color backgroundColor;

  final Color foregroundColor;

  final ImageProvider backgroundImage;

  final double radius;

  final double minRadius;

  final double maxRadius;

  static const double _defaultRadius = 20.0;

  static const double _defaultMinRadius = 0.0;

  static const double _defaultMaxRadius = double.infinity;

  double get _minDiameter {
    if (radius == null && minRadius == null && maxRadius == null) {
      return _defaultRadius * 2.0;
    }
    return 2.0 * (radius ?? minRadius ?? _defaultMinRadius);
  }

  double get _maxDiameter {
    if (radius == null && minRadius == null && maxRadius == null) {
      return _defaultRadius * 2.0;
    }
    return 2.0 * (radius ?? maxRadius ?? _defaultMaxRadius);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final ThemeData theme = Theme.of(context);
    TextStyle textStyle =
        theme.primaryTextTheme.subhead.copyWith(color: foregroundColor);
    Color effectiveBackgroundColor = backgroundColor;
    if (effectiveBackgroundColor == null) {
      switch (ThemeData.estimateBrightnessForColor(textStyle.color)) {
        case Brightness.dark:
          effectiveBackgroundColor = theme.primaryColorLight;
          break;
        case Brightness.light:
          effectiveBackgroundColor = theme.primaryColorDark;
          break;
      }
    } else if (foregroundColor == null) {
      switch (ThemeData.estimateBrightnessForColor(backgroundColor)) {
        case Brightness.dark:
          textStyle = textStyle.copyWith(color: theme.primaryColorLight);
          break;
        case Brightness.light:
          textStyle = textStyle.copyWith(color: theme.primaryColorDark);
          break;
      }
    }
    final double minDiameter = _minDiameter;
    final double maxDiameter = _maxDiameter;
    return new AnimatedContainer(
      constraints: new BoxConstraints(
        minHeight: minDiameter,
        minWidth: minDiameter,
        maxWidth: maxDiameter,
        maxHeight: maxDiameter,
      ),
      duration: kThemeChangeDuration,
      decoration: new BoxDecoration(
        color: effectiveBackgroundColor,
        image: backgroundImage != null
            ? new DecorationImage(image: backgroundImage, fit: BoxFit.cover)
            : null,
        shape: BoxShape.circle,
      ),
      child: child == null
          ? null
          : new Center(
              child: new MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: new IconTheme(
                  data: theme.iconTheme.copyWith(color: textStyle.color),
                  child: new DefaultTextStyle(
                    style: textStyle,
                    child: child,
                  ),
                ),
              ),
            ),
    );
  }
}

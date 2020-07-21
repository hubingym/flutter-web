import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/ui.dart' hide TextStyle;

import 'package:vector_math/vector_math_64.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'icon_data.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';

class Icon extends StatelessWidget {
  const Icon(
    this.icon, {
    Key key,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  }) : super(key: key);

  final IconData icon;

  final double size;

  final Color color;

  final String semanticLabel;

  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    assert(this.textDirection != null || debugCheckHasDirectionality(context));
    final TextDirection textDirection =
        this.textDirection ?? Directionality.of(context);

    final IconThemeData iconTheme = IconTheme.of(context);

    final double iconSize = size ?? iconTheme.size;

    if (icon == null) {
      return new Semantics(
          label: semanticLabel,
          child: new SizedBox(width: iconSize, height: iconSize));
    }

    final double iconOpacity = iconTheme.opacity;
    Color iconColor = color ?? iconTheme.color;
    if (iconOpacity != 1.0)
      iconColor = iconColor.withOpacity(iconColor.opacity * iconOpacity);

    Widget iconWidget = new RichText(
      textDirection: textDirection,
      text: new TextSpan(
        text: new String.fromCharCode(icon.codePoint),
        style: new TextStyle(
          inherit: false,
          color: iconColor,
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
    );

    if (icon.matchTextDirection) {
      switch (textDirection) {
        case TextDirection.rtl:
          iconWidget = new Transform(
            transform: new Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            alignment: Alignment.center,
            transformHitTests: false,
            child: iconWidget,
          );
          break;
        case TextDirection.ltr:
          break;
      }
    }

    return new Semantics(
      label: semanticLabel,
      child: new ExcludeSemantics(
        child: new SizedBox(
          width: iconSize,
          height: iconSize,
          child: new Center(
            child: iconWidget,
          ),
        ),
      ),
    );
  }
}

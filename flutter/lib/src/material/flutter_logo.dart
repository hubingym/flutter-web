import 'package:flutter_web/widgets.dart';

import 'colors.dart';

class FlutterLogo extends StatelessWidget {
  const FlutterLogo({
    Key key,
    this.size,
    this.colors,
    this.textColor = const Color(0xFF616161),
    this.style = FlutterLogoStyle.markOnly,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.fastOutSlowIn,
  }) : super(key: key);

  final double size;

  final MaterialColor colors;

  final Color textColor;

  final FlutterLogoStyle style;

  final Duration duration;

  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final double iconSize = size ?? iconTheme.size;
    final MaterialColor logoColors = colors ?? Colors.blue;
    return AnimatedContainer(
      width: iconSize,
      height: iconSize,
      duration: duration,
      curve: curve,
      decoration: FlutterLogoDecoration(
        lightColor: logoColors.shade400,
        darkColor: logoColors.shade900,
        style: style,
        textColor: textColor,
      ),
    );
  }
}

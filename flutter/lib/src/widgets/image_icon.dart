import 'package:flutter_web/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'icon.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'image.dart';

class ImageIcon extends StatelessWidget {
  const ImageIcon(
    this.image, {
    Key key,
    this.size,
    this.color,
    this.semanticLabel,
  }) : super(key: key);

  final ImageProvider image;

  final double size;

  final Color color;

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final IconThemeData iconTheme = IconTheme.of(context);
    final double iconSize = size ?? iconTheme.size;

    if (image == null)
      return Semantics(
          label: semanticLabel,
          child: SizedBox(width: iconSize, height: iconSize));

    final double iconOpacity = iconTheme.opacity;
    Color iconColor = color ?? iconTheme.color;

    if (iconOpacity != null && iconOpacity != 1.0)
      iconColor = iconColor.withOpacity(iconColor.opacity * iconOpacity);

    return Semantics(
      label: semanticLabel,
      child: Image(
        image: image,
        width: iconSize,
        height: iconSize,
        color: iconColor,
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        excludeFromSemantics: true,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider>('image', image,
        ifNull: '<empty>', showName: false));
    properties.add(DoubleProperty('size', size, defaultValue: null));
    properties
        .add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
  }
}

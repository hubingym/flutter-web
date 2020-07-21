import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart';

import 'basic.dart';
import 'framework.dart';

class Title extends StatelessWidget {
  Title({
    Key key,
    this.title = '',
    @required this.color,
    @required this.child,
  })  : assert(title != null),
        assert(color != null && color.alpha == 0xFF),
        super(key: key);

  final String title;

  final Color color;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setApplicationSwitcherDescription(
        ApplicationSwitcherDescription(
      label: title,
      primaryColor: color.value,
    ));
    return child;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title, defaultValue: ''));
    properties
        .add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
  }
}

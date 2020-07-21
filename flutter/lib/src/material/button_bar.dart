import 'package:flutter_web/widgets.dart';

import 'button_theme.dart';
import 'dialog.dart';
import 'flat_button.dart';
import 'raised_button.dart';

class ButtonBar extends StatelessWidget {
  const ButtonBar({
    Key key,
    this.alignment = MainAxisAlignment.end,
    this.mainAxisSize = MainAxisSize.max,
    this.children = const <Widget>[],
  }) : super(key: key);

  final MainAxisAlignment alignment;

  final MainAxisSize mainAxisSize;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);

    final double paddingUnit = buttonTheme.padding.horizontal / 4.0;
    final Widget child = Row(
        mainAxisAlignment: alignment,
        mainAxisSize: mainAxisSize,
        children: children.map<Widget>((Widget child) {
          return Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingUnit),
              child: child);
        }).toList());
    switch (buttonTheme.layoutBehavior) {
      case ButtonBarLayoutBehavior.padded:
        return Padding(
          padding: EdgeInsets.symmetric(
              vertical: 2.0 * paddingUnit, horizontal: paddingUnit),
          child: child,
        );
      case ButtonBarLayoutBehavior.constrained:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: paddingUnit),
          constraints: const BoxConstraints(minHeight: 52.0),
          alignment: Alignment.center,
          child: child,
        );
    }
    assert(false);
    return null;
  }
}

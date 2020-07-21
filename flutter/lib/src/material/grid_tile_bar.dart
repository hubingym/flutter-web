import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'theme.dart';

class GridTileBar extends StatelessWidget {
  const GridTileBar(
      {Key key,
      this.backgroundColor,
      this.leading,
      this.title,
      this.subtitle,
      this.trailing})
      : super(key: key);

  final Color backgroundColor;

  final Widget leading;

  final Widget title;

  final Widget subtitle;

  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration;
    if (backgroundColor != null)
      decoration = BoxDecoration(color: backgroundColor);

    final List<Widget> children = <Widget>[];
    final EdgeInsetsDirectional padding = EdgeInsetsDirectional.only(
      start: leading != null ? 8.0 : 16.0,
      end: trailing != null ? 8.0 : 16.0,
    );

    if (leading != null)
      children.add(Padding(
          padding: const EdgeInsetsDirectional.only(end: 8.0), child: leading));

    final ThemeData theme = Theme.of(context);
    final ThemeData darkTheme = ThemeData(
        brightness: Brightness.dark,
        accentColor: theme.accentColor,
        accentColorBrightness: theme.accentColorBrightness);
    if (title != null && subtitle != null) {
      children.add(Expanded(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
            DefaultTextStyle(
                style: darkTheme.textTheme.subhead,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: title),
            DefaultTextStyle(
                style: darkTheme.textTheme.caption,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: subtitle)
          ])));
    } else if (title != null || subtitle != null) {
      children.add(Expanded(
          child: DefaultTextStyle(
              style: darkTheme.textTheme.subhead,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              child: title ?? subtitle)));
    }

    if (trailing != null)
      children.add(Padding(
          padding: const EdgeInsetsDirectional.only(start: 8.0),
          child: trailing));

    return Container(
        padding: padding,
        decoration: decoration,
        height: (title != null && subtitle != null) ? 68.0 : 48.0,
        child: Theme(
            data: darkTheme,
            child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: children))));
  }
}

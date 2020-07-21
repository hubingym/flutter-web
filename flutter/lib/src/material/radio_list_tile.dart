import 'package:flutter_web/widgets.dart';

import 'list_tile.dart';
import 'radio.dart';
import 'theme.dart';
import 'theme_data.dart';

class RadioListTile<T> extends StatelessWidget {
  const RadioListTile({
    Key key,
    @required this.value,
    @required this.groupValue,
    @required this.onChanged,
    this.activeColor,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
    this.controlAffinity = ListTileControlAffinity.platform,
  })  : assert(isThreeLine != null),
        assert(!isThreeLine || subtitle != null),
        assert(selected != null),
        assert(controlAffinity != null),
        super(key: key);

  final T value;

  final T groupValue;

  final ValueChanged<T> onChanged;

  final Color activeColor;

  final Widget title;

  final Widget subtitle;

  final Widget secondary;

  final bool isThreeLine;

  final bool dense;

  final bool selected;

  final ListTileControlAffinity controlAffinity;

  bool get checked => value == groupValue;

  @override
  Widget build(BuildContext context) {
    final Widget control = Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: activeColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    Widget leading, trailing;
    switch (controlAffinity) {
      case ListTileControlAffinity.leading:
      case ListTileControlAffinity.platform:
        leading = control;
        trailing = secondary;
        break;
      case ListTileControlAffinity.trailing:
        leading = secondary;
        trailing = control;
        break;
    }
    return MergeSemantics(
      child: ListTileTheme.merge(
        selectedColor: activeColor ?? Theme.of(context).accentColor,
        child: ListTile(
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: trailing,
          isThreeLine: isThreeLine,
          dense: dense,
          enabled: onChanged != null,
          onTap: onChanged != null
              ? () {
                  onChanged(value);
                }
              : null,
          selected: selected,
        ),
      ),
    );
  }
}

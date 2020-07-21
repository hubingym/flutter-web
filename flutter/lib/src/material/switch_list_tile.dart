import 'package:flutter_web/widgets.dart';

import 'list_tile.dart';
import 'switch.dart';
import 'theme.dart';
import 'theme_data.dart';

enum _SwitchListTileType { material, adaptive }

class SwitchListTile extends StatelessWidget {
  const SwitchListTile({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
  })  : _switchListTileType = _SwitchListTileType.material,
        assert(value != null),
        assert(isThreeLine != null),
        assert(!isThreeLine || subtitle != null),
        assert(selected != null),
        super(key: key);

  const SwitchListTile.adaptive({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.title,
    this.subtitle,
    this.isThreeLine = false,
    this.dense,
    this.secondary,
    this.selected = false,
  })  : _switchListTileType = _SwitchListTileType.adaptive,
        assert(value != null),
        assert(isThreeLine != null),
        assert(!isThreeLine || subtitle != null),
        assert(selected != null),
        super(key: key);

  final bool value;

  final ValueChanged<bool> onChanged;

  final Color activeColor;

  final Color activeTrackColor;

  final Color inactiveThumbColor;

  final Color inactiveTrackColor;

  final ImageProvider activeThumbImage;

  final ImageProvider inactiveThumbImage;

  final Widget title;

  final Widget subtitle;

  final Widget secondary;

  final bool isThreeLine;

  final bool dense;

  final bool selected;

  final _SwitchListTileType _switchListTileType;

  @override
  Widget build(BuildContext context) {
    Widget control;
    switch (_switchListTileType) {
      case _SwitchListTileType.adaptive:
        control = Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          activeThumbImage: activeThumbImage,
          inactiveThumbImage: inactiveThumbImage,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeTrackColor: activeTrackColor,
          inactiveTrackColor: inactiveTrackColor,
          inactiveThumbColor: inactiveThumbColor,
        );
        break;

      case _SwitchListTileType.material:
        control = Switch(
          value: value,
          onChanged: onChanged,
          activeColor: activeColor,
          activeThumbImage: activeThumbImage,
          inactiveThumbImage: inactiveThumbImage,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeTrackColor: activeTrackColor,
          inactiveTrackColor: inactiveTrackColor,
          inactiveThumbColor: inactiveThumbColor,
        );
    }
    return MergeSemantics(
      child: ListTileTheme.merge(
        selectedColor: activeColor ?? Theme.of(context).accentColor,
        child: ListTile(
          leading: secondary,
          title: title,
          subtitle: subtitle,
          trailing: control,
          isThreeLine: isThreeLine,
          dense: dense,
          enabled: onChanged != null,
          onTap: onChanged != null
              ? () {
                  onChanged(!value);
                }
              : null,
          selected: selected,
        ),
      ),
    );
  }
}

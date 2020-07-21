import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'icons.dart';
import 'list_tile.dart';
import 'theme.dart';
import 'theme_data.dart';

enum MaterialListType {
  oneLine,

  oneLineWithAvatar,

  twoLine,

  threeLine,
}

@deprecated
Map<MaterialListType, double> kListTileExtent =
    const <MaterialListType, double>{
  MaterialListType.oneLine: 48.0,
  MaterialListType.oneLineWithAvatar: 56.0,
  MaterialListType.twoLine: 72.0,
  MaterialListType.threeLine: 88.0,
};

const Duration _kExpand = Duration(milliseconds: 200);

@deprecated
class TwoLevelListItem extends StatelessWidget {
  const TwoLevelListItem(
      {Key key,
      this.leading,
      @required this.title,
      this.trailing,
      this.enabled = true,
      this.onTap,
      this.onLongPress})
      : assert(title != null),
        super(key: key);

  final Widget leading;

  final Widget title;

  final Widget trailing;

  final bool enabled;

  final GestureTapCallback onTap;

  final GestureLongPressCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final TwoLevelList parentList =
        context.ancestorWidgetOfExactType(TwoLevelList);
    assert(parentList != null);

    return SizedBox(
        height: kListTileExtent[parentList.type],
        child: ListTile(
            leading: leading,
            title: title,
            trailing: trailing,
            enabled: enabled,
            onTap: onTap,
            onLongPress: onLongPress));
  }
}

@deprecated
class TwoLevelSublist extends StatefulWidget {
  const TwoLevelSublist({
    Key key,
    this.leading,
    @required this.title,
    this.backgroundColor,
    this.onOpenChanged,
    this.children = const <Widget>[],
  }) : super(key: key);

  final Widget leading;

  final Widget title;

  final ValueChanged<bool> onOpenChanged;

  final List<Widget> children;

  final Color backgroundColor;

  @override
  _TwoLevelSublistState createState() => _TwoLevelSublistState();
}

@deprecated
class _TwoLevelSublistState extends State<TwoLevelSublist>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  CurvedAnimation _easeOutAnimation;
  CurvedAnimation _easeInAnimation;
  ColorTween _borderColor;
  ColorTween _headerColor;
  ColorTween _iconColor;
  ColorTween _backgroundColor;
  Animation<double> _iconTurns;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _kExpand, vsync: this);
    _easeOutAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _easeInAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _borderColor = ColorTween(begin: Colors.transparent);
    _headerColor = ColorTween();
    _iconColor = ColorTween();
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(_easeInAnimation);
    _backgroundColor = ColorTween();

    _isExpanded = PageStorage.of(context)?.readState(context) ?? false;
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleOnTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded)
        _controller.forward();
      else
        _controller.reverse();
      PageStorage.of(context)?.writeState(context, _isExpanded);
    });
    if (widget.onOpenChanged != null) widget.onOpenChanged(_isExpanded);
  }

  Widget buildList(BuildContext context, Widget child) {
    return Container(
        decoration: BoxDecoration(
            color: _backgroundColor.evaluate(_easeOutAnimation),
            border: Border(
                top:
                    BorderSide(color: _borderColor.evaluate(_easeOutAnimation)),
                bottom: BorderSide(
                    color: _borderColor.evaluate(_easeOutAnimation)))),
        child: Column(children: <Widget>[
          IconTheme.merge(
              data: IconThemeData(color: _iconColor.evaluate(_easeInAnimation)),
              child: TwoLevelListItem(
                  onTap: _handleOnTap,
                  leading: widget.leading,
                  title: DefaultTextStyle(
                      style: Theme.of(context).textTheme.subhead.copyWith(
                          color: _headerColor.evaluate(_easeInAnimation)),
                      child: widget.title),
                  trailing: RotationTransition(
                      turns: _iconTurns,
                      child: const Icon(Icons.expand_more)))),
          ClipRect(
              child: Align(
                  heightFactor: _easeInAnimation.value,
                  child: Column(children: widget.children)))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    _borderColor.end = theme.dividerColor;
    _headerColor
      ..begin = theme.textTheme.subhead.color
      ..end = theme.accentColor;
    _iconColor
      ..begin = theme.unselectedWidgetColor
      ..end = theme.accentColor;
    _backgroundColor
      ..begin = Colors.transparent
      ..end = widget.backgroundColor ?? Colors.transparent;

    return AnimatedBuilder(animation: _controller.view, builder: buildList);
  }
}

@deprecated
class TwoLevelList extends StatelessWidget {
  const TwoLevelList({
    Key key,
    this.children = const <Widget>[],
    this.type = MaterialListType.twoLine,
    this.padding,
  })  : assert(type != null),
        super(key: key);

  final List<Widget> children;

  final MaterialListType type;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      shrinkWrap: true,
      children: KeyedSubtree.ensureUniqueKeysForList(children),
    );
  }
}

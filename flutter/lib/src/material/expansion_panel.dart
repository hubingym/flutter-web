import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'expand_icon.dart';
import 'mergeable_material.dart';
import 'theme.dart';

const double _kPanelHeaderCollapsedHeight = 48.0;
const double _kPanelHeaderExpandedHeight = 64.0;

class _SaltedKey<S, V> extends LocalKey {
  const _SaltedKey(this.salt, this.value);

  final S salt;
  final V value;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final _SaltedKey<S, V> typedOther = other;
    return salt == typedOther.salt && value == typedOther.value;
  }

  @override
  int get hashCode => hashValues(runtimeType, salt, value);

  @override
  String toString() {
    final String saltString = S == String ? '<\'$salt\'>' : '<$salt>';
    final String valueString = V == String ? '<\'$value\'>' : '<$value>';
    return '[$saltString $valueString]';
  }
}

typedef ExpansionPanelCallback = void Function(int panelIndex, bool isExpanded);

typedef ExpansionPanelHeaderBuilder = Widget Function(
    BuildContext context, bool isExpanded);

class ExpansionPanel {
  ExpansionPanel(
      {@required this.headerBuilder,
      @required this.body,
      this.isExpanded = false})
      : assert(headerBuilder != null),
        assert(body != null),
        assert(isExpanded != null);

  final ExpansionPanelHeaderBuilder headerBuilder;

  final Widget body;

  final bool isExpanded;
}

class ExpansionPanelRadio extends ExpansionPanel {
  ExpansionPanelRadio({
    @required this.value,
    @required ExpansionPanelHeaderBuilder headerBuilder,
    @required Widget body,
  })  : assert(value != null),
        super(body: body, headerBuilder: headerBuilder);

  final Object value;
}

class ExpansionPanelList extends StatefulWidget {
  const ExpansionPanelList({
    Key key,
    this.children = const <ExpansionPanel>[],
    this.expansionCallback,
    this.animationDuration = kThemeAnimationDuration,
  })  : assert(children != null),
        assert(animationDuration != null),
        _allowOnlyOnePanelOpen = false,
        initialOpenPanelValue = null,
        super(key: key);

  const ExpansionPanelList.radio({
    Key key,
    List<ExpansionPanelRadio> children = const <ExpansionPanelRadio>[],
    this.expansionCallback,
    this.animationDuration = kThemeAnimationDuration,
    this.initialOpenPanelValue,
  })  : children = children,
        assert(children != null),
        assert(animationDuration != null),
        _allowOnlyOnePanelOpen = true,
        super(key: key);

  final List<ExpansionPanel> children;

  final ExpansionPanelCallback expansionCallback;

  final Duration animationDuration;

  final bool _allowOnlyOnePanelOpen;

  final Object initialOpenPanelValue;

  @override
  State<StatefulWidget> createState() => _ExpansionPanelListState();
}

class _ExpansionPanelListState extends State<ExpansionPanelList> {
  ExpansionPanelRadio _currentOpenPanel;

  @override
  void initState() {
    super.initState();
    if (widget._allowOnlyOnePanelOpen) {
      assert(_allIdentifiersUnique(), 'All object identifiers are not unique!');
      for (ExpansionPanelRadio child in widget.children) {
        if (widget.initialOpenPanelValue != null &&
            child.value == widget.initialOpenPanelValue)
          _currentOpenPanel = child;
      }
    }
  }

  @override
  void didUpdateWidget(ExpansionPanelList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._allowOnlyOnePanelOpen) {
      assert(_allIdentifiersUnique(), 'All object identifiers are not unique!');
      for (ExpansionPanelRadio newChild in widget.children) {
        if (widget.initialOpenPanelValue != null &&
            newChild.value == widget.initialOpenPanelValue)
          _currentOpenPanel = newChild;
      }
    } else if (oldWidget._allowOnlyOnePanelOpen) {
      _currentOpenPanel = null;
    }
  }

  bool _allIdentifiersUnique() {
    final Map<Object, bool> identifierMap = <Object, bool>{};
    for (ExpansionPanelRadio child in widget.children) {
      identifierMap[child.value] = true;
    }
    return identifierMap.length == widget.children.length;
  }

  bool _isChildExpanded(int index) {
    if (widget._allowOnlyOnePanelOpen) {
      final ExpansionPanelRadio radioWidget = widget.children[index];
      return _currentOpenPanel?.value == radioWidget.value;
    }
    return widget.children[index].isExpanded;
  }

  void _handlePressed(bool isExpanded, int index) {
    if (widget.expansionCallback != null)
      widget.expansionCallback(index, isExpanded);

    if (widget._allowOnlyOnePanelOpen) {
      final ExpansionPanelRadio pressedChild = widget.children[index];

      for (int childIndex = 0;
          childIndex < widget.children.length;
          childIndex += 1) {
        final ExpansionPanelRadio child = widget.children[childIndex];
        if (widget.expansionCallback != null &&
            childIndex != index &&
            child.value == _currentOpenPanel?.value)
          widget.expansionCallback(childIndex, false);
      }
      _currentOpenPanel = isExpanded ? null : pressedChild;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<MergeableMaterialItem> items = <MergeableMaterialItem>[];
    const EdgeInsets kExpandedEdgeInsets = EdgeInsets.symmetric(
        vertical: _kPanelHeaderExpandedHeight - _kPanelHeaderCollapsedHeight);

    for (int index = 0; index < widget.children.length; index += 1) {
      if (_isChildExpanded(index) && index != 0 && !_isChildExpanded(index - 1))
        items.add(MaterialGap(
            key: _SaltedKey<BuildContext, int>(context, index * 2 - 1)));

      final ExpansionPanel child = widget.children[index];
      final Row header = Row(
        children: <Widget>[
          Expanded(
            child: AnimatedContainer(
              duration: widget.animationDuration,
              curve: Curves.fastOutSlowIn,
              margin: _isChildExpanded(index)
                  ? kExpandedEdgeInsets
                  : EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    minHeight: _kPanelHeaderCollapsedHeight),
                child: child.headerBuilder(
                  context,
                  _isChildExpanded(index),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsetsDirectional.only(end: 8.0),
            child: ExpandIcon(
              isExpanded: _isChildExpanded(index),
              padding: const EdgeInsets.all(16.0),
              onPressed: (bool isExpanded) => _handlePressed(isExpanded, index),
            ),
          ),
        ],
      );

      items.add(
        MaterialSlice(
          key: _SaltedKey<BuildContext, int>(context, index * 2),
          child: Column(
            children: <Widget>[
              MergeSemantics(child: header),
              AnimatedCrossFade(
                firstChild: Container(height: 0.0),
                secondChild: child.body,
                firstCurve:
                    const Interval(0.0, 0.6, curve: Curves.fastOutSlowIn),
                secondCurve:
                    const Interval(0.4, 1.0, curve: Curves.fastOutSlowIn),
                sizeCurve: Curves.fastOutSlowIn,
                crossFadeState: _isChildExpanded(index)
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: widget.animationDuration,
              ),
            ],
          ),
        ),
      );

      if (_isChildExpanded(index) && index != widget.children.length - 1)
        items.add(MaterialGap(
            key: _SaltedKey<BuildContext, int>(context, index * 2 + 1)));
    }

    return MergeableMaterial(
      hasDividers: true,
      children: items,
    );
  }
}

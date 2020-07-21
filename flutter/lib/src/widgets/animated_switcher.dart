import 'package:flutter_web/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

class _AnimatedSwitcherChildEntry {
  _AnimatedSwitcherChildEntry({
    @required this.animation,
    @required this.transition,
    @required this.controller,
    @required this.widgetChild,
  })  : assert(animation != null),
        assert(transition != null),
        assert(controller != null);

  final Animation<double> animation;

  Widget transition;

  final AnimationController controller;

  Widget widgetChild;
}

typedef Widget AnimatedSwitcherTransitionBuilder(
    Widget child, Animation<double> animation);

typedef Widget AnimatedSwitcherLayoutBuilder(
    Widget currentChild, List<Widget> previousChildren);

class AnimatedSwitcher extends StatefulWidget {
  const AnimatedSwitcher({
    Key key,
    this.child,
    @required this.duration,
    this.switchInCurve = Curves.linear,
    this.switchOutCurve = Curves.linear,
    this.transitionBuilder = AnimatedSwitcher.defaultTransitionBuilder,
    this.layoutBuilder = AnimatedSwitcher.defaultLayoutBuilder,
  })  : assert(duration != null),
        assert(switchInCurve != null),
        assert(switchOutCurve != null),
        assert(transitionBuilder != null),
        assert(layoutBuilder != null),
        super(key: key);

  final Widget child;

  final Duration duration;

  final Curve switchInCurve;

  final Curve switchOutCurve;

  final AnimatedSwitcherTransitionBuilder transitionBuilder;

  final AnimatedSwitcherLayoutBuilder layoutBuilder;

  @override
  _AnimatedSwitcherState createState() => new _AnimatedSwitcherState();

  static Widget defaultTransitionBuilder(
      Widget child, Animation<double> animation) {
    return new FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget defaultLayoutBuilder(
      Widget currentChild, List<Widget> previousChildren) {
    List<Widget> children = previousChildren;
    if (currentChild != null) {
      children = children.toList()..add(currentChild);
    }
    return new Stack(
      children: children,
      alignment: Alignment.center,
    );
  }
}

class _AnimatedSwitcherState extends State<AnimatedSwitcher>
    with TickerProviderStateMixin {
  final Set<_AnimatedSwitcherChildEntry> _previousChildren =
      new Set<_AnimatedSwitcherChildEntry>();
  _AnimatedSwitcherChildEntry _currentChild;
  List<Widget> _previousChildWidgetCache = const <Widget>[];
  int serialNumber = 0;

  @override
  void initState() {
    super.initState();
    _addEntry(animate: false);
  }

  _AnimatedSwitcherChildEntry _newEntry({
    @required AnimationController controller,
    @required Animation<double> animation,
  }) {
    final _AnimatedSwitcherChildEntry entry = new _AnimatedSwitcherChildEntry(
      widgetChild: widget.child,
      transition: new KeyedSubtree.wrap(
        widget.transitionBuilder(
          widget.child,
          animation,
        ),
        serialNumber++,
      ),
      animation: animation,
      controller: controller,
    );
    animation.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          _removeExpiredChild(entry);
        });
        controller.dispose();
      }
    });
    return entry;
  }

  void _removeExpiredChild(_AnimatedSwitcherChildEntry child) {
    assert(_previousChildren.contains(child));
    _previousChildren.remove(child);
    _markChildWidgetCacheAsDirty();
  }

  void _retireCurrentChild() {
    assert(!_previousChildren.contains(_currentChild));
    _currentChild.controller.reverse();
    _previousChildren.add(_currentChild);
    _markChildWidgetCacheAsDirty();
  }

  void _markChildWidgetCacheAsDirty() {
    _previousChildWidgetCache = null;
  }

  void _addEntry({@required bool animate}) {
    if (widget.child == null) {
      if (animate && _currentChild != null) {
        _retireCurrentChild();
      }
      _currentChild = null;
      return;
    }
    final AnimationController controller = new AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    if (animate) {
      if (_currentChild != null) {
        _retireCurrentChild();
      }
      controller.forward();
    } else {
      assert(_currentChild == null);
      assert(_previousChildren.isEmpty);
      controller.value = 1.0;
    }
    final Animation<double> animation = new CurvedAnimation(
      parent: controller,
      curve: widget.switchInCurve,
      reverseCurve: widget.switchOutCurve,
    );
    _currentChild = _newEntry(controller: controller, animation: animation);
  }

  @override
  void dispose() {
    if (_currentChild != null) {
      _currentChild.controller.dispose();
    }
    for (_AnimatedSwitcherChildEntry child in _previousChildren) {
      child.controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    void updateTransition(_AnimatedSwitcherChildEntry entry) {
      entry.transition = new KeyedSubtree(
        key: entry.transition.key,
        child: widget.transitionBuilder(entry.widgetChild, entry.animation),
      );
    }

    if (widget.transitionBuilder != oldWidget.transitionBuilder) {
      _previousChildren.forEach(updateTransition);
      if (_currentChild != null) {
        updateTransition(_currentChild);
      }
      _markChildWidgetCacheAsDirty();
    }

    final bool hasNewChild = widget.child != null;
    final bool hasOldChild = _currentChild != null;
    if (hasNewChild != hasOldChild ||
        hasNewChild &&
            !Widget.canUpdate(widget.child, _currentChild.widgetChild)) {
      _addEntry(animate: true);
    } else {
      if (_currentChild != null) {
        _currentChild.widgetChild = widget.child;
        updateTransition(_currentChild);
        _markChildWidgetCacheAsDirty();
      }
    }
  }

  void _rebuildChildWidgetCacheIfNeeded() {
    _previousChildWidgetCache ??= new List<Widget>.unmodifiable(
      _previousChildren.map<Widget>((_AnimatedSwitcherChildEntry child) {
        return child.transition;
      }),
    );
    assert(_previousChildren.length == _previousChildWidgetCache.length);
    assert(_previousChildren.isEmpty ||
        _previousChildren.last.transition == _previousChildWidgetCache.last);
  }

  @override
  Widget build(BuildContext context) {
    _rebuildChildWidgetCacheIfNeeded();
    return widget.layoutBuilder(
        _currentChild?.transition, _previousChildWidgetCache);
  }
}

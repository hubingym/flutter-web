import 'package:collection/collection.dart' show binarySearch;

import 'package:flutter_web/animation.dart';

import 'basic.dart';
import 'framework.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scroll_view.dart';
import 'ticker_provider.dart';

typedef AnimatedListItemBuilder = Widget Function(
    BuildContext context, int index, Animation<double> animation);

typedef AnimatedListRemovedItemBuilder = Widget Function(
    BuildContext context, Animation<double> animation);

const Duration _kDuration = Duration(milliseconds: 300);

class _ActiveItem implements Comparable<_ActiveItem> {
  _ActiveItem.incoming(this.controller, this.itemIndex)
      : removedItemBuilder = null;
  _ActiveItem.outgoing(
      this.controller, this.itemIndex, this.removedItemBuilder);
  _ActiveItem.index(this.itemIndex)
      : controller = null,
        removedItemBuilder = null;

  final AnimationController controller;
  final AnimatedListRemovedItemBuilder removedItemBuilder;
  int itemIndex;

  @override
  int compareTo(_ActiveItem other) => itemIndex - other.itemIndex;
}

class AnimatedList extends StatefulWidget {
  const AnimatedList({
    Key key,
    @required this.itemBuilder,
    this.initialItemCount = 0,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  })  : assert(itemBuilder != null),
        assert(initialItemCount != null && initialItemCount >= 0),
        super(key: key);

  final AnimatedListItemBuilder itemBuilder;

  final int initialItemCount;

  final Axis scrollDirection;

  final bool reverse;

  final ScrollController controller;

  final bool primary;

  final ScrollPhysics physics;

  final bool shrinkWrap;

  final EdgeInsetsGeometry padding;

  static AnimatedListState of(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    assert(nullOk != null);
    final AnimatedListState result =
        context.ancestorStateOfType(const TypeMatcher<AnimatedListState>());
    if (nullOk || result != null) return result;
    throw FlutterError(
        'AnimatedList.of() called with a context that does not contain an AnimatedList.\n'
        'No AnimatedList ancestor could be found starting from the context that was passed to AnimatedList.of(). '
        'This can happen when the context provided is from the same StatefulWidget that '
        'built the AnimatedList. Please see the AnimatedList documentation for examples '
        'of how to refer to an AnimatedListState object: '
        '  https://docs.flutter.io/flutter/widgets/AnimatedListState-class.html \n'
        'The context used was:\n'
        '  $context');
  }

  @override
  AnimatedListState createState() => AnimatedListState();
}

class AnimatedListState extends State<AnimatedList>
    with TickerProviderStateMixin<AnimatedList> {
  final List<_ActiveItem> _incomingItems = <_ActiveItem>[];
  final List<_ActiveItem> _outgoingItems = <_ActiveItem>[];
  int _itemsCount = 0;

  @override
  void initState() {
    super.initState();
    _itemsCount = widget.initialItemCount;
  }

  @override
  void dispose() {
    for (_ActiveItem item in _incomingItems) item.controller.dispose();
    for (_ActiveItem item in _outgoingItems) item.controller.dispose();
    super.dispose();
  }

  _ActiveItem _removeActiveItemAt(List<_ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, _ActiveItem.index(itemIndex));
    return i == -1 ? null : items.removeAt(i);
  }

  _ActiveItem _activeItemAt(List<_ActiveItem> items, int itemIndex) {
    final int i = binarySearch(items, _ActiveItem.index(itemIndex));
    return i == -1 ? null : items[i];
  }

  int _indexToItemIndex(int index) {
    int itemIndex = index;
    for (_ActiveItem item in _outgoingItems) {
      if (item.itemIndex <= itemIndex)
        itemIndex += 1;
      else
        break;
    }
    return itemIndex;
  }

  int _itemIndexToIndex(int itemIndex) {
    int index = itemIndex;
    for (_ActiveItem item in _outgoingItems) {
      assert(item.itemIndex != itemIndex);
      if (item.itemIndex < itemIndex)
        index -= 1;
      else
        break;
    }
    return index;
  }

  void insertItem(int index, {Duration duration = _kDuration}) {
    assert(index != null && index >= 0);
    assert(duration != null);

    final int itemIndex = _indexToItemIndex(index);
    assert(itemIndex >= 0 && itemIndex <= _itemsCount);

    for (_ActiveItem item in _incomingItems) {
      if (item.itemIndex >= itemIndex) item.itemIndex += 1;
    }
    for (_ActiveItem item in _outgoingItems) {
      if (item.itemIndex >= itemIndex) item.itemIndex += 1;
    }

    final AnimationController controller =
        AnimationController(duration: duration, vsync: this);
    final _ActiveItem incomingItem =
        _ActiveItem.incoming(controller, itemIndex);
    setState(() {
      _incomingItems
        ..add(incomingItem)
        ..sort();
      _itemsCount += 1;
    });

    controller.forward().then<void>((_) {
      _removeActiveItemAt(_incomingItems, incomingItem.itemIndex)
          .controller
          .dispose();
    });
  }

  void removeItem(int index, AnimatedListRemovedItemBuilder builder,
      {Duration duration = _kDuration}) {
    assert(index != null && index >= 0);
    assert(builder != null);
    assert(duration != null);

    final int itemIndex = _indexToItemIndex(index);
    assert(itemIndex >= 0 && itemIndex < _itemsCount);
    assert(_activeItemAt(_outgoingItems, itemIndex) == null);

    final _ActiveItem incomingItem =
        _removeActiveItemAt(_incomingItems, itemIndex);
    final AnimationController controller = incomingItem?.controller ??
        AnimationController(duration: duration, value: 1.0, vsync: this);
    final _ActiveItem outgoingItem =
        _ActiveItem.outgoing(controller, itemIndex, builder);
    setState(() {
      _outgoingItems
        ..add(outgoingItem)
        ..sort();
    });

    controller.reverse().then<void>((void value) {
      _removeActiveItemAt(_outgoingItems, outgoingItem.itemIndex)
          .controller
          .dispose();

      for (_ActiveItem item in _incomingItems) {
        if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
      }
      for (_ActiveItem item in _outgoingItems) {
        if (item.itemIndex > outgoingItem.itemIndex) item.itemIndex -= 1;
      }

      setState(() {
        _itemsCount -= 1;
      });
    });
  }

  Widget _itemBuilder(BuildContext context, int itemIndex) {
    final _ActiveItem outgoingItem = _activeItemAt(_outgoingItems, itemIndex);
    if (outgoingItem != null)
      return outgoingItem.removedItemBuilder(
          context, outgoingItem.controller.view);

    final _ActiveItem incomingItem = _activeItemAt(_incomingItems, itemIndex);
    final Animation<double> animation =
        incomingItem?.controller?.view ?? kAlwaysCompleteAnimation;
    return widget.itemBuilder(context, _itemIndexToIndex(itemIndex), animation);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: _itemBuilder,
      itemCount: _itemsCount,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
    );
  }
}

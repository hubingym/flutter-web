import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/physics.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_context.dart';
import 'scroll_controller.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_position_with_single_context.dart';
import 'scrollable.dart';

abstract class ListWheelChildDelegate {
  Widget build(BuildContext context, int index);

  int get estimatedChildCount;

  int trueIndexOf(int index) => index;

  bool shouldRebuild(covariant ListWheelChildDelegate oldDelegate);
}

class ListWheelChildListDelegate extends ListWheelChildDelegate {
  ListWheelChildListDelegate({@required this.children})
      : assert(children != null);

  final List<Widget> children;

  @override
  int get estimatedChildCount => children.length;

  @override
  Widget build(BuildContext context, int index) {
    if (index < 0 || index >= children.length) return null;
    return IndexedSemantics(child: children[index], index: index);
  }

  @override
  bool shouldRebuild(covariant ListWheelChildListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }
}

class ListWheelChildLoopingListDelegate extends ListWheelChildDelegate {
  ListWheelChildLoopingListDelegate({@required this.children})
      : assert(children != null);

  final List<Widget> children;

  @override
  int get estimatedChildCount => null;

  @override
  int trueIndexOf(int index) => index % children.length;

  @override
  Widget build(BuildContext context, int index) {
    if (children.isEmpty) return null;
    return IndexedSemantics(
        child: children[index % children.length], index: index);
  }

  @override
  bool shouldRebuild(covariant ListWheelChildLoopingListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }
}

class ListWheelChildBuilderDelegate extends ListWheelChildDelegate {
  ListWheelChildBuilderDelegate({
    @required this.builder,
    this.childCount,
  }) : assert(builder != null);

  final IndexedWidgetBuilder builder;

  final int childCount;

  @override
  int get estimatedChildCount => childCount;

  @override
  Widget build(BuildContext context, int index) {
    if (childCount == null) {
      final Widget child = builder(context, index);
      return child == null
          ? null
          : IndexedSemantics(child: child, index: index);
    }
    if (index < 0 || index >= childCount) return null;
    return IndexedSemantics(child: builder(context, index), index: index);
  }

  @override
  bool shouldRebuild(covariant ListWheelChildBuilderDelegate oldDelegate) {
    return builder != oldDelegate.builder ||
        childCount != oldDelegate.childCount;
  }
}

class FixedExtentScrollController extends ScrollController {
  FixedExtentScrollController({
    this.initialItem = 0,
  }) : assert(initialItem != null);

  final int initialItem;

  int get selectedItem {
    assert(
      positions.isNotEmpty,
      'FixedExtentScrollController.selectedItem cannot be accessed before a '
      'scroll view is built with it.',
    );
    assert(
      positions.length == 1,
      'The selectedItem property cannot be read when multiple scroll views are '
      'attached to the same FixedExtentScrollController.',
    );
    final _FixedExtentScrollPosition position = this.position;
    return position.itemIndex;
  }

  Future<void> animateToItem(
    int itemIndex, {
    @required Duration duration,
    @required Curve curve,
  }) async {
    if (!hasClients) {
      return;
    }

    final List<Future<void>> futures = <Future<void>>[];
    for (_FixedExtentScrollPosition position in positions) {
      futures.add(position.animateTo(
        itemIndex * position.itemExtent,
        duration: duration,
        curve: curve,
      ));
    }
    await Future.wait<void>(futures);
  }

  void jumpToItem(int itemIndex) {
    for (_FixedExtentScrollPosition position in positions) {
      position.jumpTo(itemIndex * position.itemExtent);
    }
  }

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition oldPosition) {
    return _FixedExtentScrollPosition(
      physics: physics,
      context: context,
      initialItem: initialItem,
      oldPosition: oldPosition,
    );
  }
}

class FixedExtentMetrics extends FixedScrollMetrics {
  FixedExtentMetrics({
    @required double minScrollExtent,
    @required double maxScrollExtent,
    @required double pixels,
    @required double viewportDimension,
    @required AxisDirection axisDirection,
    @required this.itemIndex,
  }) : super(
          minScrollExtent: minScrollExtent,
          maxScrollExtent: maxScrollExtent,
          pixels: pixels,
          viewportDimension: viewportDimension,
          axisDirection: axisDirection,
        );

  @override
  FixedExtentMetrics copyWith({
    double minScrollExtent,
    double maxScrollExtent,
    double pixels,
    double viewportDimension,
    AxisDirection axisDirection,
    int itemIndex,
  }) {
    return FixedExtentMetrics(
      minScrollExtent: minScrollExtent ?? this.minScrollExtent,
      maxScrollExtent: maxScrollExtent ?? this.maxScrollExtent,
      pixels: pixels ?? this.pixels,
      viewportDimension: viewportDimension ?? this.viewportDimension,
      axisDirection: axisDirection ?? this.axisDirection,
      itemIndex: itemIndex ?? this.itemIndex,
    );
  }

  final int itemIndex;
}

int _getItemFromOffset({
  double offset,
  double itemExtent,
  double minScrollExtent,
  double maxScrollExtent,
}) {
  return (_clipOffsetToScrollableRange(
              offset, minScrollExtent, maxScrollExtent) /
          itemExtent)
      .round();
}

double _clipOffsetToScrollableRange(
  double offset,
  double minScrollExtent,
  double maxScrollExtent,
) {
  return math.min(math.max(offset, minScrollExtent), maxScrollExtent);
}

class _FixedExtentScrollPosition extends ScrollPositionWithSingleContext
    implements FixedExtentMetrics {
  _FixedExtentScrollPosition({
    @required ScrollPhysics physics,
    @required ScrollContext context,
    @required int initialItem,
    bool keepScrollOffset = true,
    ScrollPosition oldPosition,
    String debugLabel,
  })  : assert(context is _FixedExtentScrollableState,
            'FixedExtentScrollController can only be used with ListWheelScrollViews'),
        super(
          physics: physics,
          context: context,
          initialPixels: _getItemExtentFromScrollContext(context) * initialItem,
          keepScrollOffset: keepScrollOffset,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  static double _getItemExtentFromScrollContext(ScrollContext context) {
    final _FixedExtentScrollableState scrollable = context;
    return scrollable.itemExtent;
  }

  double get itemExtent => _getItemExtentFromScrollContext(context);

  @override
  int get itemIndex {
    return _getItemFromOffset(
      offset: pixels,
      itemExtent: itemExtent,
      minScrollExtent: minScrollExtent,
      maxScrollExtent: maxScrollExtent,
    );
  }

  @override
  FixedExtentMetrics copyWith({
    double minScrollExtent,
    double maxScrollExtent,
    double pixels,
    double viewportDimension,
    AxisDirection axisDirection,
    int itemIndex,
  }) {
    return FixedExtentMetrics(
      minScrollExtent: minScrollExtent ?? this.minScrollExtent,
      maxScrollExtent: maxScrollExtent ?? this.maxScrollExtent,
      pixels: pixels ?? this.pixels,
      viewportDimension: viewportDimension ?? this.viewportDimension,
      axisDirection: axisDirection ?? this.axisDirection,
      itemIndex: itemIndex ?? this.itemIndex,
    );
  }
}

class _FixedExtentScrollable extends Scrollable {
  const _FixedExtentScrollable({
    Key key,
    AxisDirection axisDirection = AxisDirection.down,
    ScrollController controller,
    ScrollPhysics physics,
    @required this.itemExtent,
    @required ViewportBuilder viewportBuilder,
  }) : super(
          key: key,
          axisDirection: axisDirection,
          controller: controller,
          physics: physics,
          viewportBuilder: viewportBuilder,
        );

  final double itemExtent;

  @override
  _FixedExtentScrollableState createState() => _FixedExtentScrollableState();
}

class _FixedExtentScrollableState extends ScrollableState {
  double get itemExtent {
    final _FixedExtentScrollable actualWidget = widget;
    return actualWidget.itemExtent;
  }
}

class FixedExtentScrollPhysics extends ScrollPhysics {
  const FixedExtentScrollPhysics({ScrollPhysics parent})
      : super(parent: parent);

  @override
  FixedExtentScrollPhysics applyTo(ScrollPhysics ancestor) {
    return FixedExtentScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    assert(
        position is _FixedExtentScrollPosition,
        'FixedExtentScrollPhysics can only be used with Scrollables that uses '
        'the FixedExtentScrollController');

    final _FixedExtentScrollPosition metrics = position;

    if ((velocity <= 0.0 && metrics.pixels <= metrics.minScrollExtent) ||
        (velocity >= 0.0 && metrics.pixels >= metrics.maxScrollExtent)) {
      return super.createBallisticSimulation(metrics, velocity);
    }

    final Simulation testFrictionSimulation =
        super.createBallisticSimulation(metrics, velocity);

    if (testFrictionSimulation != null &&
        (testFrictionSimulation.x(double.infinity) == metrics.minScrollExtent ||
            testFrictionSimulation.x(double.infinity) ==
                metrics.maxScrollExtent)) {
      return super.createBallisticSimulation(metrics, velocity);
    }

    final int settlingItemIndex = _getItemFromOffset(
      offset: testFrictionSimulation?.x(double.infinity) ?? metrics.pixels,
      itemExtent: metrics.itemExtent,
      minScrollExtent: metrics.minScrollExtent,
      maxScrollExtent: metrics.maxScrollExtent,
    );

    final double settlingPixels = settlingItemIndex * metrics.itemExtent;

    if (velocity.abs() < tolerance.velocity &&
        (settlingPixels - metrics.pixels).abs() < tolerance.distance) {
      return null;
    }

    if (settlingItemIndex == metrics.itemIndex) {
      return SpringSimulation(
        spring,
        metrics.pixels,
        settlingPixels,
        velocity,
        tolerance: tolerance,
      );
    }

    return FrictionSimulation.through(
      metrics.pixels,
      settlingPixels,
      velocity,
      tolerance.velocity * velocity.sign,
    );
  }
}

class ListWheelScrollView extends StatefulWidget {
  ListWheelScrollView({
    Key key,
    this.controller,
    this.physics,
    this.diameterRatio = RenderListWheelViewport.defaultDiameterRatio,
    this.perspective = RenderListWheelViewport.defaultPerspective,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    @required this.itemExtent,
    this.squeeze = 1.0,
    this.onSelectedItemChanged,
    this.clipToSize = true,
    this.renderChildrenOutsideViewport = false,
    @required List<Widget> children,
  })  : assert(children != null),
        assert(diameterRatio != null),
        assert(diameterRatio > 0.0,
            RenderListWheelViewport.diameterRatioZeroMessage),
        assert(perspective != null),
        assert(perspective > 0),
        assert(perspective <= 0.01,
            RenderListWheelViewport.perspectiveTooHighMessage),
        assert(magnification > 0),
        assert(itemExtent != null),
        assert(itemExtent > 0),
        assert(squeeze != null),
        assert(squeeze > 0),
        assert(clipToSize != null),
        assert(renderChildrenOutsideViewport != null),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          RenderListWheelViewport
              .clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        childDelegate = ListWheelChildListDelegate(children: children),
        super(key: key);

  const ListWheelScrollView.useDelegate({
    Key key,
    this.controller,
    this.physics,
    this.diameterRatio = RenderListWheelViewport.defaultDiameterRatio,
    this.perspective = RenderListWheelViewport.defaultPerspective,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    @required this.itemExtent,
    this.squeeze = 1.0,
    this.onSelectedItemChanged,
    this.clipToSize = true,
    this.renderChildrenOutsideViewport = false,
    @required this.childDelegate,
  })  : assert(childDelegate != null),
        assert(diameterRatio != null),
        assert(diameterRatio > 0.0,
            RenderListWheelViewport.diameterRatioZeroMessage),
        assert(perspective != null),
        assert(perspective > 0),
        assert(perspective <= 0.01,
            RenderListWheelViewport.perspectiveTooHighMessage),
        assert(magnification > 0),
        assert(itemExtent != null),
        assert(itemExtent > 0),
        assert(squeeze != null),
        assert(squeeze > 0),
        assert(clipToSize != null),
        assert(renderChildrenOutsideViewport != null),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          RenderListWheelViewport
              .clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        super(key: key);

  final ScrollController controller;

  final ScrollPhysics physics;

  final double diameterRatio;

  final double perspective;

  final double offAxisFraction;

  final bool useMagnifier;

  final double magnification;

  final double itemExtent;

  final double squeeze;

  final ValueChanged<int> onSelectedItemChanged;

  final bool clipToSize;

  final bool renderChildrenOutsideViewport;

  final ListWheelChildDelegate childDelegate;

  @override
  _ListWheelScrollViewState createState() => _ListWheelScrollViewState();
}

class _ListWheelScrollViewState extends State<ListWheelScrollView> {
  int _lastReportedItemIndex = 0;
  ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = widget.controller ?? FixedExtentScrollController();
    if (widget.controller is FixedExtentScrollController) {
      final FixedExtentScrollController controller = widget.controller;
      _lastReportedItemIndex = controller.initialItem;
    }
  }

  @override
  void didUpdateWidget(ListWheelScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != scrollController) {
      final ScrollController oldScrollController = scrollController;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        oldScrollController.dispose();
      });
      scrollController = widget.controller;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.depth == 0 &&
            widget.onSelectedItemChanged != null &&
            notification is ScrollUpdateNotification &&
            notification.metrics is FixedExtentMetrics) {
          final FixedExtentMetrics metrics = notification.metrics;
          final int currentItemIndex = metrics.itemIndex;
          if (currentItemIndex != _lastReportedItemIndex) {
            _lastReportedItemIndex = currentItemIndex;
            final int trueIndex =
                widget.childDelegate.trueIndexOf(currentItemIndex);
            widget.onSelectedItemChanged(trueIndex);
          }
        }
        return false;
      },
      child: _FixedExtentScrollable(
        controller: scrollController,
        physics: widget.physics,
        itemExtent: widget.itemExtent,
        viewportBuilder: (BuildContext context, ViewportOffset offset) {
          return ListWheelViewport(
            diameterRatio: widget.diameterRatio,
            perspective: widget.perspective,
            offAxisFraction: widget.offAxisFraction,
            useMagnifier: widget.useMagnifier,
            magnification: widget.magnification,
            itemExtent: widget.itemExtent,
            squeeze: widget.squeeze,
            clipToSize: widget.clipToSize,
            renderChildrenOutsideViewport: widget.renderChildrenOutsideViewport,
            offset: offset,
            childDelegate: widget.childDelegate,
          );
        },
      ),
    );
  }
}

class ListWheelElement extends RenderObjectElement
    implements ListWheelChildManager {
  ListWheelElement(ListWheelViewport widget) : super(widget);

  @override
  ListWheelViewport get widget => super.widget;

  @override
  RenderListWheelViewport get renderObject => super.renderObject;

  final Map<int, Widget> _childWidgets = HashMap<int, Widget>();

  final SplayTreeMap<int, Element> _childElements =
      SplayTreeMap<int, Element>();

  @override
  void update(ListWheelViewport newWidget) {
    final ListWheelViewport oldWidget = widget;
    super.update(newWidget);
    final ListWheelChildDelegate newDelegate = newWidget.childDelegate;
    final ListWheelChildDelegate oldDelegate = oldWidget.childDelegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType ||
            newDelegate.shouldRebuild(oldDelegate))) performRebuild();
  }

  @override
  int get childCount => widget.childDelegate.estimatedChildCount;

  @override
  void performRebuild() {
    _childWidgets.clear();
    super.performRebuild();
    if (_childElements.isEmpty) return;

    final int firstIndex = _childElements.firstKey();
    final int lastIndex = _childElements.lastKey();

    for (int index = firstIndex; index <= lastIndex; ++index) {
      final Element newChild =
          updateChild(_childElements[index], retrieveWidget(index), index);
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    }
  }

  Widget retrieveWidget(int index) {
    return _childWidgets.putIfAbsent(
        index, () => widget.childDelegate.build(this, index));
  }

  @override
  bool childExistsAt(int index) => retrieveWidget(index) != null;

  @override
  void createChild(int index, {@required RenderBox after}) {
    owner.buildScope(this, () {
      final bool insertFirst = after == null;
      assert(insertFirst || _childElements[index - 1] != null);
      final Element newChild =
          updateChild(_childElements[index], retrieveWidget(index), index);
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
  }

  @override
  void removeChild(RenderBox child) {
    final int index = renderObject.indexOf(child);
    owner.buildScope(this, () {
      assert(_childElements.containsKey(index));
      final Element result = updateChild(_childElements[index], null, index);
      assert(result == null);
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  @override
  Element updateChild(Element child, Widget newWidget, dynamic newSlot) {
    final ListWheelParentData oldParentData = child?.renderObject?.parentData;
    final Element newChild = super.updateChild(child, newWidget, newSlot);
    final ListWheelParentData newParentData =
        newChild?.renderObject?.parentData;
    if (newParentData != null) {
      newParentData.index = newSlot;
      if (oldParentData != null) newParentData.offset = oldParentData.offset;
    }

    return newChild;
  }

  @override
  void insertChildRenderObject(RenderObject child, int slot) {
    final RenderListWheelViewport renderObject = this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: _childElements[slot - 1]?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    const String moveChildRenderObjectErrorMessage =
        'Currently we maintain the list in contiguous increasing order, so '
        'moving children around is not allowed.';
    assert(false, moveChildRenderObjectErrorMessage);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(child.parent == renderObject);
    renderObject.remove(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    _childElements.forEach((int key, Element child) {
      visitor(child);
    });
  }

  @override
  void forgetChild(Element child) {
    _childElements.remove(child.slot);
  }
}

class ListWheelViewport extends RenderObjectWidget {
  const ListWheelViewport({
    Key key,
    this.diameterRatio = RenderListWheelViewport.defaultDiameterRatio,
    this.perspective = RenderListWheelViewport.defaultPerspective,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    @required this.itemExtent,
    this.squeeze = 1.0,
    this.clipToSize = true,
    this.renderChildrenOutsideViewport = false,
    @required this.offset,
    @required this.childDelegate,
  })  : assert(childDelegate != null),
        assert(offset != null),
        assert(diameterRatio != null),
        assert(diameterRatio > 0,
            RenderListWheelViewport.diameterRatioZeroMessage),
        assert(perspective != null),
        assert(perspective > 0),
        assert(perspective <= 0.01,
            RenderListWheelViewport.perspectiveTooHighMessage),
        assert(itemExtent != null),
        assert(itemExtent > 0),
        assert(squeeze != null),
        assert(squeeze > 0),
        assert(clipToSize != null),
        assert(renderChildrenOutsideViewport != null),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          RenderListWheelViewport
              .clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        super(key: key);

  final double diameterRatio;

  final double perspective;

  final double offAxisFraction;

  final bool useMagnifier;

  final double magnification;

  final double itemExtent;

  final double squeeze;

  final bool clipToSize;

  final bool renderChildrenOutsideViewport;

  final ViewportOffset offset;

  final ListWheelChildDelegate childDelegate;

  @override
  ListWheelElement createElement() => ListWheelElement(this);

  @override
  RenderListWheelViewport createRenderObject(BuildContext context) {
    final ListWheelElement childManager = context;
    return RenderListWheelViewport(
      childManager: childManager,
      offset: offset,
      diameterRatio: diameterRatio,
      perspective: perspective,
      offAxisFraction: offAxisFraction,
      useMagnifier: useMagnifier,
      magnification: magnification,
      itemExtent: itemExtent,
      squeeze: squeeze,
      clipToSize: clipToSize,
      renderChildrenOutsideViewport: renderChildrenOutsideViewport,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderListWheelViewport renderObject) {
    renderObject
      ..offset = offset
      ..diameterRatio = diameterRatio
      ..perspective = perspective
      ..offAxisFraction = offAxisFraction
      ..useMagnifier = useMagnifier
      ..magnification = magnification
      ..itemExtent = itemExtent
      ..squeeze = squeeze
      ..clipToSize = clipToSize
      ..renderChildrenOutsideViewport = renderChildrenOutsideViewport;
  }
}

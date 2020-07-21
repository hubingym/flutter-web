import 'dart:math';

import 'package:flutter_web/widgets.dart';
import 'package:flutter_web/rendering.dart';

import 'debug.dart';
import 'material.dart';
import 'material_localizations.dart';

typedef ReorderCallback = void Function(int oldIndex, int newIndex);

class ReorderableListView extends StatefulWidget {
  ReorderableListView({
    this.header,
    @required this.children,
    @required this.onReorder,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.reverse = false,
  })  : assert(scrollDirection != null),
        assert(onReorder != null),
        assert(children != null),
        assert(
          children.every((Widget w) => w.key != null),
          'All children of this widget must have a key.',
        );

  final Widget header;

  final List<Widget> children;

  final Axis scrollDirection;

  final EdgeInsets padding;

  final bool reverse;

  final ReorderCallback onReorder;

  @override
  _ReorderableListViewState createState() => _ReorderableListViewState();
}

class _ReorderableListViewState extends State<ReorderableListView> {
  final GlobalKey _overlayKey =
      GlobalKey(debugLabel: '$ReorderableListView overlay key');

  OverlayEntry _listOverlayEntry;

  @override
  void initState() {
    super.initState();
    _listOverlayEntry = OverlayEntry(
      opaque: true,
      builder: (BuildContext context) {
        return _ReorderableListContent(
          header: widget.header,
          children: widget.children,
          scrollDirection: widget.scrollDirection,
          onReorder: widget.onReorder,
          padding: widget.padding,
          reverse: widget.reverse,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(key: _overlayKey, initialEntries: <OverlayEntry>[
      _listOverlayEntry,
    ]);
  }
}

class _ReorderableListContent extends StatefulWidget {
  const _ReorderableListContent({
    @required this.header,
    @required this.children,
    @required this.scrollDirection,
    @required this.padding,
    @required this.onReorder,
    @required this.reverse,
  });

  final Widget header;
  final List<Widget> children;
  final Axis scrollDirection;
  final EdgeInsets padding;
  final ReorderCallback onReorder;
  final bool reverse;

  @override
  _ReorderableListContentState createState() => _ReorderableListContentState();
}

class _ReorderableListContentState extends State<_ReorderableListContent>
    with TickerProviderStateMixin<_ReorderableListContent> {
  static const double _defaultDropAreaExtent = 100.0;

  static const double _dropAreaMargin = 8.0;

  static const Duration _reorderAnimationDuration = Duration(milliseconds: 200);

  static const Duration _scrollAnimationDuration = Duration(milliseconds: 200);

  ScrollController _scrollController;

  AnimationController _entranceController;

  AnimationController _ghostController;

  Key _dragging;

  Size _draggingFeedbackSize;

  int _dragStartIndex = 0;

  int _ghostIndex = 0;

  int _currentIndex = 0;

  int _nextIndex = 0;

  bool _scrolling = false;

  double get _dropAreaExtent {
    if (_draggingFeedbackSize == null) {
      return _defaultDropAreaExtent;
    }
    double dropAreaWithoutMargin;
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        dropAreaWithoutMargin = _draggingFeedbackSize.width;
        break;
      case Axis.vertical:
      default:
        dropAreaWithoutMargin = _draggingFeedbackSize.height;
        break;
    }
    return dropAreaWithoutMargin + _dropAreaMargin;
  }

  @override
  void initState() {
    super.initState();
    _entranceController =
        AnimationController(vsync: this, duration: _reorderAnimationDuration);
    _ghostController =
        AnimationController(vsync: this, duration: _reorderAnimationDuration);
    _entranceController.addStatusListener(_onEntranceStatusChanged);
  }

  @override
  void didChangeDependencies() {
    _scrollController =
        PrimaryScrollController.of(context) ?? ScrollController();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ghostController.dispose();
    super.dispose();
  }

  void _requestAnimationToNextIndex() {
    if (_entranceController.isCompleted) {
      _ghostIndex = _currentIndex;
      if (_nextIndex == _currentIndex) {
        return;
      }
      _currentIndex = _nextIndex;
      _ghostController.reverse(from: 1.0);
      _entranceController.forward(from: 0.0);
    }
  }

  void _onEntranceStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        _requestAnimationToNextIndex();
      });
    }
  }

  void _scrollTo(BuildContext context) {
    if (_scrolling) return;
    final RenderObject contextObject = context.findRenderObject();
    final RenderAbstractViewport viewport =
        RenderAbstractViewport.of(contextObject);
    assert(viewport != null);

    final double margin = _dropAreaExtent;
    final double scrollOffset = _scrollController.offset;
    final double topOffset = max(
      _scrollController.position.minScrollExtent,
      viewport.getOffsetToReveal(contextObject, 0.0).offset - margin,
    );
    final double bottomOffset = min(
      _scrollController.position.maxScrollExtent,
      viewport.getOffsetToReveal(contextObject, 1.0).offset + margin,
    );
    final bool onScreen =
        scrollOffset <= topOffset && scrollOffset >= bottomOffset;

    if (!onScreen) {
      _scrolling = true;
      _scrollController.position
          .animateTo(
        scrollOffset < bottomOffset ? bottomOffset : topOffset,
        duration: _scrollAnimationDuration,
        curve: Curves.easeInOut,
      )
          .then((void value) {
        setState(() {
          _scrolling = false;
        });
      });
    }
  }

  Widget _buildContainerForScrollDirection({List<Widget> children}) {
    switch (widget.scrollDirection) {
      case Axis.horizontal:
        return Row(children: children);
      case Axis.vertical:
      default:
        return Column(children: children);
    }
  }

  Widget _wrap(Widget toWrap, int index, BoxConstraints constraints) {
    assert(toWrap.key != null);
    final GlobalObjectKey keyIndexGlobalKey = GlobalObjectKey(toWrap.key);

    void onDragStarted() {
      setState(() {
        _dragging = toWrap.key;
        _dragStartIndex = index;
        _ghostIndex = index;
        _currentIndex = index;
        _entranceController.value = 1.0;
        _draggingFeedbackSize = keyIndexGlobalKey.currentContext.size;
      });
    }

    void reorder(int startIndex, int endIndex) {
      setState(() {
        if (startIndex != endIndex) widget.onReorder(startIndex, endIndex);

        _ghostController.reverse(from: 0.1);
        _entranceController.reverse(from: 0.1);
        _dragging = null;
      });
    }

    void onDragEnded() {
      reorder(_dragStartIndex, _currentIndex);
    }

    Widget wrapWithSemantics() {
      final Map<CustomSemanticsAction, VoidCallback> semanticsActions =
          <CustomSemanticsAction, VoidCallback>{};

      void moveToStart() => reorder(index, 0);
      void moveToEnd() => reorder(index, widget.children.length);
      void moveBefore() => reorder(index, index - 1);

      void moveAfter() => reorder(index, index + 2);

      final MaterialLocalizations localizations =
          MaterialLocalizations.of(context);

      if (index > 0) {
        semanticsActions[CustomSemanticsAction(
            label: localizations.reorderItemToStart)] = moveToStart;
        String reorderItemBefore = localizations.reorderItemUp;
        if (widget.scrollDirection == Axis.horizontal) {
          reorderItemBefore = Directionality.of(context) == TextDirection.ltr
              ? localizations.reorderItemLeft
              : localizations.reorderItemRight;
        }
        semanticsActions[CustomSemanticsAction(label: reorderItemBefore)] =
            moveBefore;
      }

      if (index < widget.children.length - 1) {
        String reorderItemAfter = localizations.reorderItemDown;
        if (widget.scrollDirection == Axis.horizontal) {
          reorderItemAfter = Directionality.of(context) == TextDirection.ltr
              ? localizations.reorderItemRight
              : localizations.reorderItemLeft;
        }
        semanticsActions[CustomSemanticsAction(label: reorderItemAfter)] =
            moveAfter;
        semanticsActions[
                CustomSemanticsAction(label: localizations.reorderItemToEnd)] =
            moveToEnd;
      }

      return KeyedSubtree(
        key: keyIndexGlobalKey,
        child: MergeSemantics(
          child: Semantics(
            customSemanticsActions: semanticsActions,
            child: toWrap,
          ),
        ),
      );
    }

    Widget buildDragTarget(BuildContext context, List<Key> acceptedCandidates,
        List<dynamic> rejectedCandidates) {
      final Widget toWrapWithSemantics = wrapWithSemantics();

      Widget child = LongPressDraggable<Key>(
        maxSimultaneousDrags: 1,
        axis: widget.scrollDirection,
        data: toWrap.key,
        ignoringFeedbackSemantics: false,
        feedback: Container(
          alignment: Alignment.topLeft,
          constraints: constraints,
          child: Material(
            elevation: 6.0,
            child: toWrapWithSemantics,
          ),
        ),
        child: _dragging == toWrap.key ? const SizedBox() : toWrapWithSemantics,
        childWhenDragging: const SizedBox(),
        dragAnchor: DragAnchor.child,
        onDragStarted: onDragStarted,
        onDragCompleted: onDragEnded,
        onDraggableCanceled: (Velocity velocity, Offset offset) {
          onDragEnded();
        },
      );

      if (index >= widget.children.length) {
        child = toWrap;
      }

      Widget spacing;
      switch (widget.scrollDirection) {
        case Axis.horizontal:
          spacing = SizedBox(width: _dropAreaExtent);
          break;
        case Axis.vertical:
        default:
          spacing = SizedBox(height: _dropAreaExtent);
          break;
      }

      if (_currentIndex == index) {
        return _buildContainerForScrollDirection(children: <Widget>[
          SizeTransition(
            sizeFactor: _entranceController,
            axis: widget.scrollDirection,
            child: spacing,
          ),
          child,
        ]);
      }

      if (_ghostIndex == index) {
        return _buildContainerForScrollDirection(children: <Widget>[
          SizeTransition(
            sizeFactor: _ghostController,
            axis: widget.scrollDirection,
            child: spacing,
          ),
          child,
        ]);
      }
      return child;
    }

    return Builder(builder: (BuildContext context) {
      return DragTarget<Key>(
        builder: buildDragTarget,
        onWillAccept: (Key toAccept) {
          setState(() {
            _nextIndex = index;
            _requestAnimationToNextIndex();
          });
          _scrollTo(context);

          return _dragging == toAccept && toAccept != toWrap.key;
        },
        onAccept: (Key accepted) {},
        onLeave: (Key leaving) {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final List<Widget> wrappedChildren = <Widget>[];
      if (widget.header != null) {
        wrappedChildren.add(widget.header);
      }
      for (int i = 0; i < widget.children.length; i += 1) {
        wrappedChildren.add(_wrap(widget.children[i], i, constraints));
      }
      const Key endWidgetKey = Key('DraggableList - End Widget');
      Widget finalDropArea;
      switch (widget.scrollDirection) {
        case Axis.horizontal:
          finalDropArea = SizedBox(
            key: endWidgetKey,
            width: _defaultDropAreaExtent,
            height: constraints.maxHeight,
          );
          break;
        case Axis.vertical:
        default:
          finalDropArea = SizedBox(
            key: endWidgetKey,
            height: _defaultDropAreaExtent,
            width: constraints.maxWidth,
          );
          break;
      }
      if (widget.reverse) {
        wrappedChildren.insert(
          0,
          _wrap(finalDropArea, widget.children.length, constraints),
        );
      } else {
        wrappedChildren.add(
          _wrap(finalDropArea, widget.children.length, constraints),
        );
      }
      return SingleChildScrollView(
        scrollDirection: widget.scrollDirection,
        child: _buildContainerForScrollDirection(children: wrappedChildren),
        padding: widget.padding,
        controller: _scrollController,
        reverse: widget.reverse,
      );
    });
  }
}

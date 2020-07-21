import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/services.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'overlay.dart';

typedef DragTargetWillAccept<T> = bool Function(T data);

typedef DragTargetAccept<T> = void Function(T data);

typedef DragTargetBuilder<T> = Widget Function(
    BuildContext context, List<T> candidateData, List<dynamic> rejectedData);

typedef DraggableCanceledCallback = void Function(
    Velocity velocity, Offset offset);

typedef DragEndCallback = void Function(DraggableDetails details);

typedef DragTargetLeave<T> = void Function(T data);

enum DragAnchor {
  child,

  pointer,
}

class Draggable<T> extends StatefulWidget {
  const Draggable({
    Key key,
    @required this.child,
    @required this.feedback,
    this.data,
    this.axis,
    this.childWhenDragging,
    this.feedbackOffset = Offset.zero,
    this.dragAnchor = DragAnchor.child,
    this.affinity,
    this.maxSimultaneousDrags,
    this.onDragStarted,
    this.onDraggableCanceled,
    this.onDragEnd,
    this.onDragCompleted,
    this.ignoringFeedbackSemantics = true,
  })  : assert(child != null),
        assert(feedback != null),
        assert(ignoringFeedbackSemantics != null),
        assert(maxSimultaneousDrags == null || maxSimultaneousDrags >= 0),
        super(key: key);

  final T data;

  final Axis axis;

  final Widget child;

  final Widget childWhenDragging;

  final Widget feedback;

  final Offset feedbackOffset;

  final DragAnchor dragAnchor;

  final bool ignoringFeedbackSemantics;

  final Axis affinity;

  final int maxSimultaneousDrags;

  final VoidCallback onDragStarted;

  final DraggableCanceledCallback onDraggableCanceled;

  final VoidCallback onDragCompleted;

  final DragEndCallback onDragEnd;

  @protected
  MultiDragGestureRecognizer<MultiDragPointerState> createRecognizer(
      GestureMultiDragStartCallback onStart) {
    switch (affinity) {
      case Axis.horizontal:
        return HorizontalMultiDragGestureRecognizer()..onStart = onStart;
      case Axis.vertical:
        return VerticalMultiDragGestureRecognizer()..onStart = onStart;
    }
    return ImmediateMultiDragGestureRecognizer()..onStart = onStart;
  }

  @override
  _DraggableState<T> createState() => _DraggableState<T>();
}

class LongPressDraggable<T> extends Draggable<T> {
  const LongPressDraggable({
    Key key,
    @required Widget child,
    @required Widget feedback,
    T data,
    Axis axis,
    Widget childWhenDragging,
    Offset feedbackOffset = Offset.zero,
    DragAnchor dragAnchor = DragAnchor.child,
    int maxSimultaneousDrags,
    VoidCallback onDragStarted,
    DraggableCanceledCallback onDraggableCanceled,
    DragEndCallback onDragEnd,
    VoidCallback onDragCompleted,
    this.hapticFeedbackOnStart = true,
    bool ignoringFeedbackSemantics = true,
  }) : super(
          key: key,
          child: child,
          feedback: feedback,
          data: data,
          axis: axis,
          childWhenDragging: childWhenDragging,
          feedbackOffset: feedbackOffset,
          dragAnchor: dragAnchor,
          maxSimultaneousDrags: maxSimultaneousDrags,
          onDragStarted: onDragStarted,
          onDraggableCanceled: onDraggableCanceled,
          onDragEnd: onDragEnd,
          onDragCompleted: onDragCompleted,
          ignoringFeedbackSemantics: ignoringFeedbackSemantics,
        );

  final bool hapticFeedbackOnStart;

  @override
  DelayedMultiDragGestureRecognizer createRecognizer(
      GestureMultiDragStartCallback onStart) {
    return DelayedMultiDragGestureRecognizer()
      ..onStart = (Offset position) {
        final Drag result = onStart(position);
        if (result != null && hapticFeedbackOnStart)
          HapticFeedback.selectionClick();
        return result;
      };
  }
}

class _DraggableState<T> extends State<Draggable<T>> {
  @override
  void initState() {
    super.initState();
    _recognizer = widget.createRecognizer(_startDrag);
  }

  @override
  void dispose() {
    _disposeRecognizerIfInactive();
    super.dispose();
  }

  GestureRecognizer _recognizer;
  int _activeCount = 0;

  void _disposeRecognizerIfInactive() {
    if (_activeCount > 0) return;
    _recognizer.dispose();
    _recognizer = null;
  }

  void _routePointer(PointerEvent event) {
    if (widget.maxSimultaneousDrags != null &&
        _activeCount >= widget.maxSimultaneousDrags) return;
    _recognizer.addPointer(event);
  }

  _DragAvatar<T> _startDrag(Offset position) {
    if (widget.maxSimultaneousDrags != null &&
        _activeCount >= widget.maxSimultaneousDrags) return null;
    Offset dragStartPoint;
    switch (widget.dragAnchor) {
      case DragAnchor.child:
        final RenderBox renderObject = context.findRenderObject();
        dragStartPoint = renderObject.globalToLocal(position);
        break;
      case DragAnchor.pointer:
        dragStartPoint = Offset.zero;
        break;
    }
    setState(() {
      _activeCount += 1;
    });
    final _DragAvatar<T> avatar = _DragAvatar<T>(
      overlayState: Overlay.of(context, debugRequiredFor: widget),
      data: widget.data,
      axis: widget.axis,
      initialPosition: position,
      dragStartPoint: dragStartPoint,
      feedback: widget.feedback,
      feedbackOffset: widget.feedbackOffset,
      ignoringFeedbackSemantics: widget.ignoringFeedbackSemantics,
      onDragEnd: (Velocity velocity, Offset offset, bool wasAccepted) {
        if (mounted) {
          setState(() {
            _activeCount -= 1;
          });
        } else {
          _activeCount -= 1;
          _disposeRecognizerIfInactive();
        }
        if (mounted && widget.onDragEnd != null) {
          widget.onDragEnd(DraggableDetails(
            wasAccepted: wasAccepted,
            velocity: velocity,
            offset: offset,
          ));
        }
        if (wasAccepted && widget.onDragCompleted != null)
          widget.onDragCompleted();
        if (!wasAccepted && widget.onDraggableCanceled != null)
          widget.onDraggableCanceled(velocity, offset);
      },
    );
    if (widget.onDragStarted != null) widget.onDragStarted();
    return avatar;
  }

  @override
  Widget build(BuildContext context) {
    assert(Overlay.of(context, debugRequiredFor: widget) != null);
    final bool canDrag = widget.maxSimultaneousDrags == null ||
        _activeCount < widget.maxSimultaneousDrags;
    final bool showChild =
        _activeCount == 0 || widget.childWhenDragging == null;
    return Listener(
      onPointerDown: canDrag ? _routePointer : null,
      child: showChild ? widget.child : widget.childWhenDragging,
    );
  }
}

class DraggableDetails {
  DraggableDetails({
    this.wasAccepted = false,
    @required this.velocity,
    @required this.offset,
  })  : assert(velocity != null),
        assert(offset != null);

  final bool wasAccepted;

  final Velocity velocity;

  final Offset offset;
}

class DragTarget<T> extends StatefulWidget {
  const DragTarget({
    Key key,
    @required this.builder,
    this.onWillAccept,
    this.onAccept,
    this.onLeave,
  }) : super(key: key);

  final DragTargetBuilder<T> builder;

  final DragTargetWillAccept<T> onWillAccept;

  final DragTargetAccept<T> onAccept;

  final DragTargetLeave<T> onLeave;

  @override
  _DragTargetState<T> createState() => _DragTargetState<T>();
}

List<T> _mapAvatarsToData<T>(List<_DragAvatar<T>> avatars) {
  return avatars.map<T>((_DragAvatar<T> avatar) => avatar.data).toList();
}

class _DragTargetState<T> extends State<DragTarget<T>> {
  final List<_DragAvatar<T>> _candidateAvatars = <_DragAvatar<T>>[];
  final List<_DragAvatar<dynamic>> _rejectedAvatars = <_DragAvatar<dynamic>>[];

  bool didEnter(_DragAvatar<dynamic> avatar) {
    assert(!_candidateAvatars.contains(avatar));
    assert(!_rejectedAvatars.contains(avatar));
    if (avatar.data is T &&
        (widget.onWillAccept == null || widget.onWillAccept(avatar.data))) {
      setState(() {
        _candidateAvatars.add(avatar);
      });
      return true;
    }
    _rejectedAvatars.add(avatar);
    return false;
  }

  void didLeave(_DragAvatar<dynamic> avatar) {
    assert(_candidateAvatars.contains(avatar) ||
        _rejectedAvatars.contains(avatar));
    if (!mounted) return;
    setState(() {
      _candidateAvatars.remove(avatar);
      _rejectedAvatars.remove(avatar);
    });
    if (widget.onLeave != null) widget.onLeave(avatar.data);
  }

  void didDrop(_DragAvatar<dynamic> avatar) {
    assert(_candidateAvatars.contains(avatar));
    if (!mounted) return;
    setState(() {
      _candidateAvatars.remove(avatar);
    });
    if (widget.onAccept != null) widget.onAccept(avatar.data);
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.builder != null);
    return MetaData(
      metaData: this,
      behavior: HitTestBehavior.translucent,
      child: widget.builder(context, _mapAvatarsToData<T>(_candidateAvatars),
          _mapAvatarsToData<dynamic>(_rejectedAvatars)),
    );
  }
}

enum _DragEndKind { dropped, canceled }
typedef _OnDragEnd = void Function(
    Velocity velocity, Offset offset, bool wasAccepted);

class _DragAvatar<T> extends Drag {
  _DragAvatar({
    @required this.overlayState,
    this.data,
    this.axis,
    Offset initialPosition,
    this.dragStartPoint = Offset.zero,
    this.feedback,
    this.feedbackOffset = Offset.zero,
    this.onDragEnd,
    @required this.ignoringFeedbackSemantics,
  })  : assert(overlayState != null),
        assert(ignoringFeedbackSemantics != null),
        assert(dragStartPoint != null),
        assert(feedbackOffset != null) {
    _entry = OverlayEntry(builder: _build);
    overlayState.insert(_entry);
    _position = initialPosition;
    updateDrag(initialPosition);
  }

  final T data;
  final Axis axis;
  final Offset dragStartPoint;
  final Widget feedback;
  final Offset feedbackOffset;
  final _OnDragEnd onDragEnd;
  final OverlayState overlayState;
  final bool ignoringFeedbackSemantics;

  _DragTargetState<T> _activeTarget;
  final List<_DragTargetState<T>> _enteredTargets = <_DragTargetState<T>>[];
  Offset _position;
  Offset _lastOffset;
  OverlayEntry _entry;

  @override
  void update(DragUpdateDetails details) {
    _position += _restrictAxis(details.delta);
    updateDrag(_position);
  }

  @override
  void end(DragEndDetails details) {
    finishDrag(_DragEndKind.dropped, _restrictVelocityAxis(details.velocity));
  }

  @override
  void cancel() {
    finishDrag(_DragEndKind.canceled);
  }

  void updateDrag(Offset globalPosition) {
    _lastOffset = globalPosition - dragStartPoint;
    _entry.markNeedsBuild();
    final HitTestResult result = HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPosition + feedbackOffset);

    final List<_DragTargetState<T>> targets =
        _getDragTargets(result.path).toList();

    bool listsMatch = false;
    if (targets.length >= _enteredTargets.length &&
        _enteredTargets.isNotEmpty) {
      listsMatch = true;
      final Iterator<_DragTargetState<T>> iterator = targets.iterator;
      for (int i = 0; i < _enteredTargets.length; i += 1) {
        iterator.moveNext();
        if (iterator.current != _enteredTargets[i]) {
          listsMatch = false;
          break;
        }
      }
    }

    if (listsMatch) return;

    _leaveAllEntered();

    final _DragTargetState<T> newTarget = targets.firstWhere(
      (_DragTargetState<T> target) {
        _enteredTargets.add(target);
        return target.didEnter(this);
      },
      orElse: () => null,
    );

    _activeTarget = newTarget;
  }

  Iterable<_DragTargetState<T>> _getDragTargets(
      Iterable<HitTestEntry> path) sync* {
    for (HitTestEntry entry in path) {
      if (entry.target is RenderMetaData) {
        final RenderMetaData renderMetaData = entry.target;
        if (renderMetaData.metaData is _DragTargetState<T>)
          yield renderMetaData.metaData;
      }
    }
  }

  void _leaveAllEntered() {
    for (int i = 0; i < _enteredTargets.length; i += 1)
      _enteredTargets[i].didLeave(this);
    _enteredTargets.clear();
  }

  void finishDrag(_DragEndKind endKind, [Velocity velocity]) {
    bool wasAccepted = false;
    if (endKind == _DragEndKind.dropped && _activeTarget != null) {
      _activeTarget.didDrop(this);
      wasAccepted = true;
      _enteredTargets.remove(_activeTarget);
    }
    _leaveAllEntered();
    _activeTarget = null;
    _entry.remove();
    _entry = null;

    if (onDragEnd != null)
      onDragEnd(velocity ?? Velocity.zero, _lastOffset, wasAccepted);
  }

  Widget _build(BuildContext context) {
    final RenderBox box = overlayState.context.findRenderObject();
    final Offset overlayTopLeft = box.localToGlobal(Offset.zero);
    return Positioned(
      left: _lastOffset.dx - overlayTopLeft.dx,
      top: _lastOffset.dy - overlayTopLeft.dy,
      child: IgnorePointer(
        child: feedback,
        ignoringSemantics: ignoringFeedbackSemantics,
      ),
    );
  }

  Velocity _restrictVelocityAxis(Velocity velocity) {
    if (axis == null) {
      return velocity;
    }
    return Velocity(
      pixelsPerSecond: _restrictAxis(velocity.pixelsPerSecond),
    );
  }

  Offset _restrictAxis(Offset offset) {
    if (axis == null) {
      return offset;
    }
    if (axis == Axis.horizontal) {
      return Offset(offset.dx, 0.0);
    }
    return Offset(0.0, offset.dy);
  }
}

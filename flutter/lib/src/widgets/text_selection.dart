import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart'
    show kDoubleTapTimeout, kDoubleTapSlop;
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/services.dart';

import 'basic.dart';
import 'container.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'overlay.dart';
import 'ticker_provider.dart';
import 'transitions.dart';
import 'visibility.dart';
export 'package:flutter_web/services.dart' show TextSelectionDelegate;

const Duration _kDragSelectionUpdateThrottle = Duration(milliseconds: 50);

enum TextSelectionHandleType {
  left,

  right,

  collapsed,
}

enum _TextSelectionHandlePosition { start, end }

typedef TextSelectionOverlayChanged = void Function(
    TextEditingValue value, Rect caretRect);

typedef DragSelectionUpdateCallback = void Function(
    DragStartDetails startDetails, DragUpdateDetails updateDetails);

abstract class TextSelectionControls {
  Widget buildHandle(BuildContext context, TextSelectionHandleType type,
      double textLineHeight);

  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight);

  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
  );

  Size getHandleSize(double textLineHeight);

  bool canCut(TextSelectionDelegate delegate) {
    return delegate.cutEnabled &&
        !delegate.textEditingValue.selection.isCollapsed;
  }

  bool canCopy(TextSelectionDelegate delegate) {
    return delegate.copyEnabled &&
        !delegate.textEditingValue.selection.isCollapsed;
  }

  bool canPaste(TextSelectionDelegate delegate) {
    return delegate.pasteEnabled;
  }

  bool canSelectAll(TextSelectionDelegate delegate) {
    return delegate.selectAllEnabled &&
        delegate.textEditingValue.text.isNotEmpty &&
        delegate.textEditingValue.selection.isCollapsed;
  }

  void handleCut(TextSelectionDelegate delegate) {
    final TextEditingValue value = delegate.textEditingValue;
    Clipboard.setData(ClipboardData(
      text: value.selection.textInside(value.text),
    ));
    delegate.textEditingValue = TextEditingValue(
      text: value.selection.textBefore(value.text) +
          value.selection.textAfter(value.text),
      selection: TextSelection.collapsed(offset: value.selection.start),
    );
    delegate.bringIntoView(delegate.textEditingValue.selection.extent);
    delegate.hideToolbar();
  }

  void handleCopy(TextSelectionDelegate delegate) {
    final TextEditingValue value = delegate.textEditingValue;
    Clipboard.setData(ClipboardData(
      text: value.selection.textInside(value.text),
    ));
    delegate.textEditingValue = TextEditingValue(
      text: value.text,
      selection: TextSelection.collapsed(offset: value.selection.end),
    );
    delegate.bringIntoView(delegate.textEditingValue.selection.extent);
    delegate.hideToolbar();
  }

  Future<void> handlePaste(TextSelectionDelegate delegate) async {
    final TextEditingValue value = delegate.textEditingValue;
    final ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      delegate.textEditingValue = TextEditingValue(
        text: value.selection.textBefore(value.text) +
            data.text +
            value.selection.textAfter(value.text),
        selection: TextSelection.collapsed(
            offset: value.selection.start + data.text.length),
      );
    }
    delegate.bringIntoView(delegate.textEditingValue.selection.extent);
    delegate.hideToolbar();
  }

  void handleSelectAll(TextSelectionDelegate delegate) {
    delegate.textEditingValue = TextEditingValue(
      text: delegate.textEditingValue.text,
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: delegate.textEditingValue.text.length,
      ),
    );
    delegate.bringIntoView(delegate.textEditingValue.selection.extent);
  }
}

class TextSelectionOverlay {
  TextSelectionOverlay({
    @required TextEditingValue value,
    @required this.context,
    this.debugRequiredFor,
    @required this.toolbarLayerLink,
    @required this.startHandleLayerLink,
    @required this.endHandleLayerLink,
    @required this.renderObject,
    this.selectionControls,
    bool handlesVisible = false,
    this.selectionDelegate,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onSelectionHandleTapped,
  })  : assert(value != null),
        assert(context != null),
        assert(handlesVisible != null),
        _handlesVisible = handlesVisible,
        _value = value {
    final OverlayState overlay = Overlay.of(context);
    assert(
        overlay != null,
        'No Overlay widget exists above $context.\n'
        'Usually the Navigator created by WidgetsApp provides the overlay. Perhaps your '
        'app content was created above the Navigator with the WidgetsApp builder parameter.');
    _toolbarController =
        AnimationController(duration: fadeDuration, vsync: overlay);
  }

  final BuildContext context;

  final Widget debugRequiredFor;

  final LayerLink toolbarLayerLink;

  final LayerLink startHandleLayerLink;

  final LayerLink endHandleLayerLink;

  final RenderEditable renderObject;

  final TextSelectionControls selectionControls;

  final TextSelectionDelegate selectionDelegate;

  final DragStartBehavior dragStartBehavior;

  final VoidCallback onSelectionHandleTapped;

  static const Duration fadeDuration = Duration(milliseconds: 150);

  AnimationController _toolbarController;
  Animation<double> get _toolbarOpacity => _toolbarController.view;

  @visibleForTesting
  TextEditingValue get value => _value;

  TextEditingValue _value;

  List<OverlayEntry> _handles;

  OverlayEntry _toolbar;

  TextSelection get _selection => _value.selection;

  bool get handlesVisible => _handlesVisible;
  bool _handlesVisible = false;
  set handlesVisible(bool visible) {
    assert(visible != null);
    if (_handlesVisible == visible) return;
    _handlesVisible = visible;

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(_markNeedsBuild);
    } else {
      _markNeedsBuild();
    }
  }

  void showHandles() {
    assert(_handles == null);
    _handles = <OverlayEntry>[
      OverlayEntry(
          builder: (BuildContext context) =>
              _buildHandle(context, _TextSelectionHandlePosition.start)),
      OverlayEntry(
          builder: (BuildContext context) =>
              _buildHandle(context, _TextSelectionHandlePosition.end)),
    ];

    Overlay.of(context, debugRequiredFor: debugRequiredFor).insertAll(_handles);
  }

  void hideHandles() {
    if (_handles != null) {
      _handles[0].remove();
      _handles[1].remove();
      _handles = null;
    }
  }

  void showToolbar() {
    assert(_toolbar == null);
    _toolbar = OverlayEntry(builder: _buildToolbar);
    Overlay.of(context, debugRequiredFor: debugRequiredFor).insert(_toolbar);
    _toolbarController.forward(from: 0.0);
  }

  void update(TextEditingValue newValue) {
    if (_value == newValue) return;
    _value = newValue;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(_markNeedsBuild);
    } else {
      _markNeedsBuild();
    }
  }

  void updateForScroll() {
    _markNeedsBuild();
  }

  void _markNeedsBuild([Duration duration]) {
    if (_handles != null) {
      _handles[0].markNeedsBuild();
      _handles[1].markNeedsBuild();
    }
    _toolbar?.markNeedsBuild();
  }

  bool get handlesAreVisible => _handles != null && handlesVisible;

  bool get toolbarIsVisible => _toolbar != null;

  void hide() {
    if (_handles != null) {
      _handles[0].remove();
      _handles[1].remove();
      _handles = null;
    }
    if (_toolbar != null) {
      hideToolbar();
    }
  }

  void hideToolbar() {
    assert(_toolbar != null);
    _toolbarController.stop();
    _toolbar.remove();
    _toolbar = null;
  }

  void dispose() {
    hide();
    _toolbarController.dispose();
  }

  Widget _buildHandle(
      BuildContext context, _TextSelectionHandlePosition position) {
    if ((_selection.isCollapsed &&
            position == _TextSelectionHandlePosition.end) ||
        selectionControls == null) return Container();
    return Visibility(
        visible: handlesVisible,
        child: _TextSelectionHandleOverlay(
          onSelectionHandleChanged: (TextSelection newSelection) {
            _handleSelectionHandleChanged(newSelection, position);
          },
          onSelectionHandleTapped: onSelectionHandleTapped,
          startHandleLayerLink: startHandleLayerLink,
          endHandleLayerLink: endHandleLayerLink,
          renderObject: renderObject,
          selection: _selection,
          selectionControls: selectionControls,
          position: position,
          dragStartBehavior: dragStartBehavior,
        ));
  }

  Widget _buildToolbar(BuildContext context) {
    if (selectionControls == null) return Container();

    final List<TextSelectionPoint> endpoints =
        renderObject.getEndpointsForSelection(_selection);

    final Rect editingRegion = Rect.fromPoints(
      renderObject.localToGlobal(Offset.zero),
      renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero)),
    );

    final bool isMultiline =
        endpoints.last.point.dy - endpoints.first.point.dy >
            renderObject.preferredLineHeight / 2;

    final double midX = isMultiline
        ? editingRegion.width / 2
        : (endpoints.first.point.dx + endpoints.last.point.dx) / 2;

    final Offset midpoint = Offset(
      midX,
      endpoints[0].point.dy - renderObject.preferredLineHeight,
    );

    return FadeTransition(
      opacity: _toolbarOpacity,
      child: CompositedTransformFollower(
        link: toolbarLayerLink,
        showWhenUnlinked: false,
        offset: -editingRegion.topLeft,
        child: selectionControls.buildToolbar(
          context,
          editingRegion,
          renderObject.preferredLineHeight,
          midpoint,
          endpoints,
          selectionDelegate,
        ),
      ),
    );
  }

  void _handleSelectionHandleChanged(
      TextSelection newSelection, _TextSelectionHandlePosition position) {
    TextPosition textPosition;
    switch (position) {
      case _TextSelectionHandlePosition.start:
        textPosition = newSelection.base;
        break;
      case _TextSelectionHandlePosition.end:
        textPosition = newSelection.extent;
        break;
    }
    selectionDelegate.textEditingValue =
        _value.copyWith(selection: newSelection, composing: TextRange.empty);
    selectionDelegate.bringIntoView(textPosition);
  }
}

class _TextSelectionHandleOverlay extends StatefulWidget {
  const _TextSelectionHandleOverlay({
    Key key,
    @required this.selection,
    @required this.position,
    @required this.startHandleLayerLink,
    @required this.endHandleLayerLink,
    @required this.renderObject,
    @required this.onSelectionHandleChanged,
    @required this.onSelectionHandleTapped,
    @required this.selectionControls,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : super(key: key);

  final TextSelection selection;
  final _TextSelectionHandlePosition position;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final RenderEditable renderObject;
  final ValueChanged<TextSelection> onSelectionHandleChanged;
  final VoidCallback onSelectionHandleTapped;
  final TextSelectionControls selectionControls;
  final DragStartBehavior dragStartBehavior;

  @override
  _TextSelectionHandleOverlayState createState() =>
      _TextSelectionHandleOverlayState();

  ValueListenable<bool> get _visibility {
    switch (position) {
      case _TextSelectionHandlePosition.start:
        return renderObject.selectionStartInViewport;
      case _TextSelectionHandlePosition.end:
        return renderObject.selectionEndInViewport;
    }
    return null;
  }
}

@visibleForTesting
const double kMinInteractiveSize = 48.0;

class _TextSelectionHandleOverlayState
    extends State<_TextSelectionHandleOverlay>
    with SingleTickerProviderStateMixin {
  Offset _dragPosition;

  AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: TextSelectionOverlay.fadeDuration, vsync: this);

    _handleVisibilityChanged();
    widget._visibility.addListener(_handleVisibilityChanged);
  }

  void _handleVisibilityChanged() {
    if (widget._visibility.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(_TextSelectionHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget._visibility.removeListener(_handleVisibilityChanged);
    _handleVisibilityChanged();
    widget._visibility.addListener(_handleVisibilityChanged);
  }

  @override
  void dispose() {
    widget._visibility.removeListener(_handleVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    final Size handleSize = widget.selectionControls.getHandleSize(
      widget.renderObject.preferredLineHeight,
    );
    _dragPosition = details.globalPosition + Offset(0.0, -handleSize.height);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragPosition += details.delta;
    final TextPosition position =
        widget.renderObject.getPositionForPoint(_dragPosition);

    if (widget.selection.isCollapsed) {
      widget.onSelectionHandleChanged(TextSelection.fromPosition(position));
      return;
    }

    TextSelection newSelection;
    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        newSelection = TextSelection(
          baseOffset: position.offset,
          extentOffset: widget.selection.extentOffset,
        );
        break;
      case _TextSelectionHandlePosition.end:
        newSelection = TextSelection(
          baseOffset: widget.selection.baseOffset,
          extentOffset: position.offset,
        );
        break;
    }

    if (newSelection.baseOffset >= newSelection.extentOffset) return;

    widget.onSelectionHandleChanged(newSelection);
  }

  void _handleTap() {
    if (widget.onSelectionHandleTapped != null)
      widget.onSelectionHandleTapped();
  }

  @override
  Widget build(BuildContext context) {
    LayerLink layerLink;
    TextSelectionHandleType type;

    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        layerLink = widget.startHandleLayerLink;
        type = _chooseType(
          widget.renderObject.textDirection,
          TextSelectionHandleType.left,
          TextSelectionHandleType.right,
        );
        break;
      case _TextSelectionHandlePosition.end:
        assert(!widget.selection.isCollapsed);
        layerLink = widget.endHandleLayerLink;
        type = _chooseType(
          widget.renderObject.textDirection,
          TextSelectionHandleType.right,
          TextSelectionHandleType.left,
        );
        break;
    }

    final Offset handleAnchor = widget.selectionControls.getHandleAnchor(
      type,
      widget.renderObject.preferredLineHeight,
    );
    final Size handleSize = widget.selectionControls.getHandleSize(
      widget.renderObject.preferredLineHeight,
    );

    final Rect handleRect = Rect.fromLTWH(
      -handleAnchor.dx,
      -handleAnchor.dy,
      handleSize.width,
      handleSize.height,
    );

    final Rect interactiveRect = handleRect.expandToInclude(
      Rect.fromCircle(
          center: handleRect.center, radius: kMinInteractiveSize / 2),
    );
    final RelativeRect padding = RelativeRect.fromLTRB(
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
    );

    return CompositedTransformFollower(
      link: layerLink,
      offset: interactiveRect.topLeft,
      showWhenUnlinked: false,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          alignment: Alignment.topLeft,
          width: interactiveRect.width,
          height: interactiveRect.height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: widget.dragStartBehavior,
            onPanStart: _handleDragStart,
            onPanUpdate: _handleDragUpdate,
            onTap: _handleTap,
            child: Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                top: padding.top,
                right: padding.right,
                bottom: padding.bottom,
              ),
              child: widget.selectionControls.buildHandle(
                context,
                type,
                widget.renderObject.preferredLineHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextSelectionHandleType _chooseType(
    TextDirection textDirection,
    TextSelectionHandleType ltrType,
    TextSelectionHandleType rtlType,
  ) {
    if (widget.selection.isCollapsed) return TextSelectionHandleType.collapsed;

    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.ltr:
        return ltrType;
      case TextDirection.rtl:
        return rtlType;
    }
    return null;
  }
}

abstract class TextSelectionGestureDetectorBuilderDelegate {
  GlobalKey<EditableTextState> get editableTextKey;

  bool get forcePressEnabled;

  bool get selectionEnabled;
}

class TextSelectionGestureDetectorBuilder {
  TextSelectionGestureDetectorBuilder({
    @required this.delegate,
  }) : assert(delegate != null);

  @protected
  final TextSelectionGestureDetectorBuilderDelegate delegate;

  bool get shouldShowSelectionToolbar => _shouldShowSelectionToolbar;
  bool _shouldShowSelectionToolbar = true;

  @protected
  EditableTextState get editableText => delegate.editableTextKey.currentState;

  @protected
  RenderEditable get renderEditable => editableText.renderEditable;

  @protected
  void onTapDown(TapDownDetails details) {
    renderEditable.handleTapDown(details);

    final PointerDeviceKind kind = details.kind;
    _shouldShowSelectionToolbar = kind == null ||
        kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus;
  }

  @protected
  void onForcePressStart(ForcePressDetails details) {
    assert(delegate.forcePressEnabled);
    _shouldShowSelectionToolbar = true;
    if (delegate.selectionEnabled) {
      renderEditable.selectWordsInRange(
        from: details.globalPosition,
        cause: SelectionChangedCause.forcePress,
      );
    }
  }

  @protected
  void onForcePressEnd(ForcePressDetails details) {
    assert(delegate.forcePressEnabled);
    renderEditable.selectWordsInRange(
      from: details.globalPosition,
      cause: SelectionChangedCause.forcePress,
    );
    if (shouldShowSelectionToolbar) editableText.showToolbar();
  }

  @protected
  void onSingleTapUp(TapUpDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectWordEdge(cause: SelectionChangedCause.tap);
    }
  }

  @protected
  void onSingleTapCancel() {}

  @protected
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    }
  }

  @protected
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );
    }
  }

  @protected
  void onSingleLongTapEnd(LongPressEndDetails details) {
    if (shouldShowSelectionToolbar) editableText.showToolbar();
  }

  @protected
  void onDoubleTapDown(TapDownDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectWord(cause: SelectionChangedCause.tap);
      if (shouldShowSelectionToolbar) editableText.showToolbar();
    }
  }

  @protected
  void onDragSelectionStart(DragStartDetails details) {
    renderEditable.selectPositionAt(
      from: details.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  @protected
  void onDragSelectionUpdate(
      DragStartDetails startDetails, DragUpdateDetails updateDetails) {
    renderEditable.selectPositionAt(
      from: startDetails.globalPosition,
      to: updateDetails.globalPosition,
      cause: SelectionChangedCause.drag,
    );
  }

  @protected
  void onDragSelectionEnd(DragEndDetails details) {}

  Widget buildGestureDetector(
      {Key key, HitTestBehavior behavior, Widget child}) {
    return TextSelectionGestureDetector(
      key: key,
      onTapDown: onTapDown,
      onForcePressStart: delegate.forcePressEnabled ? onForcePressStart : null,
      onForcePressEnd: delegate.forcePressEnabled ? onForcePressEnd : null,
      onSingleTapUp: onSingleTapUp,
      onSingleTapCancel: onSingleTapCancel,
      onSingleLongTapStart: onSingleLongTapStart,
      onSingleLongTapMoveUpdate: onSingleLongTapMoveUpdate,
      onSingleLongTapEnd: onSingleLongTapEnd,
      onDoubleTapDown: onDoubleTapDown,
      onDragSelectionStart: onDragSelectionStart,
      onDragSelectionUpdate: onDragSelectionUpdate,
      onDragSelectionEnd: onDragSelectionEnd,
      behavior: behavior,
      child: child,
    );
  }
}

class TextSelectionGestureDetector extends StatefulWidget {
  const TextSelectionGestureDetector({
    Key key,
    this.onTapDown,
    this.onForcePressStart,
    this.onForcePressEnd,
    this.onSingleTapUp,
    this.onSingleTapCancel,
    this.onSingleLongTapStart,
    this.onSingleLongTapMoveUpdate,
    this.onSingleLongTapEnd,
    this.onDoubleTapDown,
    this.onDragSelectionStart,
    this.onDragSelectionUpdate,
    this.onDragSelectionEnd,
    this.behavior,
    @required this.child,
  })  : assert(child != null),
        super(key: key);

  final GestureTapDownCallback onTapDown;

  final GestureForcePressStartCallback onForcePressStart;

  final GestureForcePressEndCallback onForcePressEnd;

  final GestureTapUpCallback onSingleTapUp;

  final GestureTapCancelCallback onSingleTapCancel;

  final GestureLongPressStartCallback onSingleLongTapStart;

  final GestureLongPressMoveUpdateCallback onSingleLongTapMoveUpdate;

  final GestureLongPressEndCallback onSingleLongTapEnd;

  final GestureTapDownCallback onDoubleTapDown;

  final GestureDragStartCallback onDragSelectionStart;

  final DragSelectionUpdateCallback onDragSelectionUpdate;

  final GestureDragEndCallback onDragSelectionEnd;

  final HitTestBehavior behavior;

  final Widget child;

  @override
  State<StatefulWidget> createState() => _TextSelectionGestureDetectorState();
}

class _TextSelectionGestureDetectorState
    extends State<TextSelectionGestureDetector> {
  Timer _doubleTapTimer;
  Offset _lastTapOffset;

  bool _isDoubleTap = false;

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _dragUpdateThrottleTimer?.cancel();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTapDown != null) {
      widget.onTapDown(details);
    }

    if (_doubleTapTimer != null &&
        _isWithinDoubleTapTolerance(details.globalPosition)) {
      if (widget.onDoubleTapDown != null) {
        widget.onDoubleTapDown(details);
      }

      _doubleTapTimer.cancel();
      _doubleTapTimeout();
      _isDoubleTap = true;
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isDoubleTap) {
      if (widget.onSingleTapUp != null) {
        widget.onSingleTapUp(details);
      }
      _lastTapOffset = details.globalPosition;
      _doubleTapTimer = Timer(kDoubleTapTimeout, _doubleTapTimeout);
    }
    _isDoubleTap = false;
  }

  void _handleTapCancel() {
    if (widget.onSingleTapCancel != null) {
      widget.onSingleTapCancel();
    }
  }

  DragStartDetails _lastDragStartDetails;
  DragUpdateDetails _lastDragUpdateDetails;
  Timer _dragUpdateThrottleTimer;

  void _handleDragStart(DragStartDetails details) {
    assert(_lastDragStartDetails == null);
    _lastDragStartDetails = details;
    if (widget.onDragSelectionStart != null) {
      widget.onDragSelectionStart(details);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _lastDragUpdateDetails = details;

    _dragUpdateThrottleTimer ??=
        Timer(_kDragSelectionUpdateThrottle, _handleDragUpdateThrottled);
  }

  void _handleDragUpdateThrottled() {
    assert(_lastDragStartDetails != null);
    assert(_lastDragUpdateDetails != null);
    if (widget.onDragSelectionUpdate != null) {
      widget.onDragSelectionUpdate(
          _lastDragStartDetails, _lastDragUpdateDetails);
    }
    _dragUpdateThrottleTimer = null;
    _lastDragUpdateDetails = null;
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(_lastDragStartDetails != null);
    if (_dragUpdateThrottleTimer != null) {
      _dragUpdateThrottleTimer.cancel();
      _handleDragUpdateThrottled();
    }
    if (widget.onDragSelectionEnd != null) {
      widget.onDragSelectionEnd(details);
    }
    _dragUpdateThrottleTimer = null;
    _lastDragStartDetails = null;
    _lastDragUpdateDetails = null;
  }

  void _forcePressStarted(ForcePressDetails details) {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
    if (widget.onForcePressStart != null) widget.onForcePressStart(details);
  }

  void _forcePressEnded(ForcePressDetails details) {
    if (widget.onForcePressEnd != null) widget.onForcePressEnd(details);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapStart != null) {
      widget.onSingleLongTapStart(details);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapMoveUpdate != null) {
      widget.onSingleLongTapMoveUpdate(details);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapEnd != null) {
      widget.onSingleLongTapEnd(details);
    }
    _isDoubleTap = false;
  }

  void _doubleTapTimeout() {
    _doubleTapTimer = null;
    _lastTapOffset = null;
  }

  bool _isWithinDoubleTapTolerance(Offset secondTapOffset) {
    assert(secondTapOffset != null);
    if (_lastTapOffset == null) {
      return false;
    }

    final Offset difference = secondTapOffset - _lastTapOffset;
    return difference.distance <= kDoubleTapSlop;
  }

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    gestures[_TransparentTapGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_TransparentTapGestureRecognizer>(
      () => _TransparentTapGestureRecognizer(debugOwner: this),
      (_TransparentTapGestureRecognizer instance) {
        instance
          ..onTapDown = _handleTapDown
          ..onTapUp = _handleTapUp
          ..onTapCancel = _handleTapCancel;
      },
    );

    if (widget.onSingleLongTapStart != null ||
        widget.onSingleLongTapMoveUpdate != null ||
        widget.onSingleLongTapEnd != null) {
      gestures[LongPressGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(
            debugOwner: this, kind: PointerDeviceKind.touch),
        (LongPressGestureRecognizer instance) {
          instance
            ..onLongPressStart = _handleLongPressStart
            ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
            ..onLongPressEnd = _handleLongPressEnd;
        },
      );
    }

    if (widget.onDragSelectionStart != null ||
        widget.onDragSelectionUpdate != null ||
        widget.onDragSelectionEnd != null) {
      gestures[HorizontalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(
            debugOwner: this, kind: PointerDeviceKind.mouse),
        (HorizontalDragGestureRecognizer instance) {
          instance
            ..dragStartBehavior = DragStartBehavior.down
            ..onStart = _handleDragStart
            ..onUpdate = _handleDragUpdate
            ..onEnd = _handleDragEnd;
        },
      );
    }

    if (widget.onForcePressStart != null || widget.onForcePressEnd != null) {
      gestures[ForcePressGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
        () => ForcePressGestureRecognizer(debugOwner: this),
        (ForcePressGestureRecognizer instance) {
          instance
            ..onStart =
                widget.onForcePressStart != null ? _forcePressStarted : null
            ..onEnd = widget.onForcePressEnd != null ? _forcePressEnded : null;
        },
      );
    }

    return RawGestureDetector(
      gestures: gestures,
      excludeFromSemantics: true,
      behavior: widget.behavior,
      child: widget.child,
    );
  }
}

class _TransparentTapGestureRecognizer extends TapGestureRecognizer {
  _TransparentTapGestureRecognizer({
    Object debugOwner,
  }) : super(debugOwner: debugOwner);

  @override
  void rejectGesture(int pointer) {
    if (state == GestureRecognizerState.ready) {
      acceptGesture(pointer);
    } else {
      super.rejectGesture(pointer);
    }
  }
}

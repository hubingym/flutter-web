import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';

import 'basic.dart';
import 'framework.dart';

export 'package:flutter_web/gestures.dart'
    show
        DragDownDetails,
        DragStartDetails,
        DragUpdateDetails,
        DragEndDetails,
        GestureTapDownCallback,
        GestureTapUpCallback,
        GestureTapCallback,
        GestureTapCancelCallback,
        GestureLongPressCallback,
        GestureLongPressStartCallback,
        GestureLongPressMoveUpdateCallback,
        GestureLongPressUpCallback,
        GestureLongPressEndCallback,
        GestureDragDownCallback,
        GestureDragStartCallback,
        GestureDragUpdateCallback,
        GestureDragEndCallback,
        GestureDragCancelCallback,
        GestureScaleStartCallback,
        GestureScaleUpdateCallback,
        GestureScaleEndCallback,
        GestureForcePressStartCallback,
        GestureForcePressPeakCallback,
        GestureForcePressEndCallback,
        GestureForcePressUpdateCallback,
        LongPressStartDetails,
        LongPressMoveUpdateDetails,
        LongPressEndDetails,
        ScaleStartDetails,
        ScaleUpdateDetails,
        ScaleEndDetails,
        TapDownDetails,
        TapUpDetails,
        ForcePressDetails,
        Velocity;

@optionalTypeArgs
abstract class GestureRecognizerFactory<T extends GestureRecognizer> {
  const GestureRecognizerFactory();

  T constructor();

  void initializer(T instance);

  bool _debugAssertTypeMatches(Type type) {
    assert(type == T,
        'GestureRecognizerFactory of type $T was used where type $type was specified.');
    return true;
  }
}

typedef GestureRecognizerFactoryConstructor<T extends GestureRecognizer> = T
    Function();

typedef GestureRecognizerFactoryInitializer<T extends GestureRecognizer> = void
    Function(T instance);

class GestureRecognizerFactoryWithHandlers<T extends GestureRecognizer>
    extends GestureRecognizerFactory<T> {
  const GestureRecognizerFactoryWithHandlers(
      this._constructor, this._initializer)
      : assert(_constructor != null),
        assert(_initializer != null);

  final GestureRecognizerFactoryConstructor<T> _constructor;

  final GestureRecognizerFactoryInitializer<T> _initializer;

  @override
  T constructor() => _constructor();

  @override
  void initializer(T instance) => _initializer(instance);
}

class GestureDetector extends StatelessWidget {
  GestureDetector({
    Key key,
    this.child,
    this.onTapDown,
    this.onTapUp,
    this.onTap,
    this.onTapCancel,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onSecondaryTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressUp,
    this.onLongPressEnd,
    this.onVerticalDragDown,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
    this.onVerticalDragCancel,
    this.onHorizontalDragDown,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
    this.onHorizontalDragCancel,
    this.onForcePressStart,
    this.onForcePressPeak,
    this.onForcePressUpdate,
    this.onForcePressEnd,
    this.onPanDown,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.behavior,
    this.excludeFromSemantics = false,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : assert(excludeFromSemantics != null),
        assert(dragStartBehavior != null),
        assert(() {
          final bool haveVerticalDrag = onVerticalDragStart != null ||
              onVerticalDragUpdate != null ||
              onVerticalDragEnd != null;
          final bool haveHorizontalDrag = onHorizontalDragStart != null ||
              onHorizontalDragUpdate != null ||
              onHorizontalDragEnd != null;
          final bool havePan =
              onPanStart != null || onPanUpdate != null || onPanEnd != null;
          final bool haveScale = onScaleStart != null ||
              onScaleUpdate != null ||
              onScaleEnd != null;
          if (havePan || haveScale) {
            if (havePan && haveScale) {
              throw FlutterError('Incorrect GestureDetector arguments.\n'
                  'Having both a pan gesture recognizer and a scale gesture recognizer is redundant; scale is a superset of pan. Just use the scale gesture recognizer.');
            }
            final String recognizer = havePan ? 'pan' : 'scale';
            if (haveVerticalDrag && haveHorizontalDrag) {
              throw FlutterError('Incorrect GestureDetector arguments.\n'
                  'Simultaneously having a vertical drag gesture recognizer, a horizontal drag gesture recognizer, and a $recognizer gesture recognizer '
                  'will result in the $recognizer gesture recognizer being ignored, since the other two will catch all drags.');
            }
          }
          return true;
        }()),
        super(key: key);

  final Widget child;

  final GestureTapDownCallback onTapDown;

  final GestureTapUpCallback onTapUp;

  final GestureTapCallback onTap;

  final GestureTapCancelCallback onTapCancel;

  final GestureTapDownCallback onSecondaryTapDown;

  final GestureTapUpCallback onSecondaryTapUp;

  final GestureTapCancelCallback onSecondaryTapCancel;

  final GestureTapCallback onDoubleTap;

  final GestureLongPressCallback onLongPress;

  final GestureLongPressStartCallback onLongPressStart;

  final GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;

  final GestureLongPressUpCallback onLongPressUp;

  final GestureLongPressEndCallback onLongPressEnd;

  final GestureDragDownCallback onVerticalDragDown;

  final GestureDragStartCallback onVerticalDragStart;

  final GestureDragUpdateCallback onVerticalDragUpdate;

  final GestureDragEndCallback onVerticalDragEnd;

  final GestureDragCancelCallback onVerticalDragCancel;

  final GestureDragDownCallback onHorizontalDragDown;

  final GestureDragStartCallback onHorizontalDragStart;

  final GestureDragUpdateCallback onHorizontalDragUpdate;

  final GestureDragEndCallback onHorizontalDragEnd;

  final GestureDragCancelCallback onHorizontalDragCancel;

  final GestureDragDownCallback onPanDown;

  final GestureDragStartCallback onPanStart;

  final GestureDragUpdateCallback onPanUpdate;

  final GestureDragEndCallback onPanEnd;

  final GestureDragCancelCallback onPanCancel;

  final GestureScaleStartCallback onScaleStart;

  final GestureScaleUpdateCallback onScaleUpdate;

  final GestureScaleEndCallback onScaleEnd;

  final GestureForcePressStartCallback onForcePressStart;

  final GestureForcePressPeakCallback onForcePressPeak;

  final GestureForcePressUpdateCallback onForcePressUpdate;

  final GestureForcePressEndCallback onForcePressEnd;

  final HitTestBehavior behavior;

  final bool excludeFromSemantics;

  final DragStartBehavior dragStartBehavior;

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};

    if (onTapDown != null ||
        onTapUp != null ||
        onTap != null ||
        onTapCancel != null ||
        onSecondaryTapDown != null ||
        onSecondaryTapUp != null ||
        onSecondaryTapCancel != null) {
      gestures[TapGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(debugOwner: this),
        (TapGestureRecognizer instance) {
          instance
            ..onTapDown = onTapDown
            ..onTapUp = onTapUp
            ..onTap = onTap
            ..onTapCancel = onTapCancel
            ..onSecondaryTapDown = onSecondaryTapDown
            ..onSecondaryTapUp = onSecondaryTapUp
            ..onSecondaryTapCancel = onSecondaryTapCancel;
        },
      );
    }

    if (onDoubleTap != null) {
      gestures[DoubleTapGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
        () => DoubleTapGestureRecognizer(debugOwner: this),
        (DoubleTapGestureRecognizer instance) {
          instance..onDoubleTap = onDoubleTap;
        },
      );
    }

    if (onLongPress != null ||
        onLongPressUp != null ||
        onLongPressStart != null ||
        onLongPressMoveUpdate != null ||
        onLongPressEnd != null) {
      gestures[LongPressGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(debugOwner: this),
        (LongPressGestureRecognizer instance) {
          instance
            ..onLongPress = onLongPress
            ..onLongPressStart = onLongPressStart
            ..onLongPressMoveUpdate = onLongPressMoveUpdate
            ..onLongPressEnd = onLongPressEnd
            ..onLongPressUp = onLongPressUp;
        },
      );
    }

    if (onVerticalDragDown != null ||
        onVerticalDragStart != null ||
        onVerticalDragUpdate != null ||
        onVerticalDragEnd != null ||
        onVerticalDragCancel != null) {
      gestures[VerticalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
        () => VerticalDragGestureRecognizer(debugOwner: this),
        (VerticalDragGestureRecognizer instance) {
          instance
            ..onDown = onVerticalDragDown
            ..onStart = onVerticalDragStart
            ..onUpdate = onVerticalDragUpdate
            ..onEnd = onVerticalDragEnd
            ..onCancel = onVerticalDragCancel
            ..dragStartBehavior = dragStartBehavior;
        },
      );
    }

    if (onHorizontalDragDown != null ||
        onHorizontalDragStart != null ||
        onHorizontalDragUpdate != null ||
        onHorizontalDragEnd != null ||
        onHorizontalDragCancel != null) {
      gestures[HorizontalDragGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
        () => HorizontalDragGestureRecognizer(debugOwner: this),
        (HorizontalDragGestureRecognizer instance) {
          instance
            ..onDown = onHorizontalDragDown
            ..onStart = onHorizontalDragStart
            ..onUpdate = onHorizontalDragUpdate
            ..onEnd = onHorizontalDragEnd
            ..onCancel = onHorizontalDragCancel
            ..dragStartBehavior = dragStartBehavior;
        },
      );
    }

    if (onPanDown != null ||
        onPanStart != null ||
        onPanUpdate != null ||
        onPanEnd != null ||
        onPanCancel != null) {
      gestures[PanGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
        () => PanGestureRecognizer(debugOwner: this),
        (PanGestureRecognizer instance) {
          instance
            ..onDown = onPanDown
            ..onStart = onPanStart
            ..onUpdate = onPanUpdate
            ..onEnd = onPanEnd
            ..onCancel = onPanCancel
            ..dragStartBehavior = dragStartBehavior;
        },
      );
    }

    if (onScaleStart != null || onScaleUpdate != null || onScaleEnd != null) {
      gestures[ScaleGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
        () => ScaleGestureRecognizer(debugOwner: this),
        (ScaleGestureRecognizer instance) {
          instance
            ..onStart = onScaleStart
            ..onUpdate = onScaleUpdate
            ..onEnd = onScaleEnd;
        },
      );
    }

    if (onForcePressStart != null ||
        onForcePressPeak != null ||
        onForcePressUpdate != null ||
        onForcePressEnd != null) {
      gestures[ForcePressGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
        () => ForcePressGestureRecognizer(debugOwner: this),
        (ForcePressGestureRecognizer instance) {
          instance
            ..onStart = onForcePressStart
            ..onPeak = onForcePressPeak
            ..onUpdate = onForcePressUpdate
            ..onEnd = onForcePressEnd;
        },
      );
    }

    return RawGestureDetector(
      gestures: gestures,
      behavior: behavior,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        EnumProperty<DragStartBehavior>('startBehavior', dragStartBehavior));
  }
}

class RawGestureDetector extends StatefulWidget {
  const RawGestureDetector({
    Key key,
    this.child,
    this.gestures = const <Type, GestureRecognizerFactory>{},
    this.behavior,
    this.excludeFromSemantics = false,
  })  : assert(gestures != null),
        assert(excludeFromSemantics != null),
        super(key: key);

  final Widget child;

  final Map<Type, GestureRecognizerFactory> gestures;

  final HitTestBehavior behavior;

  final bool excludeFromSemantics;

  @override
  RawGestureDetectorState createState() => RawGestureDetectorState();
}

class RawGestureDetectorState extends State<RawGestureDetector> {
  Map<Type, GestureRecognizer> _recognizers = const <Type, GestureRecognizer>{};

  @override
  void initState() {
    super.initState();
    _syncAll(widget.gestures);
  }

  @override
  void didUpdateWidget(RawGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAll(widget.gestures);
  }

  void replaceGestureRecognizers(Map<Type, GestureRecognizerFactory> gestures) {
    assert(() {
      if (!context.findRenderObject().owner.debugDoingLayout) {
        throw FlutterError(
            'Unexpected call to replaceGestureRecognizers() method of RawGestureDetectorState.\n'
            'The replaceGestureRecognizers() method can only be called during the layout phase. '
            'To set the gesture recognizers at other times, trigger a new build using setState() '
            'and provide the new gesture recognizers as constructor arguments to the corresponding '
            'RawGestureDetector or GestureDetector object.');
      }
      return true;
    }());
    _syncAll(gestures);
    if (!widget.excludeFromSemantics) {
      final RenderSemanticsGestureHandler semanticsGestureHandler =
          context.findRenderObject();
      context.visitChildElements((Element element) {
        final _GestureSemantics widget = element.widget;
        widget._updateHandlers(semanticsGestureHandler);
      });
    }
  }

  void replaceSemanticsActions(Set<SemanticsAction> actions) {
    assert(() {
      final Element element = context;
      if (element.owner.debugBuilding) {
        throw FlutterError(
            'Unexpected call to replaceSemanticsActions() method of RawGestureDetectorState.\n'
            'The replaceSemanticsActions() method can only be called outside of the build phase.');
      }
      return true;
    }());
    if (!widget.excludeFromSemantics) {
      final RenderSemanticsGestureHandler semanticsGestureHandler =
          context.findRenderObject();
      semanticsGestureHandler.validActions = actions;
    }
  }

  @override
  void dispose() {
    for (GestureRecognizer recognizer in _recognizers.values)
      recognizer.dispose();
    _recognizers = null;
    super.dispose();
  }

  void _syncAll(Map<Type, GestureRecognizerFactory> gestures) {
    assert(_recognizers != null);
    final Map<Type, GestureRecognizer> oldRecognizers = _recognizers;
    _recognizers = <Type, GestureRecognizer>{};
    for (Type type in gestures.keys) {
      assert(gestures[type] != null);
      assert(gestures[type]._debugAssertTypeMatches(type));
      assert(!_recognizers.containsKey(type));
      _recognizers[type] = oldRecognizers[type] ?? gestures[type].constructor();
      assert(_recognizers[type].runtimeType == type,
          'GestureRecognizerFactory of type $type created a GestureRecognizer of type ${_recognizers[type].runtimeType}. The GestureRecognizerFactory must be specialized with the type of the class that it returns from its constructor method.');
      gestures[type].initializer(_recognizers[type]);
    }
    for (Type type in oldRecognizers.keys) {
      if (!_recognizers.containsKey(type)) oldRecognizers[type].dispose();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    assert(_recognizers != null);
    for (GestureRecognizer recognizer in _recognizers.values)
      recognizer.addPointer(event);
  }

  HitTestBehavior get _defaultBehavior {
    return widget.child == null
        ? HitTestBehavior.translucent
        : HitTestBehavior.deferToChild;
  }

  void _handleSemanticsTap() {
    final TapGestureRecognizer recognizer = _recognizers[TapGestureRecognizer];
    assert(recognizer != null);
    if (recognizer.onTapDown != null) recognizer.onTapDown(TapDownDetails());
    if (recognizer.onTapUp != null) recognizer.onTapUp(TapUpDetails());
    if (recognizer.onTap != null) recognizer.onTap();
  }

  void _handleSemanticsLongPress() {
    final LongPressGestureRecognizer recognizer =
        _recognizers[LongPressGestureRecognizer];
    assert(recognizer != null);
    if (recognizer.onLongPressStart != null)
      recognizer.onLongPressStart(const LongPressStartDetails());
    if (recognizer.onLongPress != null) recognizer.onLongPress();
    if (recognizer.onLongPressEnd != null)
      recognizer.onLongPressEnd(const LongPressEndDetails());
    if (recognizer.onLongPressUp != null) recognizer.onLongPressUp();
  }

  void _handleSemanticsHorizontalDragUpdate(DragUpdateDetails updateDetails) {
    {
      final HorizontalDragGestureRecognizer recognizer =
          _recognizers[HorizontalDragGestureRecognizer];
      if (recognizer != null) {
        if (recognizer.onDown != null) recognizer.onDown(DragDownDetails());
        if (recognizer.onStart != null) recognizer.onStart(DragStartDetails());
        if (recognizer.onUpdate != null) recognizer.onUpdate(updateDetails);
        if (recognizer.onEnd != null)
          recognizer.onEnd(DragEndDetails(primaryVelocity: 0.0));
        return;
      }
    }
    {
      final PanGestureRecognizer recognizer =
          _recognizers[PanGestureRecognizer];
      if (recognizer != null) {
        if (recognizer.onDown != null) recognizer.onDown(DragDownDetails());
        if (recognizer.onStart != null) recognizer.onStart(DragStartDetails());
        if (recognizer.onUpdate != null) recognizer.onUpdate(updateDetails);
        if (recognizer.onEnd != null) recognizer.onEnd(DragEndDetails());
        return;
      }
    }
  }

  void _handleSemanticsVerticalDragUpdate(DragUpdateDetails updateDetails) {
    {
      final VerticalDragGestureRecognizer recognizer =
          _recognizers[VerticalDragGestureRecognizer];
      if (recognizer != null) {
        if (recognizer.onDown != null) recognizer.onDown(DragDownDetails());
        if (recognizer.onStart != null) recognizer.onStart(DragStartDetails());
        if (recognizer.onUpdate != null) recognizer.onUpdate(updateDetails);
        if (recognizer.onEnd != null)
          recognizer.onEnd(DragEndDetails(primaryVelocity: 0.0));
        return;
      }
    }
    {
      final PanGestureRecognizer recognizer =
          _recognizers[PanGestureRecognizer];
      if (recognizer != null) {
        if (recognizer.onDown != null) recognizer.onDown(DragDownDetails());
        if (recognizer.onStart != null) recognizer.onStart(DragStartDetails());
        if (recognizer.onUpdate != null) recognizer.onUpdate(updateDetails);
        if (recognizer.onEnd != null) recognizer.onEnd(DragEndDetails());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result = Listener(
      onPointerDown: _handlePointerDown,
      behavior: widget.behavior ?? _defaultBehavior,
      child: widget.child,
    );
    if (!widget.excludeFromSemantics)
      result = _GestureSemantics(owner: this, child: result);
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_recognizers == null) {
      properties.add(DiagnosticsNode.message('DISPOSED'));
    } else {
      final List<String> gestures = _recognizers.values
          .map<String>(
              (GestureRecognizer recognizer) => recognizer.debugDescription)
          .toList();
      properties.add(
          IterableProperty<String>('gestures', gestures, ifEmpty: '<none>'));
      properties.add(IterableProperty<GestureRecognizer>(
          'recognizers', _recognizers.values,
          level: DiagnosticLevel.fine));
    }
    properties.add(EnumProperty<HitTestBehavior>('behavior', widget.behavior,
        defaultValue: null));
  }
}

class _GestureSemantics extends SingleChildRenderObjectWidget {
  const _GestureSemantics({
    Key key,
    Widget child,
    this.owner,
  }) : super(key: key, child: child);

  final RawGestureDetectorState owner;

  @override
  RenderSemanticsGestureHandler createRenderObject(BuildContext context) {
    return RenderSemanticsGestureHandler(
      onTap: _onTapHandler,
      onLongPress: _onLongPressHandler,
      onHorizontalDragUpdate: _onHorizontalDragUpdateHandler,
      onVerticalDragUpdate: _onVerticalDragUpdateHandler,
    );
  }

  void _updateHandlers(RenderSemanticsGestureHandler renderObject) {
    renderObject
      ..onTap = _onTapHandler
      ..onLongPress = _onLongPressHandler
      ..onHorizontalDragUpdate = _onHorizontalDragUpdateHandler
      ..onVerticalDragUpdate = _onVerticalDragUpdateHandler;
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSemanticsGestureHandler renderObject) {
    _updateHandlers(renderObject);
  }

  GestureTapCallback get _onTapHandler {
    return owner._recognizers.containsKey(TapGestureRecognizer)
        ? owner._handleSemanticsTap
        : null;
  }

  GestureTapCallback get _onLongPressHandler {
    return owner._recognizers.containsKey(LongPressGestureRecognizer)
        ? owner._handleSemanticsLongPress
        : null;
  }

  GestureDragUpdateCallback get _onHorizontalDragUpdateHandler {
    return owner._recognizers.containsKey(HorizontalDragGestureRecognizer) ||
            owner._recognizers.containsKey(PanGestureRecognizer)
        ? owner._handleSemanticsHorizontalDragUpdate
        : null;
  }

  GestureDragUpdateCallback get _onVerticalDragUpdateHandler {
    return owner._recognizers.containsKey(VerticalDragGestureRecognizer) ||
            owner._recognizers.containsKey(PanGestureRecognizer)
        ? owner._handleSemanticsVerticalDragUpdate
        : null;
  }
}

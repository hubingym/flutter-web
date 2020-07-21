import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/services.dart';

import 'basic.dart';
import 'debug.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';

class AndroidView extends StatefulWidget {
  const AndroidView({
    Key key,
    @required this.viewType,
    this.onPlatformViewCreated,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.layoutDirection,
    this.gestureRecognizers,
    this.creationParams,
    this.creationParamsCodec,
  })  : assert(viewType != null),
        assert(hitTestBehavior != null),
        assert(creationParams == null || creationParamsCodec != null),
        super(key: key);

  final String viewType;

  final PlatformViewCreatedCallback onPlatformViewCreated;

  final PlatformViewHitTestBehavior hitTestBehavior;

  final TextDirection layoutDirection;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  final dynamic creationParams;

  final MessageCodec<dynamic> creationParamsCodec;

  @override
  State<AndroidView> createState() => _AndroidViewState();
}

class UiKitView extends StatefulWidget {
  const UiKitView({
    Key key,
    @required this.viewType,
    this.onPlatformViewCreated,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.layoutDirection,
    this.creationParams,
    this.creationParamsCodec,
    this.gestureRecognizers,
  })  : assert(viewType != null),
        assert(hitTestBehavior != null),
        assert(creationParams == null || creationParamsCodec != null),
        super(key: key);

  final String viewType;

  final PlatformViewCreatedCallback onPlatformViewCreated;

  final PlatformViewHitTestBehavior hitTestBehavior;

  final TextDirection layoutDirection;

  final dynamic creationParams;

  final MessageCodec<dynamic> creationParamsCodec;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  State<UiKitView> createState() => _UiKitViewState();
}

class HtmlElementView extends StatelessWidget {
  const HtmlElementView({
    Key key,
    @required this.viewType,
  })  : assert(viewType != null),
        assert(kIsWeb, 'HtmlElementView is only available on Flutter Web.'),
        super(key: key);

  final String viewType;

  @override
  Widget build(BuildContext context) {
    return PlatformViewLink(
      viewType: viewType,
      onCreatePlatformView: _createHtmlElementView,
      surfaceFactory:
          (BuildContext context, PlatformViewController controller) {
        return PlatformViewSurface(
          controller: controller,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
    );
  }

  _HtmlElementViewController _createHtmlElementView(
      PlatformViewCreationParams params) {
    final _HtmlElementViewController controller =
        _HtmlElementViewController(params.id, viewType);
    controller._initialize().then((_) {
      params.onPlatformViewCreated(params.id);
    });
    return controller;
  }
}

class _HtmlElementViewController extends PlatformViewController {
  _HtmlElementViewController(
    this.viewId,
    this.viewType,
  );

  @override
  final int viewId;

  final String viewType;

  bool _initialized = false;

  Future<void> _initialize() async {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': viewId,
      'viewType': viewType,
    };
    await SystemChannels.platform_views.invokeMethod<void>('create', args);
    _initialized = true;
  }

  @override
  void clearFocus() {}

  @override
  void dispatchPointerEvent(PointerEvent event) {}

  @override
  void dispose() {
    if (_initialized) {
      SystemChannels.platform_views.invokeMethod<void>('dispose', viewId);
    }
  }
}

class _AndroidViewState extends State<AndroidView> {
  int _id;
  AndroidViewController _controller;
  TextDirection _layoutDirection;
  bool _initialized = false;
  FocusNode _focusNode;

  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizersSet =
      <Factory<OneSequenceGestureRecognizer>>{};

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onFocusChange: _onFocusChange,
      child: _AndroidPlatformView(
        controller: _controller,
        hitTestBehavior: widget.hitTestBehavior,
        gestureRecognizers: widget.gestureRecognizers ?? _emptyRecognizersSet,
      ),
    );
  }

  void _initializeOnce() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _createNewAndroidView();
    _focusNode = FocusNode(debugLabel: 'AndroidView(id: $_id)');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection =
        _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    _initializeOnce();
    if (didChangeLayoutDirection) {
      _controller.setLayoutDirection(_layoutDirection);
    }
  }

  @override
  void didUpdateWidget(AndroidView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection =
        _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (widget.viewType != oldWidget.viewType) {
      _controller.dispose();
      _createNewAndroidView();
      return;
    }

    if (didChangeLayoutDirection) {
      _controller.setLayoutDirection(_layoutDirection);
    }
  }

  TextDirection _findLayoutDirection() {
    assert(
        widget.layoutDirection != null || debugCheckHasDirectionality(context));
    return widget.layoutDirection ?? Directionality.of(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _createNewAndroidView() {
    _id = platformViewsRegistry.getNextPlatformViewId();
    _controller = PlatformViewsService.initAndroidView(
        id: _id,
        viewType: widget.viewType,
        layoutDirection: _layoutDirection,
        creationParams: widget.creationParams,
        creationParamsCodec: widget.creationParamsCodec,
        onFocus: () {
          _focusNode.requestFocus();
        });
    if (widget.onPlatformViewCreated != null) {
      _controller
          .addOnPlatformViewCreatedListener(widget.onPlatformViewCreated);
    }
  }

  void _onFocusChange(bool isFocused) {
    if (!_controller.isCreated) {
      return;
    }
    if (!isFocused) {
      _controller.clearFocus().catchError((dynamic e) {
        if (e is MissingPluginException) {
          return;
        }
      });
      return;
    }
    SystemChannels.textInput
        .invokeMethod<void>(
      'TextInput.setPlatformViewClient',
      _id,
    )
        .catchError((dynamic e) {
      if (e is MissingPluginException) {
        return;
      }
    });
  }
}

class _UiKitViewState extends State<UiKitView> {
  UiKitViewController _controller;
  TextDirection _layoutDirection;
  bool _initialized = false;

  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizersSet =
      <Factory<OneSequenceGestureRecognizer>>{};

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const SizedBox.expand();
    }
    return _UiKitPlatformView(
      controller: _controller,
      hitTestBehavior: widget.hitTestBehavior,
      gestureRecognizers: widget.gestureRecognizers ?? _emptyRecognizersSet,
    );
  }

  void _initializeOnce() {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _createNewUiKitView();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection =
        _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    _initializeOnce();
    if (didChangeLayoutDirection) {
      _controller?.setLayoutDirection(_layoutDirection);
    }
  }

  @override
  void didUpdateWidget(UiKitView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection =
        _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (widget.viewType != oldWidget.viewType) {
      _controller?.dispose();
      _createNewUiKitView();
      return;
    }

    if (didChangeLayoutDirection) {
      _controller?.setLayoutDirection(_layoutDirection);
    }
  }

  TextDirection _findLayoutDirection() {
    assert(
        widget.layoutDirection != null || debugCheckHasDirectionality(context));
    return widget.layoutDirection ?? Directionality.of(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _createNewUiKitView() async {
    final int id = platformViewsRegistry.getNextPlatformViewId();
    final UiKitViewController controller =
        await PlatformViewsService.initUiKitView(
      id: id,
      viewType: widget.viewType,
      layoutDirection: _layoutDirection,
      creationParams: widget.creationParams,
      creationParamsCodec: widget.creationParamsCodec,
    );
    if (!mounted) {
      controller.dispose();
      return;
    }
    if (widget.onPlatformViewCreated != null) {
      widget.onPlatformViewCreated(id);
    }
    setState(() {
      _controller = controller;
    });
  }
}

class _AndroidPlatformView extends LeafRenderObjectWidget {
  const _AndroidPlatformView({
    Key key,
    @required this.controller,
    @required this.hitTestBehavior,
    @required this.gestureRecognizers,
  })  : assert(controller != null),
        assert(hitTestBehavior != null),
        assert(gestureRecognizers != null),
        super(key: key);

  final AndroidViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderAndroidView(
        viewController: controller,
        hitTestBehavior: hitTestBehavior,
        gestureRecognizers: gestureRecognizers,
      );

  @override
  void updateRenderObject(
      BuildContext context, RenderAndroidView renderObject) {
    renderObject.viewController = controller;
    renderObject.hitTestBehavior = hitTestBehavior;
    renderObject.updateGestureRecognizers(gestureRecognizers);
  }
}

class _UiKitPlatformView extends LeafRenderObjectWidget {
  const _UiKitPlatformView({
    Key key,
    @required this.controller,
    @required this.hitTestBehavior,
    @required this.gestureRecognizers,
  })  : assert(controller != null),
        assert(hitTestBehavior != null),
        assert(gestureRecognizers != null),
        super(key: key);

  final UiKitViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderUiKitView(
      viewController: controller,
      hitTestBehavior: hitTestBehavior,
      gestureRecognizers: gestureRecognizers,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderUiKitView renderObject) {
    renderObject.viewController = controller;
    renderObject.hitTestBehavior = hitTestBehavior;
    renderObject.updateGestureRecognizers(gestureRecognizers);
  }
}

class PlatformViewCreationParams {
  const PlatformViewCreationParams._({
    @required this.id,
    @required this.viewType,
    @required this.onPlatformViewCreated,
    @required this.onFocusChanged,
  })  : assert(id != null),
        assert(onPlatformViewCreated != null);

  final int id;

  final String viewType;

  final PlatformViewCreatedCallback onPlatformViewCreated;

  final ValueChanged<bool> onFocusChanged;
}

typedef PlatformViewSurfaceFactory = Widget Function(
    BuildContext context, PlatformViewController controller);

typedef CreatePlatformViewCallback = PlatformViewController Function(
    PlatformViewCreationParams params);

class PlatformViewLink extends StatefulWidget {
  const PlatformViewLink({
    Key key,
    @required PlatformViewSurfaceFactory surfaceFactory,
    @required CreatePlatformViewCallback onCreatePlatformView,
    @required this.viewType,
  })  : assert(surfaceFactory != null),
        assert(onCreatePlatformView != null),
        assert(viewType != null),
        _surfaceFactory = surfaceFactory,
        _onCreatePlatformView = onCreatePlatformView,
        super(key: key);

  final PlatformViewSurfaceFactory _surfaceFactory;
  final CreatePlatformViewCallback _onCreatePlatformView;

  final String viewType;

  @override
  State<StatefulWidget> createState() => _PlatformViewLinkState();
}

class _PlatformViewLinkState extends State<PlatformViewLink> {
  int _id;
  PlatformViewController _controller;
  bool _platformViewCreated = false;
  Widget _surface;
  FocusNode _focusNode;

  @override
  Widget build(BuildContext context) {
    if (!_platformViewCreated) {
      return const SizedBox.expand();
    }
    _surface ??= widget._surfaceFactory(context, _controller);
    return Focus(
      focusNode: _focusNode,
      onFocusChange: _handleFrameworkFocusChanged,
      child: _surface,
    );
  }

  @override
  void initState() {
    _focusNode = FocusNode(
      debugLabel: 'PlatformView(id: $_id)',
    );
    _initialize();
    super.initState();
  }

  @override
  void didUpdateWidget(PlatformViewLink oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.viewType != oldWidget.viewType) {
      _controller?.dispose();

      _platformViewCreated = false;
      _initialize();
    }
  }

  void _initialize() {
    _id = platformViewsRegistry.getNextPlatformViewId();
    _controller = widget._onCreatePlatformView(
      PlatformViewCreationParams._(
        id: _id,
        viewType: widget.viewType,
        onPlatformViewCreated: _onPlatformViewCreated,
        onFocusChanged: _handlePlatformFocusChanged,
      ),
    );
  }

  void _onPlatformViewCreated(int id) {
    setState(() {
      _platformViewCreated = true;
    });
  }

  void _handleFrameworkFocusChanged(bool isFocused) {
    if (!isFocused) {
      _controller?.clearFocus();
    }
  }

  void _handlePlatformFocusChanged(bool isFocused) {
    if (isFocused) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

class PlatformViewSurface extends LeafRenderObjectWidget {
  const PlatformViewSurface({
    @required this.controller,
    @required this.hitTestBehavior,
    @required this.gestureRecognizers,
  })  : assert(controller != null),
        assert(hitTestBehavior != null),
        assert(gestureRecognizers != null);

  final PlatformViewController controller;

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  final PlatformViewHitTestBehavior hitTestBehavior;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return PlatformViewRenderBox(
        controller: controller,
        gestureRecognizers: gestureRecognizers,
        hitTestBehavior: hitTestBehavior);
  }

  @override
  void updateRenderObject(
      BuildContext context, PlatformViewRenderBox renderObject) {
    renderObject
      ..controller = controller
      ..hitTestBehavior = hitTestBehavior
      ..updateGestureRecognizers(gestureRecognizers);
  }
}

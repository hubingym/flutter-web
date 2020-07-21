import 'dart:developer';
import 'package:flutter_web/io.dart' show Platform;
import 'package:flutter_web/ui.dart' as ui show Scene, SceneBuilder, Window;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart';
import 'package:flutter_web/src/util.dart';
import 'package:vector_math/vector_math_64.dart';

import 'binding.dart';
import 'box.dart';
import 'debug.dart';
import 'layer.dart';
import 'object.dart';

@immutable
class ViewConfiguration {
  const ViewConfiguration({
    this.size = Size.zero,
    this.devicePixelRatio = 1.0,
  });

  final Size size;

  final double devicePixelRatio;

  Matrix4 toMatrix() {
    return Matrix4.diagonal3Values(devicePixelRatio, devicePixelRatio, 1.0);
  }

  @override
  String toString() => assertionsEnabled
      ? '$size at ${debugFormatDouble(devicePixelRatio)}x'
      : super.toString();
}

class RenderView extends RenderObject
    with RenderObjectWithChildMixin<RenderBox> {
  RenderView({
    RenderBox child,
    @required ViewConfiguration configuration,
    @required ui.Window window,
  })  : assert(configuration != null),
        _configuration = configuration,
        _window = window {
    this.child = child;
  }

  Size get size => _size;
  Size _size = Size.zero;

  ViewConfiguration get configuration => _configuration;
  ViewConfiguration _configuration;

  set configuration(ViewConfiguration value) {
    assert(value != null);
    if (configuration == value) return;
    _configuration = value;
    replaceRootLayer(_updateMatricesAndCreateNewRootLayer());
    assert(_rootTransform != null);
    markNeedsLayout();
  }

  ui.Window _window;

  bool automaticSystemUiAdjustment = true;

  void scheduleInitialFrame() {
    assert(owner != null);
    assert(_rootTransform == null);
    scheduleInitialLayout();
    scheduleInitialPaint(_updateMatricesAndCreateNewRootLayer());
    assert(_rootTransform != null);
    owner.requestVisualUpdate();
  }

  Matrix4 _rootTransform;

  Layer _updateMatricesAndCreateNewRootLayer() {
    _rootTransform = configuration.toMatrix();
    final ContainerLayer rootLayer = TransformLayer(transform: _rootTransform);
    rootLayer.attach(this);
    assert(_rootTransform != null);
    return rootLayer;
  }

  @override
  void debugAssertDoesMeetConstraints() {
    assert(false);
  }

  @override
  void performResize() {
    assert(false);
  }

  @override
  void performLayout() {
    assert(_rootTransform != null);
    _size = configuration.size;
    assert(_size.isFinite);

    if (child != null) child.layout(BoxConstraints.tight(_size));
  }

  @override
  void rotate({int oldAngle, int newAngle, Duration time}) {
    assert(false);
  }

  bool hitTest(HitTestResult result, {Offset position}) {
    if (child != null)
      child.hitTest(BoxHitTestResult.wrap(result), position: position);
    result.add(HitTestEntry(this));
    return true;
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) context.paintChild(child, offset);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    assert(_rootTransform != null);
    transform.multiply(_rootTransform);
    super.applyPaintTransform(child, transform);
  }

  void compositeFrame() {
    Timeline.startSync('Compositing', arguments: timelineWhitelistArguments);
    try {
      final ui.SceneBuilder builder = ui.SceneBuilder();
      final ui.Scene scene = layer.buildScene(builder);
      if (automaticSystemUiAdjustment) _updateSystemChrome();
      _window.render(scene);
      scene.dispose();
      assert(() {
        if (debugRepaintRainbowEnabled || debugRepaintTextRainbowEnabled)
          debugCurrentRepaintColor = debugCurrentRepaintColor
              .withHue((debugCurrentRepaintColor.hue + 2.0) % 360.0);
        return true;
      }());
    } finally {
      Timeline.finishSync();
    }
  }

  void _updateSystemChrome() {
    final Rect bounds = paintBounds;
    final Offset top = Offset(
        bounds.center.dx, _window.padding.top / _window.devicePixelRatio);
    final Offset bottom = Offset(bounds.center.dx,
        bounds.center.dy - _window.padding.bottom / _window.devicePixelRatio);
    final SystemUiOverlayStyle upperOverlayStyle =
        layer.find<SystemUiOverlayStyle>(top);

    SystemUiOverlayStyle lowerOverlayStyle;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        lowerOverlayStyle = layer.find<SystemUiOverlayStyle>(bottom);
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        break;
    }

    if (upperOverlayStyle != null || lowerOverlayStyle != null) {
      final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
        statusBarBrightness: upperOverlayStyle?.statusBarBrightness,
        statusBarIconBrightness: upperOverlayStyle?.statusBarIconBrightness,
        statusBarColor: upperOverlayStyle?.statusBarColor,
        systemNavigationBarColor: lowerOverlayStyle?.systemNavigationBarColor,
        systemNavigationBarDividerColor:
            lowerOverlayStyle?.systemNavigationBarDividerColor,
        systemNavigationBarIconBrightness:
            lowerOverlayStyle?.systemNavigationBarIconBrightness,
      );
      SystemChrome.setSystemUIOverlayStyle(overlayStyle);
    }
  }

  @override
  Rect get paintBounds => Offset.zero & (size * configuration.devicePixelRatio);

  @override
  Rect get semanticBounds {
    assert(_rootTransform != null);
    return MatrixUtils.transformRect(_rootTransform, Offset.zero & size);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    assert(() {
      properties.add(DiagnosticsNode.message(
          'debug mode enabled - ${Platform.operatingSystem}'));
      return true;
    }());
    properties.add(DiagnosticsProperty<Size>(
        'window size', _window.physicalSize,
        tooltip: 'in physical pixels'));
    properties.add(DoubleProperty(
        'device pixel ratio', _window.devicePixelRatio,
        tooltip: 'physical pixels per logical pixel'));
    properties.add(DiagnosticsProperty<ViewConfiguration>(
        'configuration', configuration,
        tooltip: 'in logical pixels'));
    if (_window.semanticsEnabled)
      properties.add(DiagnosticsNode.message('semantics enabled'));
  }
}

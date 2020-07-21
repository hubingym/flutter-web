import 'package:flutter_web/rendering.dart';

import 'basic.dart';
import 'framework.dart';

export 'package:flutter_web/rendering.dart' show AxisDirection, GrowthDirection;

class Viewport extends MultiChildRenderObjectWidget {
  Viewport({
    Key key,
    this.axisDirection = AxisDirection.down,
    this.crossAxisDirection,
    this.anchor = 0.0,
    @required this.offset,
    this.center,
    this.cacheExtent,
    List<Widget> slivers = const <Widget>[],
  })  : assert(offset != null),
        assert(slivers != null),
        assert(center == null ||
            slivers.where((Widget child) => child.key == center).length == 1),
        super(key: key, children: slivers);

  final AxisDirection axisDirection;

  final AxisDirection crossAxisDirection;

  final double anchor;

  final ViewportOffset offset;

  final Key center;

  final double cacheExtent;

  static AxisDirection getDefaultCrossAxisDirection(
      BuildContext context, AxisDirection axisDirection) {
    assert(axisDirection != null);
    switch (axisDirection) {
      case AxisDirection.up:
        return textDirectionToAxisDirection(Directionality.of(context));
      case AxisDirection.right:
        return AxisDirection.down;
      case AxisDirection.down:
        return textDirectionToAxisDirection(Directionality.of(context));
      case AxisDirection.left:
        return AxisDirection.down;
    }
    return null;
  }

  @override
  RenderViewport createRenderObject(BuildContext context) {
    return RenderViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      cacheExtent: cacheExtent,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderViewport renderObject) {
    renderObject
      ..axisDirection = axisDirection
      ..crossAxisDirection = crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection)
      ..anchor = anchor
      ..offset = offset
      ..cacheExtent = cacheExtent;
  }

  @override
  _ViewportElement createElement() => _ViewportElement(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
    properties.add(EnumProperty<AxisDirection>(
        'crossAxisDirection', crossAxisDirection,
        defaultValue: null));
    properties.add(DoubleProperty('anchor', anchor));
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
    if (center != null) {
      properties.add(DiagnosticsProperty<Key>('center', center));
    } else if (children.isNotEmpty && children.first.key != null) {
      properties.add(DiagnosticsProperty<Key>('center', children.first.key,
          tooltip: 'implicit'));
    }
  }
}

class _ViewportElement extends MultiChildRenderObjectElement {
  _ViewportElement(Viewport widget) : super(widget);

  @override
  Viewport get widget => super.widget;

  @override
  RenderViewport get renderObject => super.renderObject;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _updateCenter();
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    _updateCenter();
  }

  void _updateCenter() {
    if (widget.center != null) {
      renderObject.center = children
          .singleWhere((Element element) => element.widget.key == widget.center)
          .renderObject;
    } else if (children.isNotEmpty) {
      renderObject.center = children.first.renderObject;
    } else {
      renderObject.center = null;
    }
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where((Element e) {
      final RenderSliver renderSliver = e.renderObject;
      return renderSliver.geometry.visible;
    }).forEach(visitor);
  }
}

class ShrinkWrappingViewport extends MultiChildRenderObjectWidget {
  ShrinkWrappingViewport({
    Key key,
    this.axisDirection = AxisDirection.down,
    this.crossAxisDirection,
    @required this.offset,
    List<Widget> slivers = const <Widget>[],
  })  : assert(offset != null),
        super(key: key, children: slivers);

  final AxisDirection axisDirection;

  final AxisDirection crossAxisDirection;

  final ViewportOffset offset;

  @override
  RenderShrinkWrappingViewport createRenderObject(BuildContext context) {
    return RenderShrinkWrappingViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      offset: offset,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderShrinkWrappingViewport renderObject) {
    renderObject
      ..axisDirection = axisDirection
      ..crossAxisDirection = crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection)
      ..offset = offset;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
    properties.add(EnumProperty<AxisDirection>(
        'crossAxisDirection', crossAxisDirection,
        defaultValue: null));
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
  }
}

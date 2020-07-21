import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/ui.dart' show lerpDouble;
import 'package:flutter_web/widgets.dart';

import 'divider.dart';
import 'material.dart';
import 'shadows.dart';
import 'theme.dart';

@immutable
abstract class MergeableMaterialItem {
  const MergeableMaterialItem(this.key) : assert(key != null);

  final LocalKey key;
}

class MaterialSlice extends MergeableMaterialItem {
  const MaterialSlice({
    @required LocalKey key,
    @required this.child,
  })  : assert(key != null),
        super(key);

  final Widget child;

  @override
  String toString() {
    return 'MergeableSlice(key: $key, child: $child)';
  }
}

class MaterialGap extends MergeableMaterialItem {
  const MaterialGap({@required LocalKey key, this.size = 16.0})
      : assert(key != null),
        super(key);

  final double size;

  @override
  String toString() {
    return 'MaterialGap(key: $key, child: $size)';
  }
}

class MergeableMaterial extends StatefulWidget {
  const MergeableMaterial(
      {Key key,
      this.mainAxis = Axis.vertical,
      this.elevation = 2,
      this.hasDividers = false,
      this.children = const <MergeableMaterialItem>[]})
      : super(key: key);

  final List<MergeableMaterialItem> children;

  final Axis mainAxis;

  final int elevation;

  final bool hasDividers;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('mainAxis', mainAxis));
    properties.add(DoubleProperty('elevation', elevation.toDouble()));
  }

  @override
  _MergeableMaterialState createState() => _MergeableMaterialState();
}

class _AnimationTuple {
  _AnimationTuple(
      {this.controller,
      this.startAnimation,
      this.endAnimation,
      this.gapAnimation,
      this.gapStart = 0.0});

  final AnimationController controller;
  final CurvedAnimation startAnimation;
  final CurvedAnimation endAnimation;
  final CurvedAnimation gapAnimation;
  double gapStart;
}

class _MergeableMaterialState extends State<MergeableMaterial>
    with TickerProviderStateMixin {
  List<MergeableMaterialItem> _children;
  final Map<LocalKey, _AnimationTuple> _animationTuples =
      <LocalKey, _AnimationTuple>{};

  @override
  void initState() {
    super.initState();
    _children = List<MergeableMaterialItem>.from(widget.children);

    for (int i = 0; i < _children.length; i += 1) {
      if (_children[i] is MaterialGap) {
        _initGap(_children[i]);
        _animationTuples[_children[i].key].controller.value = 1.0;
      }
    }
    assert(_debugGapsAreValid(_children));
  }

  void _initGap(MaterialGap gap) {
    final AnimationController controller = AnimationController(
      duration: kThemeAnimationDuration,
      vsync: this,
    );

    final CurvedAnimation startAnimation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);
    final CurvedAnimation endAnimation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);
    final CurvedAnimation gapAnimation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(_handleTick);

    _animationTuples[gap.key] = _AnimationTuple(
        controller: controller,
        startAnimation: startAnimation,
        endAnimation: endAnimation,
        gapAnimation: gapAnimation);
  }

  @override
  void dispose() {
    for (MergeableMaterialItem child in _children) {
      if (child is MaterialGap)
        _animationTuples[child.key].controller.dispose();
    }
    super.dispose();
  }

  void _handleTick() {
    setState(() {});
  }

  bool _debugHasConsecutiveGaps(List<MergeableMaterialItem> children) {
    for (int i = 0; i < widget.children.length - 1; i += 1) {
      if (widget.children[i] is MaterialGap &&
          widget.children[i + 1] is MaterialGap) return true;
    }
    return false;
  }

  bool _debugGapsAreValid(List<MergeableMaterialItem> children) {
    if (_debugHasConsecutiveGaps(children)) return false;

    if (children.isNotEmpty) {
      if (children.first is MaterialGap || children.last is MaterialGap)
        return false;
    }

    return true;
  }

  void _insertChild(int index, MergeableMaterialItem child) {
    _children.insert(index, child);

    if (child is MaterialGap) _initGap(child);
  }

  void _removeChild(int index) {
    final MergeableMaterialItem child = _children.removeAt(index);

    if (child is MaterialGap) _animationTuples[child.key] = null;
  }

  bool _isClosingGap(int index) {
    if (index < _children.length - 1 && _children[index] is MaterialGap) {
      return _animationTuples[_children[index].key].controller.status ==
          AnimationStatus.reverse;
    }

    return false;
  }

  void _removeEmptyGaps() {
    int j = 0;

    while (j < _children.length) {
      if (_children[j] is MaterialGap &&
          _animationTuples[_children[j].key].controller.status ==
              AnimationStatus.dismissed) {
        _removeChild(j);
      } else {
        j += 1;
      }
    }
  }

  @override
  void didUpdateWidget(MergeableMaterial oldWidget) {
    super.didUpdateWidget(oldWidget);

    final Set<LocalKey> oldKeys = oldWidget.children
        .map<LocalKey>((MergeableMaterialItem child) => child.key)
        .toSet();
    final Set<LocalKey> newKeys = widget.children
        .map<LocalKey>((MergeableMaterialItem child) => child.key)
        .toSet();
    final Set<LocalKey> newOnly = newKeys.difference(oldKeys);
    final Set<LocalKey> oldOnly = oldKeys.difference(newKeys);

    final List<MergeableMaterialItem> newChildren = widget.children;
    int i = 0;
    int j = 0;

    assert(_debugGapsAreValid(newChildren));

    _removeEmptyGaps();

    while (i < newChildren.length && j < _children.length) {
      if (newOnly.contains(newChildren[i].key) ||
          oldOnly.contains(_children[j].key)) {
        final int startNew = i;
        final int startOld = j;

        while (newOnly.contains(newChildren[i].key)) i += 1;

        while (oldOnly.contains(_children[j].key) || _isClosingGap(j)) j += 1;

        final int newLength = i - startNew;
        final int oldLength = j - startOld;

        if (newLength > 0) {
          if (oldLength > 1 ||
              oldLength == 1 && _children[startOld] is MaterialSlice) {
            if (newLength == 1 && newChildren[startNew] is MaterialGap) {
              double gapSizeSum = 0.0;

              while (startOld < j) {
                if (_children[startOld] is MaterialGap) {
                  final MaterialGap gap = _children[startOld];
                  gapSizeSum += gap.size;
                }

                _removeChild(startOld);
                j -= 1;
              }

              _insertChild(startOld, newChildren[startNew]);
              _animationTuples[newChildren[startNew].key]
                ..gapStart = gapSizeSum
                ..controller.forward();

              j += 1;
            } else {
              for (int k = 0; k < oldLength; k += 1) _removeChild(startOld);
              for (int k = 0; k < newLength; k += 1)
                _insertChild(startOld + k, newChildren[startNew + k]);

              j += newLength - oldLength;
            }
          } else if (oldLength == 1) {
            if (newLength == 1 &&
                newChildren[startNew] is MaterialGap &&
                _children[startOld].key == newChildren[startNew].key) {
              _animationTuples[newChildren[startNew].key].controller.forward();
            } else {
              final double gapSize = _getGapSize(startOld);

              _removeChild(startOld);

              for (int k = 0; k < newLength; k += 1)
                _insertChild(startOld + k, newChildren[startNew + k]);

              j += newLength - 1;
              double gapSizeSum = 0.0;

              for (int k = startNew; k < i; k += 1) {
                if (newChildren[k] is MaterialGap) {
                  final MaterialGap gap = newChildren[k];
                  gapSizeSum += gap.size;
                }
              }

              for (int k = startNew; k < i; k += 1) {
                if (newChildren[k] is MaterialGap) {
                  final MaterialGap gap = newChildren[k];

                  _animationTuples[gap.key].gapStart =
                      gapSize * gap.size / gapSizeSum;
                  _animationTuples[gap.key].controller
                    ..value = 0.0
                    ..forward();
                }
              }
            }
          } else {
            for (int k = 0; k < newLength; k += 1) {
              _insertChild(startOld + k, newChildren[startNew + k]);

              if (newChildren[startNew + k] is MaterialGap) {
                final MaterialGap gap = newChildren[startNew + k];
                _animationTuples[gap.key].controller.forward();
              }
            }

            j += newLength;
          }
        } else {
          if (oldLength > 1 ||
              oldLength == 1 && _children[startOld] is MaterialSlice) {
            double gapSizeSum = 0.0;

            while (startOld < j) {
              if (_children[startOld] is MaterialGap) {
                final MaterialGap gap = _children[startOld];
                gapSizeSum += gap.size;
              }

              _removeChild(startOld);
              j -= 1;
            }

            if (gapSizeSum != 0.0) {
              final MaterialGap gap =
                  MaterialGap(key: UniqueKey(), size: gapSizeSum);
              _insertChild(startOld, gap);
              _animationTuples[gap.key].gapStart = 0.0;
              _animationTuples[gap.key].controller
                ..value = 1.0
                ..reverse();

              j += 1;
            }
          } else if (oldLength == 1) {
            final MaterialGap gap = _children[startOld];
            _animationTuples[gap.key].gapStart = 0.0;
            _animationTuples[gap.key].controller.reverse();
          }
        }
      } else {
        if ((_children[j] is MaterialGap) == (newChildren[i] is MaterialGap)) {
          _children[j] = newChildren[i];

          i += 1;
          j += 1;
        } else {
          assert(_children[j] is MaterialGap);
          j += 1;
        }
      }
    }

    while (j < _children.length) _removeChild(j);
    while (i < newChildren.length) {
      _insertChild(j, newChildren[i]);

      i += 1;
      j += 1;
    }
  }

  BorderRadius _borderRadius(int index, bool start, bool end) {
    assert(kMaterialEdges[MaterialType.card].topLeft ==
        kMaterialEdges[MaterialType.card].topRight);
    assert(kMaterialEdges[MaterialType.card].topLeft ==
        kMaterialEdges[MaterialType.card].bottomLeft);
    assert(kMaterialEdges[MaterialType.card].topLeft ==
        kMaterialEdges[MaterialType.card].bottomRight);
    final Radius cardRadius = kMaterialEdges[MaterialType.card].topLeft;

    Radius startRadius = Radius.zero;
    Radius endRadius = Radius.zero;

    if (index > 0 && _children[index - 1] is MaterialGap) {
      startRadius = Radius.lerp(Radius.zero, cardRadius,
          _animationTuples[_children[index - 1].key].startAnimation.value);
    }
    if (index < _children.length - 2 && _children[index + 1] is MaterialGap) {
      endRadius = Radius.lerp(Radius.zero, cardRadius,
          _animationTuples[_children[index + 1].key].endAnimation.value);
    }

    if (widget.mainAxis == Axis.vertical) {
      return BorderRadius.vertical(
          top: start ? cardRadius : startRadius,
          bottom: end ? cardRadius : endRadius);
    } else {
      return BorderRadius.horizontal(
          left: start ? cardRadius : startRadius,
          right: end ? cardRadius : endRadius);
    }
  }

  double _getGapSize(int index) {
    final MaterialGap gap = _children[index];

    return lerpDouble(_animationTuples[gap.key].gapStart, gap.size,
        _animationTuples[gap.key].gapAnimation.value);
  }

  bool _willNeedDivider(int index) {
    if (index < 0) return false;
    if (index >= _children.length) return false;
    return _children[index] is MaterialSlice || _isClosingGap(index);
  }

  @override
  Widget build(BuildContext context) {
    _removeEmptyGaps();

    final List<Widget> widgets = <Widget>[];
    List<Widget> slices = <Widget>[];
    int i;

    for (i = 0; i < _children.length; i += 1) {
      if (_children[i] is MaterialGap) {
        assert(slices.isNotEmpty);
        widgets.add(Container(
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: _borderRadius(i - 1, widgets.isEmpty, false),
                shape: BoxShape.rectangle),
            child: ListBody(mainAxis: widget.mainAxis, children: slices)));
        slices = <Widget>[];

        widgets.add(SizedBox(
            width: widget.mainAxis == Axis.horizontal ? _getGapSize(i) : null,
            height: widget.mainAxis == Axis.vertical ? _getGapSize(i) : null));
      } else {
        final MaterialSlice slice = _children[i];
        Widget child = slice.child;

        if (widget.hasDividers) {
          final bool hasTopDivider = _willNeedDivider(i - 1);
          final bool hasBottomDivider = _willNeedDivider(i + 1);

          Border border;
          final BorderSide divider = Divider.createBorderSide(
            context,
            width: 0.5,
          );

          if (i == 0) {
            border =
                Border(bottom: hasBottomDivider ? divider : BorderSide.none);
          } else if (i == _children.length - 1) {
            border = Border(top: hasTopDivider ? divider : BorderSide.none);
          } else {
            border = Border(
                top: hasTopDivider ? divider : BorderSide.none,
                bottom: hasBottomDivider ? divider : BorderSide.none);
          }

          assert(border != null);

          child = AnimatedContainer(
              key: _MergeableMaterialSliceKey(_children[i].key),
              decoration: BoxDecoration(border: border),
              duration: kThemeAnimationDuration,
              curve: Curves.fastOutSlowIn,
              child: child);
        }

        slices.add(Material(type: MaterialType.transparency, child: child));
      }
    }

    if (slices.isNotEmpty) {
      widgets.add(Container(
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: _borderRadius(i - 1, widgets.isEmpty, true),
              shape: BoxShape.rectangle),
          child: ListBody(mainAxis: widget.mainAxis, children: slices)));
      slices = <Widget>[];
    }

    return _MergeableMaterialListBody(
        mainAxis: widget.mainAxis,
        boxShadows: kElevationToShadow[widget.elevation],
        items: _children,
        children: widgets);
  }
}

class _MergeableMaterialSliceKey extends GlobalKey {
  const _MergeableMaterialSliceKey(this.value) : super.constructor();

  final LocalKey value;

  @override
  bool operator ==(dynamic other) {
    if (other is! _MergeableMaterialSliceKey) return false;
    final _MergeableMaterialSliceKey typedOther = other;
    return value == typedOther.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return '_MergeableMaterialSliceKey($value)';
  }
}

class _MergeableMaterialListBody extends ListBody {
  _MergeableMaterialListBody(
      {List<Widget> children,
      Axis mainAxis = Axis.vertical,
      this.items,
      this.boxShadows})
      : super(children: children, mainAxis: mainAxis);

  final List<MergeableMaterialItem> items;
  final List<BoxShadow> boxShadows;

  AxisDirection _getDirection(BuildContext context) {
    return getAxisDirectionFromAxisReverseAndDirectionality(
        context, mainAxis, false);
  }

  @override
  RenderListBody createRenderObject(BuildContext context) {
    return _RenderMergeableMaterialListBody(
      axisDirection: _getDirection(context),
      boxShadows: boxShadows,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderListBody renderObject) {
    final _RenderMergeableMaterialListBody materialRenderListBody =
        renderObject;
    materialRenderListBody
      ..axisDirection = _getDirection(context)
      ..boxShadows = boxShadows;
  }
}

class _RenderMergeableMaterialListBody extends RenderListBody {
  _RenderMergeableMaterialListBody(
      {List<RenderBox> children,
      AxisDirection axisDirection = AxisDirection.down,
      this.boxShadows})
      : super(children: children, axisDirection: axisDirection);

  List<BoxShadow> boxShadows;

  void _paintShadows(Canvas canvas, Rect rect) {
    for (BoxShadow boxShadow in boxShadows) {
      final Paint paint = boxShadow.toPaint();

      canvas.drawRRect(kMaterialEdges[MaterialType.card].toRRect(rect), paint);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox child = firstChild;
    int i = 0;

    while (child != null) {
      final ListBodyParentData childParentData = child.parentData;
      final Rect rect = (childParentData.offset + offset) & child.size;
      if (i % 2 == 0) _paintShadows(context.canvas, rect);
      child = childParentData.nextSibling;

      i += 1;
    }

    defaultPaint(context, offset);
  }
}

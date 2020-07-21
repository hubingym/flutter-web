import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/ui.dart' show Clip;
import 'package:flutter_web/widgets.dart';

import 'material.dart';
import 'scaffold.dart';
import 'theme.dart';

class BottomAppBar extends StatefulWidget {
  const BottomAppBar({
    Key key,
    this.color,
    this.elevation = 8.0,
    this.shape,
    this.clipBehavior = Clip.none,
    this.notchMargin = 4.0,
    this.child,
  })  : assert(elevation != null),
        assert(elevation >= 0.0),
        assert(clipBehavior != null),
        super(key: key);

  final Widget child;

  final Color color;

  final double elevation;

  final NotchedShape shape;

  final Clip clipBehavior;

  final double notchMargin;

  @override
  State createState() => _BottomAppBarState();
}

class _BottomAppBarState extends State<BottomAppBar> {
  ValueListenable<ScaffoldGeometry> geometryListenable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    geometryListenable = Scaffold.geometryOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final CustomClipper<Path> clipper = widget.shape != null
        ? _BottomAppBarClipper(
            geometry: geometryListenable,
            shape: widget.shape,
            notchMargin: widget.notchMargin,
          )
        : const ShapeBorderClipper(shape: RoundedRectangleBorder());
    return PhysicalShape(
      clipper: clipper,
      elevation: widget.elevation,
      color: widget.color ?? Theme.of(context).bottomAppBarColor,
      clipBehavior: widget.clipBehavior,
      child: Material(
        type: MaterialType.transparency,
        child: widget.child == null ? null : SafeArea(child: widget.child),
      ),
    );
  }
}

class _BottomAppBarClipper extends CustomClipper<Path> {
  const _BottomAppBarClipper({
    @required this.geometry,
    @required this.shape,
    @required this.notchMargin,
  })  : assert(geometry != null),
        assert(shape != null),
        assert(notchMargin != null),
        super(reclip: geometry);

  final ValueListenable<ScaffoldGeometry> geometry;
  final NotchedShape shape;
  final double notchMargin;

  @override
  Path getClip(Size size) {
    final Rect appBar = Offset.zero & size;
    if (geometry.value.floatingActionButtonArea == null) {
      return Path()..addRect(appBar);
    }

    final Rect button = geometry.value.floatingActionButtonArea
        .translate(0.0, geometry.value.bottomNavigationBarTop * -1.0);

    return shape.getOuterPath(appBar, button.inflate(notchMargin));
  }

  @override
  bool shouldReclip(_BottomAppBarClipper oldClipper) =>
      oldClipper.geometry != geometry;
}

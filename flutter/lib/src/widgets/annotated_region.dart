import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';

import 'framework.dart';

class AnnotatedRegion<T> extends SingleChildRenderObjectWidget {
  const AnnotatedRegion({
    Key key,
    @required Widget child,
    @required this.value,
    this.sized = true,
  })  : assert(value != null),
        assert(child != null),
        super(key: key, child: child);

  final T value;

  final bool sized;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderAnnotatedRegion<T>(value: value, sized: sized);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderAnnotatedRegion<T> renderObject) {
    renderObject
      ..value = value
      ..sized = sized;
  }
}

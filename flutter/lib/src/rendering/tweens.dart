import 'package:flutter_web/animation.dart';
import 'package:flutter_web/painting.dart';

class FractionalOffsetTween extends Tween<FractionalOffset> {
  FractionalOffsetTween({FractionalOffset begin, FractionalOffset end})
      : super(begin: begin, end: end);

  @override
  FractionalOffset lerp(double t) => FractionalOffset.lerp(begin, end, t);
}

class AlignmentTween extends Tween<Alignment> {
  AlignmentTween({Alignment begin, Alignment end})
      : super(begin: begin, end: end);

  @override
  Alignment lerp(double t) => Alignment.lerp(begin, end, t);
}

class AlignmentGeometryTween extends Tween<AlignmentGeometry> {
  AlignmentGeometryTween({
    AlignmentGeometry begin,
    AlignmentGeometry end,
  }) : super(begin: begin, end: end);

  @override
  AlignmentGeometry lerp(double t) => AlignmentGeometry.lerp(begin, end, t);
}

import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/rendering.dart';

import 'framework.dart';

abstract class ScrollContext {
  BuildContext get notificationContext;

  BuildContext get storageContext;

  TickerProvider get vsync;

  AxisDirection get axisDirection;

  void setIgnorePointer(bool value);

  void setCanDrag(bool value);

  void setSemanticsActions(Set<SemanticsAction> actions);
}

import 'package:flutter_web/rendering.dart';

import 'basic.dart';
import 'framework.dart';

class Spacer extends StatelessWidget {
  const Spacer({Key key, this.flex = 1})
      : assert(flex != null),
        assert(flex > 0),
        super(key: key);

  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: const SizedBox.shrink(),
    );
  }
}

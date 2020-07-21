import 'basic.dart';
import 'framework.dart';
import 'layout_builder.dart';
import 'media_query.dart';

typedef OrientationWidgetBuilder = Widget Function(
    BuildContext context, Orientation orientation);

class OrientationBuilder extends StatelessWidget {
  const OrientationBuilder({
    Key key,
    @required this.builder,
  })  : assert(builder != null),
        super(key: key);

  final OrientationWidgetBuilder builder;

  Widget _buildWithConstraints(
      BuildContext context, BoxConstraints constraints) {
    final Orientation orientation = constraints.maxWidth > constraints.maxHeight
        ? Orientation.landscape
        : Orientation.portrait;
    return builder(context, orientation);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildWithConstraints);
  }
}

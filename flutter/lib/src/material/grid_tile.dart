import 'package:flutter_web/widgets.dart';

class GridTile extends StatelessWidget {
  const GridTile({
    Key key,
    this.header,
    this.footer,
    @required this.child,
  })  : assert(child != null),
        super(key: key);

  final Widget header;

  final Widget footer;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (header == null && footer == null) return child;

    final List<Widget> children = <Widget>[
      Positioned.fill(
        child: child,
      ),
    ];
    if (header != null) {
      children.add(Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        child: header,
      ));
    }
    if (footer != null) {
      children.add(Positioned(
        left: 0.0,
        bottom: 0.0,
        right: 0.0,
        child: footer,
      ));
    }
    return Stack(children: children);
  }
}

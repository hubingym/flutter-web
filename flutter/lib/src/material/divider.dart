import 'package:flutter_web/material.dart';

class Divider extends StatelessWidget {
  const Divider({Key key, this.height = 16.0, this.indent = 0.0, this.color})
      : assert(height >= 0.0),
        super(key: key);

  final double height;

  final double indent;

  final Color color;

  static BorderSide createBorderSide(BuildContext context,
      {Color color, double width = 0.0}) {
    assert(width != null);
    return BorderSide(
      color: color ?? Theme.of(context).dividerColor,
      width: width,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Container(
          height: 0.0,
          margin: EdgeInsetsDirectional.only(start: indent),
          decoration: BoxDecoration(
            border: Border(
              bottom: createBorderSide(context, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class VerticalDivider extends StatelessWidget {
  const VerticalDivider(
      {Key key, this.width = 16.0, this.indent = 0.0, this.color})
      : assert(width >= 0.0),
        super(key: key);

  final double width;

  final double indent;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: Container(
          width: 0.0,
          margin: EdgeInsetsDirectional.only(start: indent),
          decoration: BoxDecoration(
            border: Border(
              left: Divider.createBorderSide(context, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

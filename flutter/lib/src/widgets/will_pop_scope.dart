import 'framework.dart';
import 'navigator.dart';
import 'routes.dart';

class WillPopScope extends StatefulWidget {
  const WillPopScope({
    Key key,
    @required this.child,
    @required this.onWillPop,
  })  : assert(child != null),
        super(key: key);

  final Widget child;

  final WillPopCallback onWillPop;

  @override
  _WillPopScopeState createState() => _WillPopScopeState();
}

class _WillPopScopeState extends State<WillPopScope> {
  ModalRoute<dynamic> _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.onWillPop != null)
      _route?.removeScopedWillPopCallback(widget.onWillPop);
    _route = ModalRoute.of(context);
    if (widget.onWillPop != null)
      _route?.addScopedWillPopCallback(widget.onWillPop);
  }

  @override
  void didUpdateWidget(WillPopScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(_route == ModalRoute.of(context));
    if (widget.onWillPop != oldWidget.onWillPop && _route != null) {
      if (oldWidget.onWillPop != null)
        _route.removeScopedWillPopCallback(oldWidget.onWillPop);
      if (widget.onWillPop != null)
        _route.addScopedWillPopCallback(widget.onWillPop);
    }
  }

  @override
  void dispose() {
    if (widget.onWillPop != null)
      _route?.removeScopedWillPopCallback(widget.onWillPop);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

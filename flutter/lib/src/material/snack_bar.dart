import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'button_theme.dart';
import 'flat_button.dart';
import 'material.dart';
import 'scaffold.dart';
import 'theme.dart';
import 'theme_data.dart';

const double _kSnackBarPadding = 24.0;
const double _kSingleLineVerticalPadding = 14.0;
const Color _kSnackBackground = Color(0xFF323232);

const Duration _kSnackBarTransitionDuration = Duration(milliseconds: 250);
const Duration _kSnackBarDisplayDuration = Duration(milliseconds: 4000);
const Curve _snackBarHeightCurve = Curves.fastOutSlowIn;
const Curve _snackBarFadeCurve =
    Interval(0.72, 1.0, curve: Curves.fastOutSlowIn);

enum SnackBarClosedReason {
  action,

  dismiss,

  swipe,

  hide,

  remove,

  timeout,
}

class SnackBarAction extends StatefulWidget {
  const SnackBarAction({
    Key key,
    @required this.label,
    @required this.onPressed,
  })  : assert(label != null),
        assert(onPressed != null),
        super(key: key);

  final String label;

  final VoidCallback onPressed;

  @override
  _SnackBarActionState createState() => _SnackBarActionState();
}

class _SnackBarActionState extends State<SnackBarAction> {
  bool _haveTriggeredAction = false;

  void _handlePressed() {
    if (_haveTriggeredAction) return;
    setState(() {
      _haveTriggeredAction = true;
    });
    widget.onPressed();
    Scaffold.of(context)
        .hideCurrentSnackBar(reason: SnackBarClosedReason.action);
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: _haveTriggeredAction ? null : _handlePressed,
      child: Text(widget.label),
    );
  }
}

class SnackBar extends StatelessWidget {
  const SnackBar({
    Key key,
    @required this.content,
    this.backgroundColor,
    this.action,
    this.duration = _kSnackBarDisplayDuration,
    this.animation,
  })  : assert(content != null),
        super(key: key);

  final Widget content;

  final Color backgroundColor;

  final SnackBarAction action;

  final Duration duration;

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    assert(animation != null);
    final ThemeData theme = Theme.of(context);
    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      accentColor: theme.accentColor,
      accentColorBrightness: theme.accentColorBrightness,
    );
    final List<Widget> children = <Widget>[
      const SizedBox(width: _kSnackBarPadding),
      Expanded(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: _kSingleLineVerticalPadding),
          child: DefaultTextStyle(
            style: darkTheme.textTheme.subhead,
            child: content,
          ),
        ),
      ),
    ];
    if (action != null) {
      children.add(ButtonTheme.bar(
        padding: const EdgeInsets.symmetric(horizontal: _kSnackBarPadding),
        textTheme: ButtonTextTheme.accent,
        child: action,
      ));
    } else {
      children.add(const SizedBox(width: _kSnackBarPadding));
    }
    final CurvedAnimation heightAnimation =
        CurvedAnimation(parent: animation, curve: _snackBarHeightCurve);
    final CurvedAnimation fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: _snackBarFadeCurve,
        reverseCurve: const Threshold(0.0));
    Widget snackbar = SafeArea(
      top: false,
      child: Row(
        children: children,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
    );
    snackbar = Semantics(
      container: true,
      liveRegion: true,
      onDismiss: () {
        Scaffold.of(context)
            .removeCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
      },
      child: Dismissible(
        key: const Key('dismissible'),
        direction: DismissDirection.down,
        resizeDuration: null,
        onDismissed: (DismissDirection direction) {
          Scaffold.of(context)
              .removeCurrentSnackBar(reason: SnackBarClosedReason.swipe);
        },
        child: Material(
          elevation: 6.0,
          color: backgroundColor ?? _kSnackBackground,
          child: Theme(
            data: darkTheme,
            child: mediaQueryData.accessibleNavigation
                ? snackbar
                : FadeTransition(
                    opacity: fadeAnimation,
                    child: snackbar,
                  ),
          ),
        ),
      ),
    );
    return ClipRect(
      child: mediaQueryData.accessibleNavigation
          ? snackbar
          : AnimatedBuilder(
              animation: heightAnimation,
              builder: (BuildContext context, Widget child) {
                return Align(
                  alignment: AlignmentDirectional.topStart,
                  heightFactor: heightAnimation.value,
                  child: child,
                );
              },
              child: snackbar,
            ),
    );
  }

  static AnimationController createAnimationController(
      {@required TickerProvider vsync}) {
    return AnimationController(
      duration: _kSnackBarTransitionDuration,
      debugLabel: 'SnackBar',
      vsync: vsync,
    );
  }

  SnackBar withAnimation(Animation<double> newAnimation, {Key fallbackKey}) {
    return SnackBar(
      key: key ?? fallbackKey,
      content: content,
      backgroundColor: backgroundColor,
      action: action,
      duration: duration,
      animation: newAnimation,
    );
  }
}

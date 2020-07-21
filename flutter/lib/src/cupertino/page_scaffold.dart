import 'package:flutter_web/widgets.dart';

import 'theme.dart';

class CupertinoPageScaffold extends StatefulWidget {
  const CupertinoPageScaffold({
    Key key,
    this.navigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    @required this.child,
  })  : assert(child != null),
        assert(resizeToAvoidBottomInset != null),
        super(key: key);

  final ObstructingPreferredSizeWidget navigationBar;

  final Widget child;

  final Color backgroundColor;

  final bool resizeToAvoidBottomInset;

  @override
  _CupertinoPageScaffoldState createState() => _CupertinoPageScaffoldState();
}

class _CupertinoPageScaffoldState extends State<CupertinoPageScaffold> {
  final ScrollController _primaryScrollController = ScrollController();

  void _handleStatusBarTap() {
    if (_primaryScrollController.hasClients) {
      _primaryScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.linearToEaseOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> stacked = <Widget>[];

    Widget paddedContent = widget.child;

    final MediaQueryData existingMediaQuery = MediaQuery.of(context);
    if (widget.navigationBar != null) {
      final double topPadding = widget.navigationBar.preferredSize.height +
          existingMediaQuery.padding.top;

      final double bottomPadding = widget.resizeToAvoidBottomInset
          ? existingMediaQuery.viewInsets.bottom
          : 0.0;

      final EdgeInsets newViewInsets = widget.resizeToAvoidBottomInset
          ? existingMediaQuery.viewInsets.copyWith(bottom: 0.0)
          : existingMediaQuery.viewInsets;

      final bool fullObstruction = widget.navigationBar.fullObstruction ??
          CupertinoTheme.of(context).barBackgroundColor.alpha == 0xFF;

      if (fullObstruction) {
        paddedContent = MediaQuery(
          data: existingMediaQuery.removePadding(removeTop: true).copyWith(
                viewInsets: newViewInsets,
              ),
          child: Padding(
            padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
            child: paddedContent,
          ),
        );
      } else {
        paddedContent = MediaQuery(
          data: existingMediaQuery.copyWith(
            padding: existingMediaQuery.padding.copyWith(
              top: topPadding,
            ),
            viewInsets: newViewInsets,
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: paddedContent,
          ),
        );
      }
    }

    stacked.add(PrimaryScrollController(
      controller: _primaryScrollController,
      child: paddedContent,
    ));

    if (widget.navigationBar != null) {
      stacked.add(Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        child: widget.navigationBar,
      ));
    }

    stacked.add(
      Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        height: existingMediaQuery.padding.top,
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: _handleStatusBarTap,
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            CupertinoTheme.of(context).scaffoldBackgroundColor,
      ),
      child: Stack(
        children: stacked,
      ),
    );
  }
}

abstract class ObstructingPreferredSizeWidget extends PreferredSizeWidget {
  bool get fullObstruction;
}

import 'dart:math' as math;

import 'package:flutter_web/widgets.dart';
import 'package:flutter_web/rendering.dart';

import 'colors.dart';
import 'debug.dart';
import 'drawer_header.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'material_localizations.dart';
import 'theme.dart';

class _AccountPictures extends StatelessWidget {
  const _AccountPictures({
    Key key,
    this.currentAccountPicture,
    this.otherAccountsPictures,
  }) : super(key: key);

  final Widget currentAccountPicture;
  final List<Widget> otherAccountsPictures;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        PositionedDirectional(
          top: 0.0,
          end: 0.0,
          child: Row(
            children: (otherAccountsPictures ?? <Widget>[])
                .take(3)
                .map<Widget>((Widget picture) {
              return Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: Semantics(
                    container: true,
                    child: Container(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      width: 48.0,
                      height: 48.0,
                      child: picture,
                    ),
                  ));
            }).toList(),
          ),
        ),
        Positioned(
          top: 0.0,
          child: Semantics(
            explicitChildNodes: true,
            child: SizedBox(
                width: 72.0, height: 72.0, child: currentAccountPicture),
          ),
        ),
      ],
    );
  }
}

class _AccountDetails extends StatefulWidget {
  const _AccountDetails({
    Key key,
    @required this.accountName,
    @required this.accountEmail,
    this.onTap,
    this.isOpen,
  }) : super(key: key);

  final Widget accountName;
  final Widget accountEmail;
  final VoidCallback onTap;
  final bool isOpen;

  @override
  _AccountDetailsState createState() => _AccountDetailsState();
}

class _AccountDetailsState extends State<_AccountDetails>
    with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: widget.isOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn.flipped,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AccountDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_animation.status == AnimationStatus.dismissed ||
        _animation.status == AnimationStatus.reverse) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    assert(debugCheckHasMaterialLocalizations(context));
    assert(debugCheckHasMaterialLocalizations(context));

    final ThemeData theme = Theme.of(context);
    final List<Widget> children = <Widget>[];

    if (widget.accountName != null) {
      final Widget accountNameLine = LayoutId(
        id: _AccountDetailsLayout.accountName,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: DefaultTextStyle(
            style: theme.primaryTextTheme.body2,
            overflow: TextOverflow.ellipsis,
            child: widget.accountName,
          ),
        ),
      );
      children.add(accountNameLine);
    }

    if (widget.accountEmail != null) {
      final Widget accountEmailLine = LayoutId(
        id: _AccountDetailsLayout.accountEmail,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: DefaultTextStyle(
            style: theme.primaryTextTheme.body1,
            overflow: TextOverflow.ellipsis,
            child: widget.accountEmail,
          ),
        ),
      );
      children.add(accountEmailLine);
    }
    if (widget.onTap != null) {
      final MaterialLocalizations localizations =
          MaterialLocalizations.of(context);
      final Widget dropDownIcon = LayoutId(
        id: _AccountDetailsLayout.dropdownIcon,
        child: Semantics(
          container: true,
          button: true,
          onTap: widget.onTap,
          child: SizedBox(
            height: _kAccountDetailsHeight,
            width: _kAccountDetailsHeight,
            child: Center(
              child: Transform.rotate(
                angle: _animation.value * math.pi,
                child: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  semanticLabel: widget.isOpen
                      ? localizations.hideAccountsLabel
                      : localizations.showAccountsLabel,
                ),
              ),
            ),
          ),
        ),
      );
      children.add(dropDownIcon);
    }

    Widget accountDetails = CustomMultiChildLayout(
      delegate: _AccountDetailsLayout(
        textDirection: Directionality.of(context),
      ),
      children: children,
    );

    if (widget.onTap != null) {
      accountDetails = InkWell(
        onTap: widget.onTap,
        child: accountDetails,
        excludeFromSemantics: true,
      );
    }

    return SizedBox(
      height: _kAccountDetailsHeight,
      child: accountDetails,
    );
  }
}

const double _kAccountDetailsHeight = 56.0;

class _AccountDetailsLayout extends MultiChildLayoutDelegate {
  _AccountDetailsLayout({@required this.textDirection});

  static const String accountName = 'accountName';
  static const String accountEmail = 'accountEmail';
  static const String dropdownIcon = 'dropdownIcon';

  final TextDirection textDirection;

  @override
  void performLayout(Size size) {
    Size iconSize;
    if (hasChild(dropdownIcon)) {
      iconSize = layoutChild(dropdownIcon, BoxConstraints.loose(size));
      positionChild(dropdownIcon, _offsetForIcon(size, iconSize));
    }

    final String bottomLine = hasChild(accountEmail)
        ? accountEmail
        : (hasChild(accountName) ? accountName : null);

    if (bottomLine != null) {
      final Size constraintSize =
          iconSize == null ? size : size - Offset(iconSize.width, 0.0);
      iconSize ??= const Size(_kAccountDetailsHeight, _kAccountDetailsHeight);

      final Size bottomLineSize =
          layoutChild(bottomLine, BoxConstraints.loose(constraintSize));
      final Offset bottomLineOffset =
          _offsetForBottomLine(size, iconSize, bottomLineSize);
      positionChild(bottomLine, bottomLineOffset);

      if (bottomLine == accountEmail && hasChild(accountName)) {
        final Size nameSize =
            layoutChild(accountName, BoxConstraints.loose(constraintSize));
        positionChild(
            accountName, _offsetForName(size, nameSize, bottomLineOffset));
      }
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) => true;

  Offset _offsetForIcon(Size size, Size iconSize) {
    switch (textDirection) {
      case TextDirection.ltr:
        return Offset(
            size.width - iconSize.width, size.height - iconSize.height);
      case TextDirection.rtl:
        return Offset(0.0, size.height - iconSize.height);
    }
    assert(false, 'Unreachable');
    return null;
  }

  Offset _offsetForBottomLine(Size size, Size iconSize, Size bottomLineSize) {
    final double y =
        size.height - 0.5 * iconSize.height - 0.5 * bottomLineSize.height;
    switch (textDirection) {
      case TextDirection.ltr:
        return Offset(0.0, y);
      case TextDirection.rtl:
        return Offset(size.width - bottomLineSize.width, y);
    }
    assert(false, 'Unreachable');
    return null;
  }

  Offset _offsetForName(Size size, Size nameSize, Offset bottomLineOffset) {
    final double y = bottomLineOffset.dy - nameSize.height;
    switch (textDirection) {
      case TextDirection.ltr:
        return Offset(0.0, y);
      case TextDirection.rtl:
        return Offset(size.width - nameSize.width, y);
    }
    assert(false, 'Unreachable');
    return null;
  }
}

class UserAccountsDrawerHeader extends StatefulWidget {
  const UserAccountsDrawerHeader(
      {Key key,
      this.decoration,
      this.margin = const EdgeInsets.only(bottom: 8.0),
      this.currentAccountPicture,
      this.otherAccountsPictures,
      @required this.accountName,
      @required this.accountEmail,
      this.onDetailsPressed})
      : super(key: key);

  final Decoration decoration;

  final EdgeInsetsGeometry margin;

  final Widget currentAccountPicture;

  final List<Widget> otherAccountsPictures;

  final Widget accountName;

  final Widget accountEmail;

  final VoidCallback onDetailsPressed;

  @override
  _UserAccountsDrawerHeaderState createState() =>
      _UserAccountsDrawerHeaderState();
}

class _UserAccountsDrawerHeaderState extends State<UserAccountsDrawerHeader> {
  bool _isOpen = false;

  void _handleDetailsPressed() {
    setState(() {
      _isOpen = !_isOpen;
    });
    widget.onDetailsPressed();
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    return Semantics(
      container: true,
      label: MaterialLocalizations.of(context).signedInLabel,
      child: DrawerHeader(
        decoration: widget.decoration ??
            BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
        margin: widget.margin,
        padding: const EdgeInsetsDirectional.only(top: 16.0, start: 16.0),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                  child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 16.0),
                child: _AccountPictures(
                  currentAccountPicture: widget.currentAccountPicture,
                  otherAccountsPictures: widget.otherAccountsPictures,
                ),
              )),
              _AccountDetails(
                accountName: widget.accountName,
                accountEmail: widget.accountEmail,
                isOpen: _isOpen,
                onTap: widget.onDetailsPressed == null
                    ? null
                    : _handleDetailsPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

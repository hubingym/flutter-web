import 'package:flutter_web/widgets.dart';
import 'bottom_tab_bar.dart';
import 'theme.dart';

class CupertinoTabController extends ChangeNotifier {
  CupertinoTabController({int initialIndex = 0})
      : _index = initialIndex,
        assert(initialIndex != null),
        assert(initialIndex >= 0);

  bool _isDisposed = false;

  int get index => _index;
  int _index;
  set index(int value) {
    assert(value != null);
    assert(value >= 0);
    if (_index == value) {
      return;
    }
    _index = value;
    notifyListeners();
  }

  @mustCallSuper
  @override
  void dispose() {
    super.dispose();
    _isDisposed = true;
  }
}

class CupertinoTabScaffold extends StatefulWidget {
  CupertinoTabScaffold({
    Key key,
    @required this.tabBar,
    @required this.tabBuilder,
    this.controller,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  })  : assert(tabBar != null),
        assert(tabBuilder != null),
        assert(
            controller == null || controller.index < tabBar.items.length,
            "The CupertinoTabController's current index ${controller.index} is "
            'out of bounds for the tab bar with ${tabBar.items.length} tabs'),
        super(key: key);

  final CupertinoTabBar tabBar;

  final CupertinoTabController controller;

  final IndexedWidgetBuilder tabBuilder;

  final Color backgroundColor;

  final bool resizeToAvoidBottomInset;

  @override
  _CupertinoTabScaffoldState createState() => _CupertinoTabScaffoldState();
}

class _CupertinoTabScaffoldState extends State<CupertinoTabScaffold> {
  CupertinoTabController _controller;

  @override
  void initState() {
    super.initState();
    _updateTabController();
  }

  void _updateTabController({bool shouldDisposeOldController = false}) {
    final CupertinoTabController newController = widget.controller ??
        CupertinoTabController(initialIndex: widget.tabBar.currentIndex);

    if (newController == _controller) {
      return;
    }

    if (shouldDisposeOldController) {
      _controller?.dispose();
    } else if (_controller?._isDisposed == false) {
      _controller.removeListener(_onCurrentIndexChange);
    }

    newController.addListener(_onCurrentIndexChange);
    _controller = newController;
  }

  void _onCurrentIndexChange() {
    assert(
        _controller.index >= 0 &&
            _controller.index < widget.tabBar.items.length,
        "The $runtimeType's current index ${_controller.index} is "
        'out of bounds for the tab bar with ${widget.tabBar.items.length} tabs');

    setState(() {});
  }

  @override
  void didUpdateWidget(CupertinoTabScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _updateTabController(
          shouldDisposeOldController: oldWidget.controller == null);
    } else if (_controller.index >= widget.tabBar.items.length) {
      _controller.index = widget.tabBar.items.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> stacked = <Widget>[];

    final MediaQueryData existingMediaQuery = MediaQuery.of(context);
    MediaQueryData newMediaQuery = MediaQuery.of(context);

    Widget content = _TabSwitchingView(
      currentTabIndex: _controller.index,
      tabNumber: widget.tabBar.items.length,
      tabBuilder: widget.tabBuilder,
    );
    EdgeInsets contentPadding = EdgeInsets.zero;

    if (widget.resizeToAvoidBottomInset) {
      newMediaQuery = newMediaQuery.removeViewInsets(removeBottom: true);
      contentPadding =
          EdgeInsets.only(bottom: existingMediaQuery.viewInsets.bottom);
    }

    if (widget.tabBar != null &&
        (!widget.resizeToAvoidBottomInset ||
            widget.tabBar.preferredSize.height >
                existingMediaQuery.viewInsets.bottom)) {
      final double bottomPadding = widget.tabBar.preferredSize.height +
          existingMediaQuery.padding.bottom;

      if (widget.tabBar.opaque(context)) {
        contentPadding = EdgeInsets.only(bottom: bottomPadding);
      } else {
        newMediaQuery = newMediaQuery.copyWith(
          padding: newMediaQuery.padding.copyWith(
            bottom: bottomPadding,
          ),
        );
      }
    }

    content = MediaQuery(
      data: newMediaQuery,
      child: Padding(
        padding: contentPadding,
        child: content,
      ),
    );

    stacked.add(content);

    if (widget.tabBar != null) {
      stacked.add(Align(
        alignment: Alignment.bottomCenter,
        child: widget.tabBar.copyWith(
          currentIndex: _controller.index,
          onTap: (int newIndex) {
            _controller.index = newIndex;

            if (widget.tabBar.onTap != null) widget.tabBar.onTap(newIndex);
          },
        ),
      ));
    }

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

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller?.dispose();
    } else if (_controller?._isDisposed == false) {
      _controller.removeListener(_onCurrentIndexChange);
    }

    super.dispose();
  }
}

class _TabSwitchingView extends StatefulWidget {
  const _TabSwitchingView({
    @required this.currentTabIndex,
    @required this.tabNumber,
    @required this.tabBuilder,
  })  : assert(currentTabIndex != null),
        assert(tabNumber != null && tabNumber > 0),
        assert(tabBuilder != null);

  final int currentTabIndex;
  final int tabNumber;
  final IndexedWidgetBuilder tabBuilder;

  @override
  _TabSwitchingViewState createState() => _TabSwitchingViewState();
}

class _TabSwitchingViewState extends State<_TabSwitchingView> {
  List<bool> shouldBuildTab;
  List<FocusScopeNode> tabFocusNodes;

  @override
  void initState() {
    super.initState();
    shouldBuildTab = List<bool>.filled(widget.tabNumber, false, growable: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focusActiveTab();
  }

  @override
  void didUpdateWidget(_TabSwitchingView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final int lengthDiff = widget.tabNumber - shouldBuildTab.length;
    if (lengthDiff > 0) {
      shouldBuildTab.addAll(List<bool>.filled(lengthDiff, false));
    } else if (lengthDiff < 0) {
      shouldBuildTab.removeRange(widget.tabNumber, shouldBuildTab.length);
    }
    _focusActiveTab();
  }

  void _focusActiveTab() {
    if (tabFocusNodes?.length != widget.tabNumber) {
      tabFocusNodes = List<FocusScopeNode>.generate(
        widget.tabNumber,
        (int index) => FocusScopeNode(debugLabel: 'Tab Focus Scope $index'),
      );
    }
    FocusScope.of(context).setFirstFocus(tabFocusNodes[widget.currentTabIndex]);
  }

  @override
  void dispose() {
    for (FocusScopeNode focusScopeNode in tabFocusNodes) {
      focusScopeNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List<Widget>.generate(widget.tabNumber, (int index) {
        final bool active = index == widget.currentTabIndex;
        shouldBuildTab[index] = active || shouldBuildTab[index];

        return Offstage(
          offstage: !active,
          child: TickerMode(
            enabled: active,
            child: FocusScope(
              node: tabFocusNodes[index],
              child: shouldBuildTab[index]
                  ? widget.tabBuilder(context, index)
                  : Container(),
            ),
          ),
        );
      }),
    );
  }
}

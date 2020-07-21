import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart' show DragStartBehavior;
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'app_bar.dart';
import 'bottom_sheet.dart';
import 'button_bar.dart';
import 'button_theme.dart';
import 'divider.dart';
import 'drawer.dart';
import 'flexible_space_bar.dart';
import 'floating_action_button.dart';
import 'floating_action_button_location.dart';
import 'material.dart';
import 'snack_bar.dart';
import 'theme.dart';

const FloatingActionButtonLocation _kDefaultFloatingActionButtonLocation =
    FloatingActionButtonLocation.endFloat;
const FloatingActionButtonAnimator _kDefaultFloatingActionButtonAnimator =
    FloatingActionButtonAnimator.scaling;

enum _ScaffoldSlot {
  body,
  appBar,
  bottomSheet,
  snackBar,
  persistentFooter,
  bottomNavigationBar,
  floatingActionButton,
  drawer,
  endDrawer,
  statusBar,
}

@immutable
class ScaffoldPrelayoutGeometry {
  const ScaffoldPrelayoutGeometry({
    @required this.bottomSheetSize,
    @required this.contentBottom,
    @required this.contentTop,
    @required this.floatingActionButtonSize,
    @required this.minInsets,
    @required this.scaffoldSize,
    @required this.snackBarSize,
    @required this.textDirection,
  });

  final Size floatingActionButtonSize;

  final Size bottomSheetSize;

  final double contentBottom;

  final double contentTop;

  final EdgeInsets minInsets;

  final Size scaffoldSize;

  final Size snackBarSize;

  final TextDirection textDirection;
}

@immutable
class _TransitionSnapshotFabLocation extends FloatingActionButtonLocation {
  const _TransitionSnapshotFabLocation(
      this.begin, this.end, this.animator, this.progress);

  final FloatingActionButtonLocation begin;
  final FloatingActionButtonLocation end;
  final FloatingActionButtonAnimator animator;
  final double progress;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return animator.getOffset(
      begin: begin.getOffset(scaffoldGeometry),
      end: end.getOffset(scaffoldGeometry),
      progress: progress,
    );
  }

  @override
  String toString() {
    return '$runtimeType(begin: $begin, end: $end, progress: $progress)';
  }
}

@immutable
class ScaffoldGeometry {
  const ScaffoldGeometry({
    this.bottomNavigationBarTop,
    this.floatingActionButtonArea,
  });

  final double bottomNavigationBarTop;

  final Rect floatingActionButtonArea;

  ScaffoldGeometry _scaleFloatingActionButton(double scaleFactor) {
    if (scaleFactor == 1.0) return this;

    if (scaleFactor == 0.0) {
      return ScaffoldGeometry(
        bottomNavigationBarTop: bottomNavigationBarTop,
      );
    }

    final Rect scaledButton = Rect.lerp(
        floatingActionButtonArea.center & Size.zero,
        floatingActionButtonArea,
        scaleFactor);
    return copyWith(floatingActionButtonArea: scaledButton);
  }

  ScaffoldGeometry copyWith({
    double bottomNavigationBarTop,
    Rect floatingActionButtonArea,
  }) {
    return ScaffoldGeometry(
      bottomNavigationBarTop:
          bottomNavigationBarTop ?? this.bottomNavigationBarTop,
      floatingActionButtonArea:
          floatingActionButtonArea ?? this.floatingActionButtonArea,
    );
  }
}

class _ScaffoldGeometryNotifier extends ChangeNotifier
    implements ValueListenable<ScaffoldGeometry> {
  _ScaffoldGeometryNotifier(this.geometry, this.context)
      : assert(context != null);

  final BuildContext context;
  double floatingActionButtonScale;
  ScaffoldGeometry geometry;

  @override
  ScaffoldGeometry get value {
    assert(() {
      final RenderObject renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.owner.debugDoingPaint)
        throw FlutterError(
            'Scaffold.geometryOf() must only be accessed during the paint phase.\n'
            'The ScaffoldGeometry is only available during the paint phase, because\n'
            'its value is computed during the animation and layout phases prior to painting.');
      return true;
    }());
    return geometry._scaleFloatingActionButton(floatingActionButtonScale);
  }

  void _updateWith({
    double bottomNavigationBarTop,
    Rect floatingActionButtonArea,
    double floatingActionButtonScale,
  }) {
    this.floatingActionButtonScale =
        floatingActionButtonScale ?? this.floatingActionButtonScale;
    geometry = geometry.copyWith(
      bottomNavigationBarTop: bottomNavigationBarTop,
      floatingActionButtonArea: floatingActionButtonArea,
    );
    notifyListeners();
  }
}

class _ScaffoldLayout extends MultiChildLayoutDelegate {
  _ScaffoldLayout({
    @required this.minInsets,
    @required this.textDirection,
    @required this.geometryNotifier,
    @required this.previousFloatingActionButtonLocation,
    @required this.currentFloatingActionButtonLocation,
    @required this.floatingActionButtonMoveAnimationProgress,
    @required this.floatingActionButtonMotionAnimator,
  })  : assert(minInsets != null),
        assert(textDirection != null),
        assert(geometryNotifier != null),
        assert(previousFloatingActionButtonLocation != null),
        assert(currentFloatingActionButtonLocation != null);

  final EdgeInsets minInsets;
  final TextDirection textDirection;
  final _ScaffoldGeometryNotifier geometryNotifier;

  final FloatingActionButtonLocation previousFloatingActionButtonLocation;
  final FloatingActionButtonLocation currentFloatingActionButtonLocation;
  final double floatingActionButtonMoveAnimationProgress;
  final FloatingActionButtonAnimator floatingActionButtonMotionAnimator;

  @override
  void performLayout(Size size) {
    final BoxConstraints looseConstraints = BoxConstraints.loose(size);

    final BoxConstraints fullWidthConstraints =
        looseConstraints.tighten(width: size.width);
    final double bottom = size.height;
    double contentTop = 0.0;
    double bottomWidgetsHeight = 0.0;

    if (hasChild(_ScaffoldSlot.appBar)) {
      contentTop =
          layoutChild(_ScaffoldSlot.appBar, fullWidthConstraints).height;
      positionChild(_ScaffoldSlot.appBar, Offset.zero);
    }

    double bottomNavigationBarTop;
    if (hasChild(_ScaffoldSlot.bottomNavigationBar)) {
      final double bottomNavigationBarHeight =
          layoutChild(_ScaffoldSlot.bottomNavigationBar, fullWidthConstraints)
              .height;
      bottomWidgetsHeight += bottomNavigationBarHeight;
      bottomNavigationBarTop = math.max(0.0, bottom - bottomWidgetsHeight);
      positionChild(_ScaffoldSlot.bottomNavigationBar,
          Offset(0.0, bottomNavigationBarTop));
    }

    if (hasChild(_ScaffoldSlot.persistentFooter)) {
      final BoxConstraints footerConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: math.max(0.0, bottom - bottomWidgetsHeight - contentTop),
      );
      final double persistentFooterHeight =
          layoutChild(_ScaffoldSlot.persistentFooter, footerConstraints).height;
      bottomWidgetsHeight += persistentFooterHeight;
      positionChild(_ScaffoldSlot.persistentFooter,
          Offset(0.0, math.max(0.0, bottom - bottomWidgetsHeight)));
    }

    final double contentBottom =
        math.max(0.0, bottom - math.max(minInsets.bottom, bottomWidgetsHeight));

    if (hasChild(_ScaffoldSlot.body)) {
      final BoxConstraints bodyConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: math.max(0.0, contentBottom - contentTop),
      );
      layoutChild(_ScaffoldSlot.body, bodyConstraints);
      positionChild(_ScaffoldSlot.body, Offset(0.0, contentTop));
    }

    Size bottomSheetSize = Size.zero;
    Size snackBarSize = Size.zero;

    if (hasChild(_ScaffoldSlot.bottomSheet)) {
      final BoxConstraints bottomSheetConstraints = BoxConstraints(
        maxWidth: fullWidthConstraints.maxWidth,
        maxHeight: math.max(0.0, contentBottom - contentTop),
      );
      bottomSheetSize =
          layoutChild(_ScaffoldSlot.bottomSheet, bottomSheetConstraints);
      positionChild(
          _ScaffoldSlot.bottomSheet,
          Offset((size.width - bottomSheetSize.width) / 2.0,
              contentBottom - bottomSheetSize.height));
    }

    if (hasChild(_ScaffoldSlot.snackBar)) {
      snackBarSize = layoutChild(_ScaffoldSlot.snackBar, fullWidthConstraints);
      positionChild(_ScaffoldSlot.snackBar,
          Offset(0.0, contentBottom - snackBarSize.height));
    }

    Rect floatingActionButtonRect;
    if (hasChild(_ScaffoldSlot.floatingActionButton)) {
      final Size fabSize =
          layoutChild(_ScaffoldSlot.floatingActionButton, looseConstraints);

      final ScaffoldPrelayoutGeometry currentGeometry =
          ScaffoldPrelayoutGeometry(
        bottomSheetSize: bottomSheetSize,
        contentBottom: contentBottom,
        contentTop: contentTop,
        floatingActionButtonSize: fabSize,
        minInsets: minInsets,
        scaffoldSize: size,
        snackBarSize: snackBarSize,
        textDirection: textDirection,
      );
      final Offset currentFabOffset =
          currentFloatingActionButtonLocation.getOffset(currentGeometry);
      final Offset previousFabOffset =
          previousFloatingActionButtonLocation.getOffset(currentGeometry);
      final Offset fabOffset = floatingActionButtonMotionAnimator.getOffset(
        begin: previousFabOffset,
        end: currentFabOffset,
        progress: floatingActionButtonMoveAnimationProgress,
      );
      positionChild(_ScaffoldSlot.floatingActionButton, fabOffset);
      floatingActionButtonRect = fabOffset & fabSize;
    }

    if (hasChild(_ScaffoldSlot.statusBar)) {
      layoutChild(_ScaffoldSlot.statusBar,
          fullWidthConstraints.tighten(height: minInsets.top));
      positionChild(_ScaffoldSlot.statusBar, Offset.zero);
    }

    if (hasChild(_ScaffoldSlot.drawer)) {
      layoutChild(_ScaffoldSlot.drawer, BoxConstraints.tight(size));
      positionChild(_ScaffoldSlot.drawer, Offset.zero);
    }

    if (hasChild(_ScaffoldSlot.endDrawer)) {
      layoutChild(_ScaffoldSlot.endDrawer, BoxConstraints.tight(size));
      positionChild(_ScaffoldSlot.endDrawer, Offset.zero);
    }

    geometryNotifier._updateWith(
      bottomNavigationBarTop: bottomNavigationBarTop,
      floatingActionButtonArea: floatingActionButtonRect,
    );
  }

  @override
  bool shouldRelayout(_ScaffoldLayout oldDelegate) {
    return oldDelegate.minInsets != minInsets ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.floatingActionButtonMoveAnimationProgress !=
            floatingActionButtonMoveAnimationProgress ||
        oldDelegate.previousFloatingActionButtonLocation !=
            previousFloatingActionButtonLocation ||
        oldDelegate.currentFloatingActionButtonLocation !=
            currentFloatingActionButtonLocation;
  }
}

class _FloatingActionButtonTransition extends StatefulWidget {
  const _FloatingActionButtonTransition({
    Key key,
    @required this.child,
    @required this.fabMoveAnimation,
    @required this.fabMotionAnimator,
    @required this.geometryNotifier,
  })  : assert(fabMoveAnimation != null),
        assert(fabMotionAnimator != null),
        super(key: key);

  final Widget child;
  final Animation<double> fabMoveAnimation;
  final FloatingActionButtonAnimator fabMotionAnimator;
  final _ScaffoldGeometryNotifier geometryNotifier;

  @override
  _FloatingActionButtonTransitionState createState() =>
      _FloatingActionButtonTransitionState();
}

class _FloatingActionButtonTransitionState
    extends State<_FloatingActionButtonTransition>
    with TickerProviderStateMixin {
  AnimationController _previousController;
  Animation<double> _previousScaleAnimation;
  Animation<double> _previousRotationAnimation;

  AnimationController _currentController;

  Animation<double> _currentScaleAnimation;
  Animation<double> _extendedCurrentScaleAnimation;
  Animation<double> _currentRotationAnimation;
  Widget _previousChild;

  @override
  void initState() {
    super.initState();

    _previousController = AnimationController(
      duration: kFloatingActionButtonSegue,
      vsync: this,
    )..addStatusListener(_handlePreviousAnimationStatusChanged);

    _currentController = AnimationController(
      duration: kFloatingActionButtonSegue,
      vsync: this,
    );

    _updateAnimations();

    if (widget.child != null) {
      _currentController.value = 1.0;
    } else {
      _updateGeometryScale(0.0);
    }
  }

  @override
  void dispose() {
    _previousController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FloatingActionButtonTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool oldChildIsNull = oldWidget.child == null;
    final bool newChildIsNull = widget.child == null;
    if (oldChildIsNull == newChildIsNull &&
        oldWidget.child?.key == widget.child?.key) return;
    if (oldWidget.fabMotionAnimator != widget.fabMotionAnimator ||
        oldWidget.fabMoveAnimation != widget.fabMoveAnimation) {
      _updateAnimations();
    }
    if (_previousController.status == AnimationStatus.dismissed) {
      final double currentValue = _currentController.value;
      if (currentValue == 0.0 || oldWidget.child == null) {
        _previousChild = null;
        if (widget.child != null) _currentController.forward();
      } else {
        _previousChild = oldWidget.child;
        _previousController
          ..value = currentValue
          ..reverse();
        _currentController.value = 0.0;
      }
    }
  }

  static final Animatable<double> _entranceTurnTween = Tween<double>(
    begin: 1.0 - kFloatingActionButtonTurnInterval,
    end: 1.0,
  ).chain(CurveTween(curve: Curves.easeIn));

  void _updateAnimations() {
    final CurvedAnimation previousExitScaleAnimation = CurvedAnimation(
      parent: _previousController,
      curve: Curves.easeIn,
    );
    final Animation<double> previousExitRotationAnimation =
        Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _previousController,
        curve: Curves.easeIn,
      ),
    );

    final CurvedAnimation currentEntranceScaleAnimation = CurvedAnimation(
      parent: _currentController,
      curve: Curves.easeIn,
    );
    final Animation<double> currentEntranceRotationAnimation =
        _currentController.drive(_entranceTurnTween);

    final Animation<double> moveScaleAnimation = widget.fabMotionAnimator
        .getScaleAnimation(parent: widget.fabMoveAnimation);
    final Animation<double> moveRotationAnimation = widget.fabMotionAnimator
        .getRotationAnimation(parent: widget.fabMoveAnimation);

    _previousScaleAnimation =
        AnimationMin<double>(moveScaleAnimation, previousExitScaleAnimation);
    _currentScaleAnimation =
        AnimationMin<double>(moveScaleAnimation, currentEntranceScaleAnimation);
    _extendedCurrentScaleAnimation = _currentScaleAnimation
        .drive(CurveTween(curve: const Interval(0.0, 0.1)));

    _previousRotationAnimation = TrainHoppingAnimation(
        previousExitRotationAnimation, moveRotationAnimation);
    _currentRotationAnimation = TrainHoppingAnimation(
        currentEntranceRotationAnimation, moveRotationAnimation);

    _currentScaleAnimation.addListener(_onProgressChanged);
    _previousScaleAnimation.addListener(_onProgressChanged);
  }

  void _handlePreviousAnimationStatusChanged(AnimationStatus status) {
    setState(() {
      if (status == AnimationStatus.dismissed) {
        assert(_currentController.status == AnimationStatus.dismissed);
        if (widget.child != null) _currentController.forward();
      }
    });
  }

  bool _isExtendedFloatingActionButton(Widget widget) {
    if (widget is! FloatingActionButton) return false;
    final FloatingActionButton fab = widget;
    return fab.isExtended;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];

    if (_previousController.status != AnimationStatus.dismissed) {
      if (_isExtendedFloatingActionButton(_previousChild)) {
        children.add(FadeTransition(
          opacity: _previousScaleAnimation,
          child: _previousChild,
        ));
      } else {
        children.add(ScaleTransition(
          scale: _previousScaleAnimation,
          child: RotationTransition(
            turns: _previousRotationAnimation,
            child: _previousChild,
          ),
        ));
      }
    }

    if (_isExtendedFloatingActionButton(widget.child)) {
      children.add(ScaleTransition(
        scale: _extendedCurrentScaleAnimation,
        child: FadeTransition(
          opacity: _currentScaleAnimation,
          child: widget.child,
        ),
      ));
    } else {
      children.add(ScaleTransition(
        scale: _currentScaleAnimation,
        child: RotationTransition(
          turns: _currentRotationAnimation,
          child: widget.child,
        ),
      ));
    }

    return Stack(
      alignment: Alignment.centerRight,
      children: children,
    );
  }

  void _onProgressChanged() {
    _updateGeometryScale(
        math.max(_previousScaleAnimation.value, _currentScaleAnimation.value));
  }

  void _updateGeometryScale(double scale) {
    widget.geometryNotifier._updateWith(
      floatingActionButtonScale: scale,
    );
  }
}

class Scaffold extends StatefulWidget {
  const Scaffold({
    Key key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomPadding,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.down,
  })  : assert(primary != null),
        assert(drawerDragStartBehavior != null),
        super(key: key);

  final PreferredSizeWidget appBar;

  final Widget body;

  final Widget floatingActionButton;

  final FloatingActionButtonLocation floatingActionButtonLocation;

  final FloatingActionButtonAnimator floatingActionButtonAnimator;

  final List<Widget> persistentFooterButtons;

  final Widget drawer;

  final Widget endDrawer;

  final Color backgroundColor;

  final Widget bottomNavigationBar;

  final Widget bottomSheet;

  @Deprecated(
      'Use resizeToAvoidBottomInset to specify if the body should resize when the keyboard appears')
  final bool resizeToAvoidBottomPadding;

  final bool resizeToAvoidBottomInset;

  final bool primary;

  final DragStartBehavior drawerDragStartBehavior;

  static ScaffoldState of(BuildContext context, {bool nullOk = false}) {
    assert(nullOk != null);
    assert(context != null);
    final ScaffoldState result =
        context.ancestorStateOfType(const TypeMatcher<ScaffoldState>());
    if (nullOk || result != null) return result;
    throw FlutterError(
        'Scaffold.of() called with a context that does not contain a Scaffold.\n'
        'No Scaffold ancestor could be found starting from the context that was passed to Scaffold.of(). '
        'This usually happens when the context provided is from the same StatefulWidget as that '
        'whose build function actually creates the Scaffold widget being sought.\n'
        'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
        'context that is "under" the Scaffold. For an example of this, please see the '
        'documentation for Scaffold.of():\n'
        '  https://docs.flutter.io/flutter/material/Scaffold/of.html\n'
        'A more efficient solution is to split your build function into several widgets. This '
        'introduces a new context from which you can obtain the Scaffold. In this solution, '
        'you would have an outer widget that creates the Scaffold populated by instances of '
        'your new inner widgets, and then in these inner widgets you would use Scaffold.of().\n'
        'A less elegant but more expedient solution is assign a GlobalKey to the Scaffold, '
        'then use the key.currentState property to obtain the ScaffoldState rather than '
        'using the Scaffold.of() function.\n'
        'The context used was:\n'
        '  $context');
  }

  static ValueListenable<ScaffoldGeometry> geometryOf(BuildContext context) {
    final _ScaffoldScope scaffoldScope =
        context.inheritFromWidgetOfExactType(_ScaffoldScope);
    if (scaffoldScope == null)
      throw FlutterError(
          'Scaffold.geometryOf() called with a context that does not contain a Scaffold.\n'
          'This usually happens when the context provided is from the same StatefulWidget as that '
          'whose build function actually creates the Scaffold widget being sought.\n'
          'There are several ways to avoid this problem. The simplest is to use a Builder to get a '
          'context that is "under" the Scaffold. For an example of this, please see the '
          'documentation for Scaffold.of():\n'
          '  https://docs.flutter.io/flutter/material/Scaffold/of.html\n'
          'A more efficient solution is to split your build function into several widgets. This '
          'introduces a new context from which you can obtain the Scaffold. In this solution, '
          'you would have an outer widget that creates the Scaffold populated by instances of '
          'your new inner widgets, and then in these inner widgets you would use Scaffold.geometryOf().\n'
          'The context used was:\n'
          '  $context');

    return scaffoldScope.geometryNotifier;
  }

  static bool hasDrawer(BuildContext context,
      {bool registerForUpdates = true}) {
    assert(registerForUpdates != null);
    assert(context != null);
    if (registerForUpdates) {
      final _ScaffoldScope scaffold =
          context.inheritFromWidgetOfExactType(_ScaffoldScope);
      return scaffold?.hasDrawer ?? false;
    } else {
      final ScaffoldState scaffold =
          context.ancestorStateOfType(const TypeMatcher<ScaffoldState>());
      return scaffold?.hasDrawer ?? false;
    }
  }

  @override
  ScaffoldState createState() => ScaffoldState();
}

class ScaffoldState extends State<Scaffold> with TickerProviderStateMixin {
  final GlobalKey<DrawerControllerState> _drawerKey =
      GlobalKey<DrawerControllerState>();
  final GlobalKey<DrawerControllerState> _endDrawerKey =
      GlobalKey<DrawerControllerState>();

  bool get hasDrawer => widget.drawer != null;

  bool get hasEndDrawer => widget.endDrawer != null;

  bool _drawerOpened = false;
  bool _endDrawerOpened = false;

  bool get isDrawerOpen => _drawerOpened;

  bool get isEndDrawerOpen => _endDrawerOpened;

  void _drawerOpenedCallback(bool isOpened) {
    setState(() {
      _drawerOpened = isOpened;
    });
  }

  void _endDrawerOpenedCallback(bool isOpened) {
    setState(() {
      _endDrawerOpened = isOpened;
    });
  }

  void openDrawer() {
    if (_endDrawerKey.currentState != null && _endDrawerOpened)
      _endDrawerKey.currentState.close();
    _drawerKey.currentState?.open();
  }

  void openEndDrawer() {
    if (_drawerKey.currentState != null && _drawerOpened)
      _drawerKey.currentState.close();
    _endDrawerKey.currentState?.open();
  }

  final Queue<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>>
      _snackBars =
      Queue<ScaffoldFeatureController<SnackBar, SnackBarClosedReason>>();
  AnimationController _snackBarController;
  Timer _snackBarTimer;
  bool _accessibleNavigation;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
      SnackBar snackbar) {
    _snackBarController ??= SnackBar.createAnimationController(vsync: this)
      ..addStatusListener(_handleSnackBarStatusChange);
    if (_snackBars.isEmpty) {
      assert(_snackBarController.isDismissed);
      _snackBarController.forward();
    }
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason> controller;
    controller = ScaffoldFeatureController<SnackBar, SnackBarClosedReason>._(
        snackbar.withAnimation(_snackBarController, fallbackKey: UniqueKey()),
        Completer<SnackBarClosedReason>(), () {
      assert(_snackBars.first == controller);
      hideCurrentSnackBar(reason: SnackBarClosedReason.hide);
    }, null);
    setState(() {
      _snackBars.addLast(controller);
    });
    return controller;
  }

  void _handleSnackBarStatusChange(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.dismissed:
        assert(_snackBars.isNotEmpty);
        setState(() {
          _snackBars.removeFirst();
        });
        if (_snackBars.isNotEmpty) _snackBarController.forward();
        break;
      case AnimationStatus.completed:
        setState(() {
          assert(_snackBarTimer == null);
        });
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        break;
    }
  }

  void removeCurrentSnackBar(
      {SnackBarClosedReason reason = SnackBarClosedReason.remove}) {
    assert(reason != null);
    if (_snackBars.isEmpty) return;
    final Completer<SnackBarClosedReason> completer =
        _snackBars.first._completer;
    if (!completer.isCompleted) completer.complete(reason);
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    _snackBarController.value = 0.0;
  }

  void hideCurrentSnackBar(
      {SnackBarClosedReason reason = SnackBarClosedReason.hide}) {
    assert(reason != null);
    if (_snackBars.isEmpty ||
        _snackBarController.status == AnimationStatus.dismissed) return;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final Completer<SnackBarClosedReason> completer =
        _snackBars.first._completer;
    if (mediaQuery.accessibleNavigation) {
      _snackBarController.value = 0.0;
      completer.complete(reason);
    } else {
      _snackBarController.reverse().then<void>((void value) {
        assert(mounted);
        if (!completer.isCompleted) completer.complete(reason);
      });
    }
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
  }

  final List<_PersistentBottomSheet> _dismissedBottomSheets =
      <_PersistentBottomSheet>[];
  PersistentBottomSheetController<dynamic> _currentBottomSheet;

  void _maybeBuildCurrentBottomSheet() {
    if (widget.bottomSheet != null) {
      _currentBottomSheet = _buildBottomSheet<void>(
        (BuildContext context) => widget.bottomSheet,
        BottomSheet.createAnimationController(this)..value = 1.0,
        false,
      );
    }
  }

  void _closeCurrentBottomSheet() {
    if (_currentBottomSheet != null) {
      _currentBottomSheet.close();
      assert(_currentBottomSheet == null);
    }
  }

  PersistentBottomSheetController<T> _buildBottomSheet<T>(WidgetBuilder builder,
      AnimationController controller, bool isLocalHistoryEntry) {
    final Completer<T> completer = Completer<T>();
    final GlobalKey<_PersistentBottomSheetState> bottomSheetKey =
        GlobalKey<_PersistentBottomSheetState>();
    _PersistentBottomSheet bottomSheet;

    void _removeCurrentBottomSheet() {
      assert(_currentBottomSheet._widget == bottomSheet);
      assert(bottomSheetKey.currentState != null);
      bottomSheetKey.currentState.close();
      if (controller.status != AnimationStatus.dismissed)
        _dismissedBottomSheets.add(bottomSheet);
      setState(() {
        _currentBottomSheet = null;
      });
      completer.complete();
    }

    final LocalHistoryEntry entry = isLocalHistoryEntry
        ? LocalHistoryEntry(onRemove: _removeCurrentBottomSheet)
        : null;

    bottomSheet = _PersistentBottomSheet(
        key: bottomSheetKey,
        animationController: controller,
        enableDrag: isLocalHistoryEntry,
        onClosing: () {
          assert(_currentBottomSheet._widget == bottomSheet);
          if (isLocalHistoryEntry)
            entry.remove();
          else
            _removeCurrentBottomSheet();
        },
        onDismissed: () {
          if (_dismissedBottomSheets.contains(bottomSheet)) {
            bottomSheet.animationController.dispose();
            setState(() {
              _dismissedBottomSheets.remove(bottomSheet);
            });
          }
        },
        builder: builder);

    if (isLocalHistoryEntry) ModalRoute.of(context).addLocalHistoryEntry(entry);

    return PersistentBottomSheetController<T>._(
      bottomSheet,
      completer,
      isLocalHistoryEntry ? entry.remove : _removeCurrentBottomSheet,
      (VoidCallback fn) {
        bottomSheetKey.currentState?.setState(fn);
      },
      isLocalHistoryEntry,
    );
  }

  PersistentBottomSheetController<T> showBottomSheet<T>(WidgetBuilder builder) {
    _closeCurrentBottomSheet();
    final AnimationController controller =
        BottomSheet.createAnimationController(this)..forward();
    setState(() {
      _currentBottomSheet = _buildBottomSheet<T>(builder, controller, true);
    });
    return _currentBottomSheet;
  }

  AnimationController _floatingActionButtonMoveController;
  FloatingActionButtonAnimator _floatingActionButtonAnimator;
  FloatingActionButtonLocation _previousFloatingActionButtonLocation;
  FloatingActionButtonLocation _floatingActionButtonLocation;

  void _moveFloatingActionButton(
      final FloatingActionButtonLocation newLocation) {
    FloatingActionButtonLocation previousLocation =
        _floatingActionButtonLocation;
    double restartAnimationFrom = 0.0;

    if (_floatingActionButtonMoveController.isAnimating) {
      previousLocation = _TransitionSnapshotFabLocation(
          _previousFloatingActionButtonLocation,
          _floatingActionButtonLocation,
          _floatingActionButtonAnimator,
          _floatingActionButtonMoveController.value);
      restartAnimationFrom = _floatingActionButtonAnimator
          .getAnimationRestart(_floatingActionButtonMoveController.value);
    }

    setState(() {
      _previousFloatingActionButtonLocation = previousLocation;
      _floatingActionButtonLocation = newLocation;
    });

    _floatingActionButtonMoveController.forward(from: restartAnimationFrom);
  }

  final ScrollController _primaryScrollController = ScrollController();

  void _handleStatusBarTap() {
    if (_primaryScrollController.hasClients) {
      _primaryScrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.linear,
      );
    }
  }

  _ScaffoldGeometryNotifier _geometryNotifier;

  bool get _resizeToAvoidBottomInset {
    return widget.resizeToAvoidBottomInset ??
        widget.resizeToAvoidBottomPadding ??
        true;
  }

  @override
  void initState() {
    super.initState();
    _geometryNotifier =
        _ScaffoldGeometryNotifier(const ScaffoldGeometry(), context);
    _floatingActionButtonLocation = widget.floatingActionButtonLocation ??
        _kDefaultFloatingActionButtonLocation;
    _floatingActionButtonAnimator = widget.floatingActionButtonAnimator ??
        _kDefaultFloatingActionButtonAnimator;
    _previousFloatingActionButtonLocation = _floatingActionButtonLocation;
    _floatingActionButtonMoveController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
      value: 1.0,
      duration: kFloatingActionButtonSegue * 2,
    );
    _maybeBuildCurrentBottomSheet();
  }

  @override
  void didUpdateWidget(Scaffold oldWidget) {
    if (widget.floatingActionButtonAnimator !=
        oldWidget.floatingActionButtonAnimator) {
      _floatingActionButtonAnimator = widget.floatingActionButtonAnimator ??
          _kDefaultFloatingActionButtonAnimator;
    }
    if (widget.floatingActionButtonLocation !=
        oldWidget.floatingActionButtonLocation) {
      _moveFloatingActionButton(widget.floatingActionButtonLocation ??
          _kDefaultFloatingActionButtonLocation);
    }
    if (widget.bottomSheet != oldWidget.bottomSheet) {
      assert(() {
        if (widget.bottomSheet != null &&
            _currentBottomSheet?._isLocalHistoryEntry == true) {
          throw FlutterError(
              'Scaffold.bottomSheet cannot be specified while a bottom sheet displayed '
              'with showBottomSheet() is still visible.\n Use the PersistentBottomSheetController '
              'returned by showBottomSheet() to close the old bottom sheet before creating '
              'a Scaffold with a (non null) bottomSheet.');
        }
        return true;
      }());
      _closeCurrentBottomSheet();
      _maybeBuildCurrentBottomSheet();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    if (_accessibleNavigation == true &&
        !mediaQuery.accessibleNavigation &&
        _snackBarTimer != null &&
        !_snackBarTimer.isActive) {
      hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
    }
    _accessibleNavigation = mediaQuery.accessibleNavigation;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _snackBarController?.dispose();
    _snackBarTimer?.cancel();
    _snackBarTimer = null;
    _geometryNotifier.dispose();
    for (_PersistentBottomSheet bottomSheet in _dismissedBottomSheets)
      bottomSheet.animationController.dispose();
    if (_currentBottomSheet != null)
      _currentBottomSheet._widget.animationController.dispose();
    _floatingActionButtonMoveController.dispose();
    super.dispose();
  }

  void _addIfNonNull(
    List<LayoutId> children,
    Widget child,
    Object childId, {
    @required bool removeLeftPadding,
    @required bool removeTopPadding,
    @required bool removeRightPadding,
    @required bool removeBottomPadding,
    bool removeBottomInset = false,
  }) {
    MediaQueryData data = MediaQuery.of(context).removePadding(
      removeLeft: removeLeftPadding,
      removeTop: removeTopPadding,
      removeRight: removeRightPadding,
      removeBottom: removeBottomPadding,
    );
    if (removeBottomInset) data = data.removeViewInsets(removeBottom: true);

    if (child != null) {
      children.add(
        LayoutId(
          id: childId,
          child: MediaQuery(data: data, child: child),
        ),
      );
    }
  }

  void _buildEndDrawer(List<LayoutId> children, TextDirection textDirection) {
    if (widget.endDrawer != null) {
      assert(hasEndDrawer);
      _addIfNonNull(
        children,
        DrawerController(
          key: _endDrawerKey,
          alignment: DrawerAlignment.end,
          child: widget.endDrawer,
          drawerCallback: _endDrawerOpenedCallback,
          dragStartBehavior: widget.drawerDragStartBehavior,
        ),
        _ScaffoldSlot.endDrawer,
        removeLeftPadding: textDirection == TextDirection.ltr,
        removeTopPadding: false,
        removeRightPadding: textDirection == TextDirection.rtl,
        removeBottomPadding: false,
      );
    }
  }

  void _buildDrawer(List<LayoutId> children, TextDirection textDirection) {
    if (widget.drawer != null) {
      assert(hasDrawer);
      _addIfNonNull(
        children,
        DrawerController(
          key: _drawerKey,
          alignment: DrawerAlignment.start,
          child: widget.drawer,
          drawerCallback: _drawerOpenedCallback,
          dragStartBehavior: widget.drawerDragStartBehavior,
        ),
        _ScaffoldSlot.drawer,
        removeLeftPadding: textDirection == TextDirection.rtl,
        removeTopPadding: false,
        removeRightPadding: textDirection == TextDirection.ltr,
        removeBottomPadding: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasDirectionality(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final ThemeData themeData = Theme.of(context);
    final TextDirection textDirection = Directionality.of(context);
    _accessibleNavigation = mediaQuery.accessibleNavigation;

    if (_snackBars.isNotEmpty) {
      final ModalRoute<dynamic> route = ModalRoute.of(context);
      if (route == null || route.isCurrent) {
        if (_snackBarController.isCompleted && _snackBarTimer == null) {
          final SnackBar snackBar = _snackBars.first._widget;
          _snackBarTimer = Timer(snackBar.duration, () {
            assert(_snackBarController.status == AnimationStatus.forward ||
                _snackBarController.status == AnimationStatus.completed);

            final MediaQueryData mediaQuery = MediaQuery.of(context);
            if (mediaQuery.accessibleNavigation && snackBar.action != null)
              return;
            hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
          });
        }
      } else {
        _snackBarTimer?.cancel();
        _snackBarTimer = null;
      }
    }

    final List<LayoutId> children = <LayoutId>[];

    _addIfNonNull(
      children,
      widget.body,
      _ScaffoldSlot.body,
      removeLeftPadding: false,
      removeTopPadding: widget.appBar != null,
      removeRightPadding: false,
      removeBottomPadding: widget.bottomNavigationBar != null ||
          widget.persistentFooterButtons != null,
      removeBottomInset: _resizeToAvoidBottomInset,
    );

    if (widget.appBar != null) {
      final double topPadding = widget.primary ? mediaQuery.padding.top : 0.0;
      final double extent = widget.appBar.preferredSize.height + topPadding;
      assert(extent >= 0.0 && extent.isFinite);
      _addIfNonNull(
        children,
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: extent),
          child: FlexibleSpaceBar.createSettings(
            currentExtent: extent,
            child: widget.appBar,
          ),
        ),
        _ScaffoldSlot.appBar,
        removeLeftPadding: false,
        removeTopPadding: false,
        removeRightPadding: false,
        removeBottomPadding: true,
      );
    }

    if (_snackBars.isNotEmpty) {
      _addIfNonNull(
        children,
        _snackBars.first._widget,
        _ScaffoldSlot.snackBar,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: widget.bottomNavigationBar != null ||
            widget.persistentFooterButtons != null,
      );
    }

    if (widget.persistentFooterButtons != null) {
      _addIfNonNull(
        children,
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: Divider.createBorderSide(context, width: 1.0),
            ),
          ),
          child: SafeArea(
            child: ButtonTheme.bar(
              child: SafeArea(
                top: false,
                child: ButtonBar(children: widget.persistentFooterButtons),
              ),
            ),
          ),
        ),
        _ScaffoldSlot.persistentFooter,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: false,
      );
    }

    if (widget.bottomNavigationBar != null) {
      _addIfNonNull(
        children,
        widget.bottomNavigationBar,
        _ScaffoldSlot.bottomNavigationBar,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: false,
      );
    }

    if (_currentBottomSheet != null || _dismissedBottomSheets.isNotEmpty) {
      final List<Widget> bottomSheets = <Widget>[];
      if (_dismissedBottomSheets.isNotEmpty)
        bottomSheets.addAll(_dismissedBottomSheets);
      if (_currentBottomSheet != null)
        bottomSheets.add(_currentBottomSheet._widget);
      final Widget stack = Stack(
        children: bottomSheets,
        alignment: Alignment.bottomCenter,
      );
      _addIfNonNull(
        children,
        stack,
        _ScaffoldSlot.bottomSheet,
        removeLeftPadding: false,
        removeTopPadding: true,
        removeRightPadding: false,
        removeBottomPadding: _resizeToAvoidBottomInset,
      );
    }

    _addIfNonNull(
      children,
      _FloatingActionButtonTransition(
        child: widget.floatingActionButton,
        fabMoveAnimation: _floatingActionButtonMoveController,
        fabMotionAnimator: _floatingActionButtonAnimator,
        geometryNotifier: _geometryNotifier,
      ),
      _ScaffoldSlot.floatingActionButton,
      removeLeftPadding: true,
      removeTopPadding: true,
      removeRightPadding: true,
      removeBottomPadding: true,
    );

    switch (themeData.platform) {
      case TargetPlatform.iOS:
        _addIfNonNull(
          children,
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleStatusBarTap,
            excludeFromSemantics: true,
          ),
          _ScaffoldSlot.statusBar,
          removeLeftPadding: false,
          removeTopPadding: true,
          removeRightPadding: false,
          removeBottomPadding: true,
        );
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        break;
    }

    if (_endDrawerOpened) {
      _buildDrawer(children, textDirection);
      _buildEndDrawer(children, textDirection);
    } else {
      _buildEndDrawer(children, textDirection);
      _buildDrawer(children, textDirection);
    }

    final EdgeInsets minInsets = mediaQuery.padding.copyWith(
      bottom: _resizeToAvoidBottomInset ? mediaQuery.viewInsets.bottom : 0.0,
    );

    return _ScaffoldScope(
      hasDrawer: hasDrawer,
      geometryNotifier: _geometryNotifier,
      child: PrimaryScrollController(
        controller: _primaryScrollController,
        child: Material(
          color: widget.backgroundColor ?? themeData.scaffoldBackgroundColor,
          child: AnimatedBuilder(
              animation: _floatingActionButtonMoveController,
              builder: (BuildContext context, Widget child) {
                return CustomMultiChildLayout(
                  children: children,
                  delegate: _ScaffoldLayout(
                    minInsets: minInsets,
                    currentFloatingActionButtonLocation:
                        _floatingActionButtonLocation,
                    floatingActionButtonMoveAnimationProgress:
                        _floatingActionButtonMoveController.value,
                    floatingActionButtonMotionAnimator:
                        _floatingActionButtonAnimator,
                    geometryNotifier: _geometryNotifier,
                    previousFloatingActionButtonLocation:
                        _previousFloatingActionButtonLocation,
                    textDirection: textDirection,
                  ),
                );
              }),
        ),
      ),
    );
  }
}

class ScaffoldFeatureController<T extends Widget, U> {
  const ScaffoldFeatureController._(
      this._widget, this._completer, this.close, this.setState);
  final T _widget;
  final Completer<U> _completer;

  Future<U> get closed => _completer.future;

  final VoidCallback close;

  final StateSetter setState;
}

class _PersistentBottomSheet extends StatefulWidget {
  const _PersistentBottomSheet(
      {Key key,
      this.animationController,
      this.enableDrag = true,
      this.onClosing,
      this.onDismissed,
      this.builder})
      : super(key: key);

  final AnimationController animationController;
  final bool enableDrag;
  final VoidCallback onClosing;
  final VoidCallback onDismissed;
  final WidgetBuilder builder;

  @override
  _PersistentBottomSheetState createState() => _PersistentBottomSheetState();
}

class _PersistentBottomSheetState extends State<_PersistentBottomSheet> {
  @override
  void initState() {
    super.initState();
    assert(widget.animationController.status == AnimationStatus.forward ||
        widget.animationController.status == AnimationStatus.completed);
    widget.animationController.addStatusListener(_handleStatusChange);
  }

  @override
  void didUpdateWidget(_PersistentBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.animationController == oldWidget.animationController);
  }

  void close() {
    widget.animationController.reverse();
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && widget.onDismissed != null)
      widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: widget.animationController,
        builder: (BuildContext context, Widget child) {
          return Align(
              alignment: AlignmentDirectional.topStart,
              heightFactor: widget.animationController.value,
              child: child);
        },
        child: Semantics(
            container: true,
            onDismiss: () {
              close();
              widget.onClosing();
            },
            child: BottomSheet(
                animationController: widget.animationController,
                enableDrag: widget.enableDrag,
                onClosing: widget.onClosing,
                builder: widget.builder)));
  }
}

class PersistentBottomSheetController<T>
    extends ScaffoldFeatureController<_PersistentBottomSheet, T> {
  const PersistentBottomSheetController._(
    _PersistentBottomSheet widget,
    Completer<T> completer,
    VoidCallback close,
    StateSetter setState,
    this._isLocalHistoryEntry,
  ) : super._(widget, completer, close, setState);

  final bool _isLocalHistoryEntry;
}

class _ScaffoldScope extends InheritedWidget {
  const _ScaffoldScope({
    @required this.hasDrawer,
    @required this.geometryNotifier,
    @required Widget child,
  })  : assert(hasDrawer != null),
        super(child: child);

  final bool hasDrawer;
  final _ScaffoldGeometryNotifier geometryNotifier;

  @override
  bool updateShouldNotify(_ScaffoldScope oldWidget) {
    return hasDrawer != oldWidget.hasDrawer;
  }
}

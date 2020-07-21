import 'dart:math' as math;
import 'package:flutter_web/ui.dart' show ImageFilter;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'localizations.dart';
import 'scrollbar.dart';

const TextStyle _kCupertinoDialogTitleStyle = TextStyle(
  fontFamily: '.SF UI Display',
  inherit: false,
  fontSize: 18.0,
  fontWeight: FontWeight.w600,
  color: CupertinoColors.black,
  letterSpacing: 0.48,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogContentStyle = TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 13.4,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.black,
  height: 1.036,
  letterSpacing: -0.25,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogActionStyle = TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 16.8,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.activeBlue,
  textBaseline: TextBaseline.alphabetic,
);

const double _kCupertinoDialogWidth = 270.0;
const double _kAccessibilityCupertinoDialogWidth = 310.0;

const BoxDecoration _kCupertinoDialogBlurOverlayDecoration = BoxDecoration(
  color: CupertinoColors.white,
  backgroundBlendMode: BlendMode.overlay,
);

const double _kBlurAmount = 20.0;
const double _kEdgePadding = 20.0;
const double _kMinButtonHeight = 45.0;
const double _kMinButtonFontSize = 10.0;
const double _kDialogCornerRadius = 12.0;
const double _kDividerThickness = 1.0;

const Color _kDialogColor = Color(0xC0FFFFFF);

const Color _kDialogPressedColor = Color(0x90FFFFFF);

const Color _kButtonDividerColor = Color(0x40FFFFFF);

const double _kMaxRegularTextScaleFactor = 1.4;

bool _isInAccessibilityMode(BuildContext context) {
  final MediaQueryData data = MediaQuery.of(context, nullOk: true);
  return data != null && data.textScaleFactor > _kMaxRegularTextScaleFactor;
}

class CupertinoAlertDialog extends StatelessWidget {
  const CupertinoAlertDialog({
    Key key,
    this.title,
    this.content,
    this.actions = const <Widget>[],
    this.scrollController,
    this.actionScrollController,
  })  : assert(actions != null),
        super(key: key);

  final Widget title;

  final Widget content;

  final List<Widget> actions;

  final ScrollController scrollController;

  final ScrollController actionScrollController;

  Widget _buildContent() {
    final List<Widget> children = <Widget>[];

    if (title != null || content != null) {
      final Widget titleSection = _CupertinoAlertContentSection(
        title: title,
        content: content,
        scrollController: scrollController,
      );
      children.add(Flexible(flex: 3, child: titleSection));
    }

    return Container(
      color: _kDialogColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildActions() {
    Widget actionSection = Container(
      height: 0.0,
    );
    if (actions.isNotEmpty) {
      actionSection = _CupertinoAlertActionSection(
        children: actions,
        scrollController: actionScrollController,
      );
    }

    return actionSection;
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoLocalizations localizations =
        CupertinoLocalizations.of(context);
    final bool isInAccessibilityMode = _isInAccessibilityMode(context);
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: math.max(textScaleFactor, 1.0),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: _kEdgePadding),
              width: isInAccessibilityMode
                  ? _kAccessibilityCupertinoDialogWidth
                  : _kCupertinoDialogWidth,
              child: CupertinoPopupSurface(
                isSurfacePainted: false,
                child: Semantics(
                  namesRoute: true,
                  scopesRoute: true,
                  explicitChildNodes: true,
                  label: localizations.alertDialogLabel,
                  child: _CupertinoDialogRenderWidget(
                    contentSection: _buildContent(),
                    actionsSection: _buildActions(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

@Deprecated(
    'Use CupertinoAlertDialog for alert dialogs. Use CupertinoPopupSurface for custom popups.')
class CupertinoDialog extends StatelessWidget {
  const CupertinoDialog({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _kCupertinoDialogWidth,
        child: CupertinoPopupSurface(
          child: child,
        ),
      ),
    );
  }
}

class CupertinoPopupSurface extends StatelessWidget {
  const CupertinoPopupSurface({
    Key key,
    this.isSurfacePainted = true,
    this.child,
  }) : super(key: key);

  final bool isSurfacePainted;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kDialogCornerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _kBlurAmount, sigmaY: _kBlurAmount),
        child: Container(
          decoration: _kCupertinoDialogBlurOverlayDecoration,
          child: Container(
            color: isSurfacePainted ? _kDialogColor : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _CupertinoDialogRenderWidget extends RenderObjectWidget {
  const _CupertinoDialogRenderWidget({
    Key key,
    @required this.contentSection,
    @required this.actionsSection,
  }) : super(key: key);

  final Widget contentSection;
  final Widget actionsSection;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCupertinoDialog(
      dividerThickness:
          _kDividerThickness / MediaQuery.of(context).devicePixelRatio,
      isInAccessibilityMode: _isInAccessibilityMode(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderCupertinoDialog renderObject) {
    renderObject.isInAccessibilityMode = _isInAccessibilityMode(context);
  }

  @override
  RenderObjectElement createElement() {
    return _CupertinoDialogRenderElement(this);
  }
}

class _CupertinoDialogRenderElement extends RenderObjectElement {
  _CupertinoDialogRenderElement(_CupertinoDialogRenderWidget widget)
      : super(widget);

  Element _contentElement;
  Element _actionsElement;

  @override
  _CupertinoDialogRenderWidget get widget => super.widget;

  @override
  _RenderCupertinoDialog get renderObject => super.renderObject;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_contentElement != null) {
      visitor(_contentElement);
    }
    if (_actionsElement != null) {
      visitor(_actionsElement);
    }
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _contentElement = updateChild(_contentElement, widget.contentSection,
        _AlertDialogSections.contentSection);
    _actionsElement = updateChild(_actionsElement, widget.actionsSection,
        _AlertDialogSections.actionsSection);
  }

  @override
  void insertChildRenderObject(RenderObject child, _AlertDialogSections slot) {
    assert(slot != null);
    switch (slot) {
      case _AlertDialogSections.contentSection:
        renderObject.contentSection = child;
        break;
      case _AlertDialogSections.actionsSection:
        renderObject.actionsSection = child;
        break;
    }
  }

  @override
  void moveChildRenderObject(RenderObject child, _AlertDialogSections slot) {
    assert(false);
  }

  @override
  void update(RenderObjectWidget newWidget) {
    super.update(newWidget);
    _contentElement = updateChild(_contentElement, widget.contentSection,
        _AlertDialogSections.contentSection);
    _actionsElement = updateChild(_actionsElement, widget.actionsSection,
        _AlertDialogSections.actionsSection);
  }

  @override
  void forgetChild(Element child) {
    assert(child == _contentElement || child == _actionsElement);
    if (_contentElement == child) {
      _contentElement = null;
    } else {
      assert(_actionsElement == child);
      _actionsElement = null;
    }
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(child == renderObject.contentSection ||
        child == renderObject.actionsSection);
    if (renderObject.contentSection == child) {
      renderObject.contentSection = null;
    } else {
      assert(renderObject.actionsSection == child);
      renderObject.actionsSection = null;
    }
  }
}

class _RenderCupertinoDialog extends RenderBox {
  _RenderCupertinoDialog({
    RenderBox contentSection,
    RenderBox actionsSection,
    double dividerThickness = 0.0,
    bool isInAccessibilityMode = false,
  })  : _contentSection = contentSection,
        _actionsSection = actionsSection,
        _dividerThickness = dividerThickness,
        _isInAccessibilityMode = isInAccessibilityMode;

  RenderBox get contentSection => _contentSection;
  RenderBox _contentSection;
  set contentSection(RenderBox newContentSection) {
    if (newContentSection != _contentSection) {
      if (_contentSection != null) {
        dropChild(_contentSection);
      }
      _contentSection = newContentSection;
      if (_contentSection != null) {
        adoptChild(_contentSection);
      }
    }
  }

  RenderBox get actionsSection => _actionsSection;
  RenderBox _actionsSection;
  set actionsSection(RenderBox newActionsSection) {
    if (newActionsSection != _actionsSection) {
      if (null != _actionsSection) {
        dropChild(_actionsSection);
      }
      _actionsSection = newActionsSection;
      if (null != _actionsSection) {
        adoptChild(_actionsSection);
      }
    }
  }

  bool get isInAccessibilityMode => _isInAccessibilityMode;
  bool _isInAccessibilityMode;
  set isInAccessibilityMode(bool newValue) {
    if (newValue != _isInAccessibilityMode) {
      _isInAccessibilityMode = newValue;
      markNeedsLayout();
    }
  }

  double get _dialogWidth => isInAccessibilityMode
      ? _kAccessibilityCupertinoDialogWidth
      : _kCupertinoDialogWidth;

  final double _dividerThickness;

  final Paint _dividerPaint = Paint()
    ..color = _kButtonDividerColor
    ..style = PaintingStyle.fill;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (null != contentSection) {
      contentSection.attach(owner);
    }
    if (null != actionsSection) {
      actionsSection.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    if (null != contentSection) {
      contentSection.detach();
    }
    if (null != actionsSection) {
      actionsSection.detach();
    }
  }

  @override
  void redepthChildren() {
    if (null != contentSection) {
      redepthChild(contentSection);
    }
    if (null != actionsSection) {
      redepthChild(actionsSection);
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (contentSection != null) {
      visitor(contentSection);
    }
    if (actionsSection != null) {
      visitor(actionsSection);
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> value = <DiagnosticsNode>[];
    if (contentSection != null) {
      value.add(contentSection.toDiagnosticsNode(name: 'content'));
    }
    if (actionsSection != null) {
      value.add(actionsSection.toDiagnosticsNode(name: 'actions'));
    }
    return value;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _dialogWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _dialogWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double contentHeight = contentSection.getMinIntrinsicHeight(width);
    final double actionsHeight = actionsSection.getMinIntrinsicHeight(width);
    final bool hasDivider = contentHeight > 0.0 && actionsHeight > 0.0;
    final double height =
        contentHeight + (hasDivider ? _dividerThickness : 0.0) + actionsHeight;

    if (height.isFinite) return height;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double contentHeight = contentSection.getMaxIntrinsicHeight(width);
    final double actionsHeight = actionsSection.getMaxIntrinsicHeight(width);
    final bool hasDivider = contentHeight > 0.0 && actionsHeight > 0.0;
    final double height =
        contentHeight + (hasDivider ? _dividerThickness : 0.0) + actionsHeight;

    if (height.isFinite) return height;
    return 0.0;
  }

  @override
  void performLayout() {
    if (isInAccessibilityMode) {
      performAccessibilityLayout();
    } else {
      performRegularLayout();
    }
  }

  void performRegularLayout() {
    final bool hasDivider =
        contentSection.getMaxIntrinsicHeight(_dialogWidth) > 0.0 &&
            actionsSection.getMaxIntrinsicHeight(_dialogWidth) > 0.0;
    final double dividerThickness = hasDivider ? _dividerThickness : 0.0;

    final double minActionsHeight =
        actionsSection.getMinIntrinsicHeight(_dialogWidth);

    contentSection.layout(
      constraints.deflate(
          EdgeInsets.only(bottom: minActionsHeight + dividerThickness)),
      parentUsesSize: true,
    );
    final Size contentSize = contentSection.size;

    actionsSection.layout(
      constraints
          .deflate(EdgeInsets.only(top: contentSize.height + dividerThickness)),
      parentUsesSize: true,
    );
    final Size actionsSize = actionsSection.size;

    final double dialogHeight =
        contentSize.height + dividerThickness + actionsSize.height;

    size = constraints.constrain(Size(_dialogWidth, dialogHeight));

    assert(actionsSection.parentData is BoxParentData);
    final BoxParentData actionParentData = actionsSection.parentData;
    actionParentData.offset =
        Offset(0.0, contentSize.height + dividerThickness);
  }

  void performAccessibilityLayout() {
    final bool hasDivider =
        contentSection.getMaxIntrinsicHeight(_dialogWidth) > 0.0 &&
            actionsSection.getMaxIntrinsicHeight(_dialogWidth) > 0.0;
    final double dividerThickness = hasDivider ? _dividerThickness : 0.0;

    final double maxContentHeight =
        contentSection.getMaxIntrinsicHeight(_dialogWidth);
    final double maxActionsHeight =
        actionsSection.getMaxIntrinsicHeight(_dialogWidth);

    Size contentSize;
    Size actionsSize;
    if (maxContentHeight + dividerThickness + maxActionsHeight >
        constraints.maxHeight) {
      actionsSection.layout(
        constraints.deflate(EdgeInsets.only(top: constraints.maxHeight / 2.0)),
        parentUsesSize: true,
      );
      actionsSize = actionsSection.size;

      contentSection.layout(
        constraints.deflate(
            EdgeInsets.only(bottom: actionsSize.height + dividerThickness)),
        parentUsesSize: true,
      );
      contentSize = contentSection.size;
    } else {
      contentSection.layout(
        constraints,
        parentUsesSize: true,
      );
      contentSize = contentSection.size;

      actionsSection.layout(
        constraints.deflate(EdgeInsets.only(top: contentSize.height)),
        parentUsesSize: true,
      );
      actionsSize = actionsSection.size;
    }

    final double dialogHeight =
        contentSize.height + dividerThickness + actionsSize.height;

    size = constraints.constrain(Size(_dialogWidth, dialogHeight));

    assert(actionsSection.parentData is BoxParentData);
    final BoxParentData actionParentData = actionsSection.parentData;
    actionParentData.offset =
        Offset(0.0, contentSize.height + dividerThickness);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final BoxParentData contentParentData = contentSection.parentData;
    contentSection.paint(context, offset + contentParentData.offset);

    final bool hasDivider =
        contentSection.size.height > 0.0 && actionsSection.size.height > 0.0;
    if (hasDivider) {
      _paintDividerBetweenContentAndActions(context.canvas, offset);
    }

    final BoxParentData actionsParentData = actionsSection.parentData;
    actionsSection.paint(context, offset + actionsParentData.offset);
  }

  void _paintDividerBetweenContentAndActions(Canvas canvas, Offset offset) {
    canvas.drawRect(
      Rect.fromLTWH(
        offset.dx,
        offset.dy + contentSection.size.height,
        size.width,
        _dividerThickness,
      ),
      _dividerPaint,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    final BoxParentData contentSectionParentData = contentSection.parentData;
    final BoxParentData actionsSectionParentData = actionsSection.parentData;
    return result.addWithPaintOffset(
          offset: contentSectionParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            assert(transformed == position - contentSectionParentData.offset);
            return contentSection.hitTest(result, position: transformed);
          },
        ) ||
        result.addWithPaintOffset(
          offset: actionsSectionParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            assert(transformed == position - actionsSectionParentData.offset);
            return actionsSection.hitTest(result, position: transformed);
          },
        );
  }
}

enum _AlertDialogSections {
  contentSection,
  actionsSection,
}

class _CupertinoAlertContentSection extends StatelessWidget {
  const _CupertinoAlertContentSection({
    Key key,
    this.title,
    this.content,
    this.scrollController,
  }) : super(key: key);

  final Widget title;

  final Widget content;

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final List<Widget> titleContentGroup = <Widget>[];
    if (title != null) {
      titleContentGroup.add(Padding(
        padding: EdgeInsets.only(
          left: _kEdgePadding,
          right: _kEdgePadding,
          bottom: content == null ? _kEdgePadding : 1.0,
          top: _kEdgePadding * textScaleFactor,
        ),
        child: DefaultTextStyle(
          style: _kCupertinoDialogTitleStyle,
          textAlign: TextAlign.center,
          child: title,
        ),
      ));
    }

    if (content != null) {
      titleContentGroup.add(
        Padding(
          padding: EdgeInsets.only(
            left: _kEdgePadding,
            right: _kEdgePadding,
            bottom: _kEdgePadding * textScaleFactor,
            top: title == null ? _kEdgePadding : 1.0,
          ),
          child: DefaultTextStyle(
            style: _kCupertinoDialogContentStyle,
            textAlign: TextAlign.center,
            child: content,
          ),
        ),
      );
    }

    if (titleContentGroup.isEmpty) {
      return SingleChildScrollView(
        controller: scrollController,
        child: Container(width: 0.0, height: 0.0),
      );
    }

    return CupertinoScrollbar(
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: titleContentGroup,
        ),
      ),
    );
  }
}

class _CupertinoAlertActionSection extends StatefulWidget {
  const _CupertinoAlertActionSection({
    Key key,
    @required this.children,
    this.scrollController,
  })  : assert(children != null),
        super(key: key);

  final List<Widget> children;

  final ScrollController scrollController;

  @override
  _CupertinoAlertActionSectionState createState() =>
      _CupertinoAlertActionSectionState();
}

class _CupertinoAlertActionSectionState
    extends State<_CupertinoAlertActionSection> {
  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final List<Widget> interactiveButtons = <Widget>[];
    for (int i = 0; i < widget.children.length; i += 1) {
      interactiveButtons.add(
        _PressableActionButton(
          child: widget.children[i],
        ),
      );
    }

    return CupertinoScrollbar(
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: _CupertinoDialogActionsRenderWidget(
          actionButtons: interactiveButtons,
          dividerThickness: _kDividerThickness / devicePixelRatio,
        ),
      ),
    );
  }
}

class _PressableActionButton extends StatefulWidget {
  const _PressableActionButton({
    @required this.child,
  });

  final Widget child;

  @override
  _PressableActionButtonState createState() => _PressableActionButtonState();
}

class _PressableActionButtonState extends State<_PressableActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return _ActionButtonParentDataWidget(
      isPressed: _isPressed,
      child: MergeSemantics(
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails details) => setState(() {
            _isPressed = true;
          }),
          onTapUp: (TapUpDetails details) => setState(() {
            _isPressed = false;
          }),
          onTapCancel: () => setState(() => _isPressed = false),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ActionButtonParentDataWidget
    extends ParentDataWidget<_CupertinoDialogActionsRenderWidget> {
  const _ActionButtonParentDataWidget({
    Key key,
    this.isPressed,
    @required Widget child,
  }) : super(key: key, child: child);

  final bool isPressed;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is _ActionButtonParentData);
    final _ActionButtonParentData parentData = renderObject.parentData;
    if (parentData.isPressed != isPressed) {
      parentData.isPressed = isPressed;

      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsPaint();
    }
  }
}

class _ActionButtonParentData extends MultiChildLayoutParentData {
  _ActionButtonParentData({
    this.isPressed = false,
  });

  bool isPressed;
}

class CupertinoDialogAction extends StatelessWidget {
  const CupertinoDialogAction({
    this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.textStyle,
    @required this.child,
  })  : assert(child != null),
        assert(isDefaultAction != null),
        assert(isDestructiveAction != null);

  final VoidCallback onPressed;

  final bool isDefaultAction;

  final bool isDestructiveAction;

  final TextStyle textStyle;

  final Widget child;

  bool get enabled => onPressed != null;

  double _calculatePadding(BuildContext context) {
    return 8.0 * MediaQuery.textScaleFactorOf(context);
  }

  Widget _buildContentWithRegularSizingPolicy({
    @required BuildContext context,
    @required TextStyle textStyle,
    @required Widget content,
  }) {
    final bool isInAccessibilityMode = _isInAccessibilityMode(context);
    final double dialogWidth = isInAccessibilityMode
        ? _kAccessibilityCupertinoDialogWidth
        : _kCupertinoDialogWidth;
    final double textScaleFactor = MediaQuery.textScaleFactorOf(context);

    final double fontSizeRatio =
        (textScaleFactor * textStyle.fontSize) / _kMinButtonFontSize;
    final double padding = _calculatePadding(context);

    return IntrinsicHeight(
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: fontSizeRatio * (dialogWidth - (2 * padding)),
            ),
            child: Semantics(
              button: true,
              onTap: onPressed,
              child: DefaultTextStyle(
                style: textStyle,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentWithAccessibilitySizingPolicy({
    @required TextStyle textStyle,
    @required Widget content,
  }) {
    return DefaultTextStyle(
      style: textStyle,
      textAlign: TextAlign.center,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = _kCupertinoDialogActionStyle;
    style = style.merge(textStyle);

    if (isDefaultAction) {
      style = style.copyWith(fontWeight: FontWeight.w600);
    }

    if (isDestructiveAction) {
      style = style.copyWith(color: CupertinoColors.destructiveRed);
    }

    if (!enabled) {
      style = style.copyWith(color: style.color.withOpacity(0.5));
    }

    final Widget sizedContent = _isInAccessibilityMode(context)
        ? _buildContentWithAccessibilitySizingPolicy(
            textStyle: style,
            content: child,
          )
        : _buildContentWithRegularSizingPolicy(
            context: context,
            textStyle: style,
            content: child,
          );

    return GestureDetector(
      excludeFromSemantics: true,
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _kMinButtonHeight,
        ),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(_calculatePadding(context)),
          child: sizedContent,
        ),
      ),
    );
  }
}

class _CupertinoDialogActionsRenderWidget extends MultiChildRenderObjectWidget {
  _CupertinoDialogActionsRenderWidget({
    Key key,
    @required List<Widget> actionButtons,
    double dividerThickness = 0.0,
  })  : _dividerThickness = dividerThickness,
        super(key: key, children: actionButtons);

  final double _dividerThickness;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCupertinoDialogActions(
      dialogWidth: _isInAccessibilityMode(context)
          ? _kAccessibilityCupertinoDialogWidth
          : _kCupertinoDialogWidth,
      dividerThickness: _dividerThickness,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderCupertinoDialogActions renderObject) {
    renderObject.dialogWidth = _isInAccessibilityMode(context)
        ? _kAccessibilityCupertinoDialogWidth
        : _kCupertinoDialogWidth;
    renderObject.dividerThickness = _dividerThickness;
  }
}

class _RenderCupertinoDialogActions extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderCupertinoDialogActions({
    List<RenderBox> children,
    @required double dialogWidth,
    double dividerThickness = 0.0,
  })  : _dialogWidth = dialogWidth,
        _dividerThickness = dividerThickness {
    addAll(children);
  }

  double get dialogWidth => _dialogWidth;
  double _dialogWidth;
  set dialogWidth(double newWidth) {
    if (newWidth != _dialogWidth) {
      _dialogWidth = newWidth;
      markNeedsLayout();
    }
  }

  double get dividerThickness => _dividerThickness;
  double _dividerThickness;
  set dividerThickness(double newValue) {
    if (newValue != _dividerThickness) {
      _dividerThickness = newValue;
      markNeedsLayout();
    }
  }

  final Paint _buttonBackgroundPaint = Paint()
    ..color = _kDialogColor
    ..style = PaintingStyle.fill;

  final Paint _pressedButtonBackgroundPaint = Paint()
    ..color = _kDialogPressedColor
    ..style = PaintingStyle.fill;

  final Paint _dividerPaint = Paint()
    ..color = _kButtonDividerColor
    ..style = PaintingStyle.fill;

  Iterable<RenderBox> get _pressedButtons sync* {
    RenderBox currentChild = firstChild;
    while (currentChild != null) {
      assert(currentChild.parentData is _ActionButtonParentData);
      final _ActionButtonParentData parentData = currentChild.parentData;
      if (parentData.isPressed) {
        yield currentChild;
      }
      currentChild = childAfter(currentChild);
    }
  }

  bool get _isButtonPressed {
    RenderBox currentChild = firstChild;
    while (currentChild != null) {
      assert(currentChild.parentData is _ActionButtonParentData);
      final _ActionButtonParentData parentData = currentChild.parentData;
      if (parentData.isPressed) {
        return true;
      }
      currentChild = childAfter(currentChild);
    }
    return false;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionButtonParentData)
      child.parentData = _ActionButtonParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return dialogWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return dialogWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    double minHeight;
    if (childCount == 0) {
      minHeight = 0.0;
    } else if (childCount == 1) {
      minHeight = _computeMinIntrinsicHeightSideBySide(width);
    } else {
      if (childCount == 2 && _isSingleButtonRow(width)) {
        minHeight = _computeMinIntrinsicHeightSideBySide(width);
      } else {
        minHeight = _computeMinIntrinsicHeightStacked(width);
      }
    }
    return minHeight;
  }

  double _computeMinIntrinsicHeightSideBySide(double width) {
    assert(childCount >= 1 && childCount <= 2);

    double minHeight;
    if (childCount == 1) {
      minHeight = firstChild.getMinIntrinsicHeight(width);
    } else {
      final double perButtonWidth = (width - dividerThickness) / 2.0;
      minHeight = math.max(
        firstChild.getMinIntrinsicHeight(perButtonWidth),
        lastChild.getMinIntrinsicHeight(perButtonWidth),
      );
    }
    return minHeight;
  }

  double _computeMinIntrinsicHeightStacked(double width) {
    assert(childCount >= 2);

    return firstChild.getMinIntrinsicHeight(width) +
        dividerThickness +
        (0.5 * childAfter(firstChild).getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    double maxHeight;
    if (childCount == 0) {
      maxHeight = 0.0;
    } else if (childCount == 1) {
      maxHeight = firstChild.getMaxIntrinsicHeight(width);
    } else if (childCount == 2) {
      if (_isSingleButtonRow(width)) {
        final double perButtonWidth = (width - dividerThickness) / 2.0;
        maxHeight = math.max(
          firstChild.getMaxIntrinsicHeight(perButtonWidth),
          lastChild.getMaxIntrinsicHeight(perButtonWidth),
        );
      } else {
        maxHeight = _computeMaxIntrinsicHeightStacked(width);
      }
    } else {
      maxHeight = _computeMaxIntrinsicHeightStacked(width);
    }
    return maxHeight;
  }

  double _computeMaxIntrinsicHeightStacked(double width) {
    assert(childCount >= 2);

    final double allDividersHeight = (childCount - 1) * dividerThickness;
    double heightAccumulation = allDividersHeight;
    RenderBox button = firstChild;
    while (button != null) {
      heightAccumulation += button.getMaxIntrinsicHeight(width);
      button = childAfter(button);
    }
    return heightAccumulation;
  }

  bool _isSingleButtonRow(double width) {
    bool isSingleButtonRow;
    if (childCount == 1) {
      isSingleButtonRow = true;
    } else if (childCount == 2) {
      final double sideBySideWidth =
          firstChild.getMaxIntrinsicWidth(double.infinity) +
              dividerThickness +
              lastChild.getMaxIntrinsicWidth(double.infinity);
      isSingleButtonRow = sideBySideWidth <= width;
    } else {
      isSingleButtonRow = false;
    }
    return isSingleButtonRow;
  }

  @override
  void performLayout() {
    if (_isSingleButtonRow(dialogWidth)) {
      if (childCount == 1) {
        firstChild.layout(
          constraints,
          parentUsesSize: true,
        );

        size = constraints.constrain(Size(dialogWidth, firstChild.size.height));
      } else {
        final BoxConstraints perButtonConstraints = BoxConstraints(
          minWidth: (constraints.minWidth - dividerThickness) / 2.0,
          maxWidth: (constraints.maxWidth - dividerThickness) / 2.0,
          minHeight: 0.0,
          maxHeight: double.infinity,
        );

        firstChild.layout(
          perButtonConstraints,
          parentUsesSize: true,
        );
        lastChild.layout(
          perButtonConstraints,
          parentUsesSize: true,
        );

        assert(lastChild.parentData is MultiChildLayoutParentData);
        final MultiChildLayoutParentData secondButtonParentData =
            lastChild.parentData;
        secondButtonParentData.offset =
            Offset(firstChild.size.width + dividerThickness, 0.0);

        size = constraints.constrain(Size(
          dialogWidth,
          math.max(
            firstChild.size.height,
            lastChild.size.height,
          ),
        ));
      }
    } else {
      final BoxConstraints perButtonConstraints = constraints.copyWith(
        minHeight: 0.0,
        maxHeight: double.infinity,
      );

      RenderBox child = firstChild;
      int index = 0;
      double verticalOffset = 0.0;
      while (child != null) {
        child.layout(
          perButtonConstraints,
          parentUsesSize: true,
        );

        assert(child.parentData is MultiChildLayoutParentData);
        final MultiChildLayoutParentData parentData = child.parentData;
        parentData.offset = Offset(0.0, verticalOffset);

        verticalOffset += child.size.height;
        if (index < childCount - 1) {
          verticalOffset += dividerThickness;
        }

        index += 1;
        child = childAfter(child);
      }

      size = constraints.constrain(Size(dialogWidth, verticalOffset));
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    if (_isSingleButtonRow(size.width)) {
      _drawButtonBackgroundsAndDividersSingleRow(canvas, offset);
    } else {
      _drawButtonBackgroundsAndDividersStacked(canvas, offset);
    }

    _drawButtons(context, offset);
  }

  void _drawButtonBackgroundsAndDividersSingleRow(
      Canvas canvas, Offset offset) {
    final Rect verticalDivider = childCount == 2 && !_isButtonPressed
        ? Rect.fromLTWH(
            offset.dx + firstChild.size.width,
            offset.dy,
            dividerThickness,
            math.max(
              firstChild.size.height,
              lastChild.size.height,
            ),
          )
        : Rect.zero;

    final List<Rect> pressedButtonRects =
        _pressedButtons.map<Rect>((RenderBox pressedButton) {
      final MultiChildLayoutParentData buttonParentData =
          pressedButton.parentData;

      return Rect.fromLTWH(
        offset.dx + buttonParentData.offset.dx,
        offset.dy + buttonParentData.offset.dy,
        pressedButton.size.width,
        pressedButton.size.height,
      );
    }).toList();

    final Path backgroundFillPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..addRect(verticalDivider);

    for (int i = 0; i < pressedButtonRects.length; i += 1) {
      backgroundFillPath.addRect(pressedButtonRects[i]);
    }

    canvas.drawPath(
      backgroundFillPath,
      _buttonBackgroundPaint,
    );

    final Path pressedBackgroundFillPath = Path();
    for (int i = 0; i < pressedButtonRects.length; i += 1) {
      pressedBackgroundFillPath.addRect(pressedButtonRects[i]);
    }

    canvas.drawPath(
      pressedBackgroundFillPath,
      _pressedButtonBackgroundPaint,
    );

    final Path dividersPath = Path()..addRect(verticalDivider);

    canvas.drawPath(
      dividersPath,
      _dividerPaint,
    );
  }

  void _drawButtonBackgroundsAndDividersStacked(Canvas canvas, Offset offset) {
    final Offset dividerOffset = Offset(0.0, dividerThickness);

    final Path backgroundFillPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height));

    final Path pressedBackgroundFillPath = Path();

    final Path dividersPath = Path();

    Offset accumulatingOffset = offset;

    RenderBox child = firstChild;
    RenderBox prevChild;
    while (child != null) {
      assert(child.parentData is _ActionButtonParentData);
      final _ActionButtonParentData currentButtonParentData = child.parentData;
      final bool isButtonPressed = currentButtonParentData.isPressed;

      bool isPrevButtonPressed = false;
      if (prevChild != null) {
        assert(prevChild.parentData is _ActionButtonParentData);
        final _ActionButtonParentData previousButtonParentData =
            prevChild.parentData;
        isPrevButtonPressed = previousButtonParentData.isPressed;
      }

      final bool isDividerPresent = child != firstChild;
      final bool isDividerPainted =
          isDividerPresent && !(isButtonPressed || isPrevButtonPressed);
      final Rect dividerRect = Rect.fromLTWH(
        accumulatingOffset.dx,
        accumulatingOffset.dy,
        size.width,
        dividerThickness,
      );

      final Rect buttonBackgroundRect = Rect.fromLTWH(
        accumulatingOffset.dx,
        accumulatingOffset.dy + (isDividerPresent ? dividerThickness : 0.0),
        size.width,
        child.size.height,
      );

      if (isButtonPressed) {
        backgroundFillPath.addRect(buttonBackgroundRect);
        pressedBackgroundFillPath.addRect(buttonBackgroundRect);
      }

      if (isDividerPainted) {
        backgroundFillPath.addRect(dividerRect);
        dividersPath.addRect(dividerRect);
      }

      accumulatingOffset += (isDividerPresent ? dividerOffset : Offset.zero) +
          Offset(0.0, child.size.height);

      prevChild = child;
      child = childAfter(child);
    }

    canvas.drawPath(backgroundFillPath, _buttonBackgroundPaint);
    canvas.drawPath(pressedBackgroundFillPath, _pressedButtonBackgroundPaint);
    canvas.drawPath(dividersPath, _dividerPaint);
  }

  void _drawButtons(PaintingContext context, Offset offset) {
    RenderBox child = firstChild;
    while (child != null) {
      final MultiChildLayoutParentData childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childAfter(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

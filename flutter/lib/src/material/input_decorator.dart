import 'dart:math' as math;
import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'input_border.dart';
import 'theme.dart';

const Duration _kTransitionDuration = Duration(milliseconds: 200);
const Curve _kTransitionCurve = Curves.fastOutSlowIn;

class _InputBorderGap extends ChangeNotifier {
  double _start;
  double get start => _start;
  set start(double value) {
    if (value != _start) {
      _start = value;
      notifyListeners();
    }
  }

  double _extent = 0.0;
  double get extent => _extent;
  set extent(double value) {
    if (value != _extent) {
      _extent = value;
      notifyListeners();
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final _InputBorderGap typedOther = other;
    return typedOther.start == start && typedOther.extent == extent;
  }

  @override
  int get hashCode => hashValues(start, extent);
}

class _InputBorderTween extends Tween<InputBorder> {
  _InputBorderTween({InputBorder begin, InputBorder end})
      : super(begin: begin, end: end);

  @override
  InputBorder lerp(double t) => ShapeBorder.lerp(begin, end, t);
}

class _InputBorderPainter extends CustomPainter {
  _InputBorderPainter({
    @required Listenable repaint,
    @required this.borderAnimation,
    @required this.border,
    @required this.gapAnimation,
    @required this.gap,
    @required this.textDirection,
    @required this.fillColor,
    @required this.hoverAnimation,
    @required this.hoverColorTween,
  }) : super(repaint: repaint);

  final Animation<double> borderAnimation;
  final _InputBorderTween border;
  final Animation<double> gapAnimation;
  final _InputBorderGap gap;
  final TextDirection textDirection;
  final Color fillColor;
  final ColorTween hoverColorTween;
  final Animation<double> hoverAnimation;

  Color get blendedColor =>
      Color.alphaBlend(hoverColorTween.evaluate(hoverAnimation), fillColor);

  @override
  void paint(Canvas canvas, Size size) {
    final InputBorder borderValue = border.evaluate(borderAnimation);
    final Rect canvasRect = Offset.zero & size;
    final Color blendedFillColor = blendedColor;
    if (blendedFillColor.alpha > 0) {
      canvas.drawPath(
        borderValue.getOuterPath(canvasRect, textDirection: textDirection),
        Paint()
          ..color = blendedFillColor
          ..style = PaintingStyle.fill,
      );
    }

    borderValue.paint(
      canvas,
      canvasRect,
      gapStart: gap.start,
      gapExtent: gap.extent,
      gapPercentage: gapAnimation.value,
      textDirection: textDirection,
    );
  }

  @override
  bool shouldRepaint(_InputBorderPainter oldPainter) {
    return borderAnimation != oldPainter.borderAnimation ||
        hoverAnimation != oldPainter.hoverAnimation ||
        gapAnimation != oldPainter.gapAnimation ||
        border != oldPainter.border ||
        gap != oldPainter.gap ||
        textDirection != oldPainter.textDirection;
  }
}

class _BorderContainer extends StatefulWidget {
  const _BorderContainer({
    Key key,
    @required this.border,
    @required this.gap,
    @required this.gapAnimation,
    @required this.fillColor,
    @required this.hoverColor,
    @required this.isHovering,
    this.child,
  })  : assert(border != null),
        assert(gap != null),
        assert(fillColor != null),
        super(key: key);

  final InputBorder border;
  final _InputBorderGap gap;
  final Animation<double> gapAnimation;
  final Color fillColor;
  final Color hoverColor;
  final bool isHovering;
  final Widget child;

  @override
  _BorderContainerState createState() => _BorderContainerState();
}

class _BorderContainerState extends State<_BorderContainer>
    with TickerProviderStateMixin {
  static const Duration _kHoverDuration = Duration(milliseconds: 15);

  AnimationController _controller;
  AnimationController _hoverColorController;
  Animation<double> _borderAnimation;
  _InputBorderTween _border;
  Animation<double> _hoverAnimation;
  ColorTween _hoverColorTween;

  @override
  void initState() {
    super.initState();
    _hoverColorController = AnimationController(
      duration: _kHoverDuration,
      value: widget.isHovering ? 1.0 : 0.0,
      vsync: this,
    );
    _controller = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
    );
    _borderAnimation = CurvedAnimation(
      parent: _controller,
      curve: _kTransitionCurve,
    );
    _border = _InputBorderTween(
      begin: widget.border,
      end: widget.border,
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverColorController,
      curve: Curves.linear,
    );
    _hoverColorTween =
        ColorTween(begin: Colors.transparent, end: widget.hoverColor);
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverColorController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_BorderContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.border != oldWidget.border) {
      _border = _InputBorderTween(
        begin: oldWidget.border,
        end: widget.border,
      );
      _controller
        ..value = 0.0
        ..forward();
    }
    if (widget.hoverColor != oldWidget.hoverColor) {
      _hoverColorTween =
          ColorTween(begin: Colors.transparent, end: widget.hoverColor);
    }
    if (widget.isHovering != oldWidget.isHovering) {
      if (widget.isHovering) {
        _hoverColorController.forward();
      } else {
        _hoverColorController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _InputBorderPainter(
        repaint: Listenable.merge(<Listenable>[
          _borderAnimation,
          widget.gap,
          _hoverColorController,
        ]),
        borderAnimation: _borderAnimation,
        border: _border,
        gapAnimation: widget.gapAnimation,
        gap: widget.gap,
        textDirection: Directionality.of(context),
        fillColor: widget.fillColor,
        hoverColorTween: _hoverColorTween,
        hoverAnimation: _hoverAnimation,
      ),
      child: widget.child,
    );
  }
}

class _Shaker extends AnimatedWidget {
  const _Shaker({
    Key key,
    Animation<double> animation,
    this.child,
  }) : super(key: key, listenable: animation);

  final Widget child;

  Animation<double> get animation => listenable;

  double get translateX {
    const double shakeDelta = 4.0;
    final double t = animation.value;
    if (t <= 0.25)
      return -t * shakeDelta;
    else if (t < 0.75)
      return (t - 0.5) * shakeDelta;
    else
      return (1.0 - t) * 4.0 * shakeDelta;
  }

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.translationValues(translateX, 0.0, 0.0),
      child: child,
    );
  }
}

class _HelperError extends StatefulWidget {
  const _HelperError({
    Key key,
    this.textAlign,
    this.helperText,
    this.helperStyle,
    this.errorText,
    this.errorStyle,
    this.errorMaxLines,
  }) : super(key: key);

  final TextAlign textAlign;
  final String helperText;
  final TextStyle helperStyle;
  final String errorText;
  final TextStyle errorStyle;
  final int errorMaxLines;

  @override
  _HelperErrorState createState() => _HelperErrorState();
}

class _HelperErrorState extends State<_HelperError>
    with SingleTickerProviderStateMixin {
  static const Widget empty = SizedBox();

  AnimationController _controller;
  Widget _helper;
  Widget _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
    );
    if (widget.errorText != null) {
      _error = _buildError();
      _controller.value = 1.0;
    } else if (widget.helperText != null) {
      _helper = _buildHelper();
    }
    _controller.addListener(_handleChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
  }

  @override
  void didUpdateWidget(_HelperError old) {
    super.didUpdateWidget(old);

    final String newErrorText = widget.errorText;
    final String newHelperText = widget.helperText;
    final String oldErrorText = old.errorText;
    final String oldHelperText = old.helperText;

    final bool errorTextStateChanged =
        (newErrorText != null) != (oldErrorText != null);
    final bool helperTextStateChanged = newErrorText == null &&
        (newHelperText != null) != (oldHelperText != null);

    if (errorTextStateChanged || helperTextStateChanged) {
      if (newErrorText != null) {
        _error = _buildError();
        _controller.forward();
      } else if (newHelperText != null) {
        _helper = _buildHelper();
        _controller.reverse();
      } else {
        _controller.reverse();
      }
    }
  }

  Widget _buildHelper() {
    assert(widget.helperText != null);
    return Semantics(
      container: true,
      child: Opacity(
        opacity: 1.0 - _controller.value,
        child: Text(
          widget.helperText,
          style: widget.helperStyle,
          textAlign: widget.textAlign,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildError() {
    assert(widget.errorText != null);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Opacity(
        opacity: _controller.value,
        child: FractionalTranslation(
          translation: Tween<Offset>(
            begin: const Offset(0.0, -0.25),
            end: const Offset(0.0, 0.0),
          ).evaluate(_controller.view),
          child: Text(
            widget.errorText,
            style: widget.errorStyle,
            textAlign: widget.textAlign,
            overflow: TextOverflow.ellipsis,
            maxLines: widget.errorMaxLines,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isDismissed) {
      _error = null;
      if (widget.helperText != null) {
        return _helper = _buildHelper();
      } else {
        _helper = null;
        return empty;
      }
    }

    if (_controller.isCompleted) {
      _helper = null;
      if (widget.errorText != null) {
        return _error = _buildError();
      } else {
        _error = null;
        return empty;
      }
    }

    if (_helper == null && widget.errorText != null) return _buildError();

    if (_error == null && widget.helperText != null) return _buildHelper();

    if (widget.errorText != null) {
      return Stack(
        children: <Widget>[
          Opacity(
            opacity: 1.0 - _controller.value,
            child: _helper,
          ),
          _buildError(),
        ],
      );
    }

    if (widget.helperText != null) {
      return Stack(
        children: <Widget>[
          _buildHelper(),
          Opacity(
            opacity: _controller.value,
            child: _error,
          ),
        ],
      );
    }

    return empty;
  }
}

enum _DecorationSlot {
  icon,
  input,
  label,
  hint,
  prefix,
  suffix,
  prefixIcon,
  suffixIcon,
  helperError,
  counter,
  container,
}

class _Decoration {
  const _Decoration({
    @required this.contentPadding,
    @required this.isCollapsed,
    @required this.floatingLabelHeight,
    @required this.floatingLabelProgress,
    this.border,
    this.borderGap,
    this.icon,
    this.input,
    this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.suffixIcon,
    this.helperError,
    this.counter,
    this.container,
    this.alignLabelWithHint,
  })  : assert(contentPadding != null),
        assert(isCollapsed != null),
        assert(floatingLabelHeight != null),
        assert(floatingLabelProgress != null);

  final EdgeInsetsGeometry contentPadding;
  final bool isCollapsed;
  final double floatingLabelHeight;
  final double floatingLabelProgress;
  final InputBorder border;
  final _InputBorderGap borderGap;
  final bool alignLabelWithHint;
  final Widget icon;
  final Widget input;
  final Widget label;
  final Widget hint;
  final Widget prefix;
  final Widget suffix;
  final Widget prefixIcon;
  final Widget suffixIcon;
  final Widget helperError;
  final Widget counter;
  final Widget container;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final _Decoration typedOther = other;
    return typedOther.contentPadding == contentPadding &&
        typedOther.floatingLabelHeight == floatingLabelHeight &&
        typedOther.floatingLabelProgress == floatingLabelProgress &&
        typedOther.border == border &&
        typedOther.borderGap == borderGap &&
        typedOther.icon == icon &&
        typedOther.input == input &&
        typedOther.label == label &&
        typedOther.hint == hint &&
        typedOther.prefix == prefix &&
        typedOther.suffix == suffix &&
        typedOther.prefixIcon == prefixIcon &&
        typedOther.suffixIcon == suffixIcon &&
        typedOther.helperError == helperError &&
        typedOther.counter == counter &&
        typedOther.container == container &&
        typedOther.alignLabelWithHint == alignLabelWithHint;
  }

  @override
  int get hashCode {
    return hashValues(
      contentPadding,
      floatingLabelHeight,
      floatingLabelProgress,
      border,
      borderGap,
      icon,
      input,
      label,
      hint,
      prefix,
      suffix,
      prefixIcon,
      suffixIcon,
      helperError,
      counter,
      container,
      alignLabelWithHint,
    );
  }
}

class _RenderDecorationLayout {
  const _RenderDecorationLayout({
    this.boxToBaseline,
    this.inputBaseline,
    this.outlineBaseline,
    this.subtextBaseline,
    this.containerHeight,
    this.subtextHeight,
  });

  final Map<RenderBox, double> boxToBaseline;
  final double inputBaseline;
  final double outlineBaseline;
  final double subtextBaseline;
  final double containerHeight;
  final double subtextHeight;
}

class _RenderDecoration extends RenderBox {
  _RenderDecoration({
    @required _Decoration decoration,
    @required TextDirection textDirection,
    @required TextBaseline textBaseline,
    @required bool isFocused,
    @required bool expands,
  })  : assert(decoration != null),
        assert(textDirection != null),
        assert(textBaseline != null),
        assert(expands != null),
        _decoration = decoration,
        _textDirection = textDirection,
        _textBaseline = textBaseline,
        _isFocused = isFocused,
        _expands = expands;

  static const double subtextGap = 8.0;
  final Map<_DecorationSlot, RenderBox> slotToChild =
      <_DecorationSlot, RenderBox>{};
  final Map<RenderBox, _DecorationSlot> childToSlot =
      <RenderBox, _DecorationSlot>{};

  RenderBox _updateChild(
      RenderBox oldChild, RenderBox newChild, _DecorationSlot slot) {
    if (oldChild != null) {
      dropChild(oldChild);
      childToSlot.remove(oldChild);
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      childToSlot[newChild] = slot;
      slotToChild[slot] = newChild;
      adoptChild(newChild);
    }
    return newChild;
  }

  RenderBox _icon;
  RenderBox get icon => _icon;
  set icon(RenderBox value) {
    _icon = _updateChild(_icon, value, _DecorationSlot.icon);
  }

  RenderBox _input;
  RenderBox get input => _input;
  set input(RenderBox value) {
    _input = _updateChild(_input, value, _DecorationSlot.input);
  }

  RenderBox _label;
  RenderBox get label => _label;
  set label(RenderBox value) {
    _label = _updateChild(_label, value, _DecorationSlot.label);
  }

  RenderBox _hint;
  RenderBox get hint => _hint;
  set hint(RenderBox value) {
    _hint = _updateChild(_hint, value, _DecorationSlot.hint);
  }

  RenderBox _prefix;
  RenderBox get prefix => _prefix;
  set prefix(RenderBox value) {
    _prefix = _updateChild(_prefix, value, _DecorationSlot.prefix);
  }

  RenderBox _suffix;
  RenderBox get suffix => _suffix;
  set suffix(RenderBox value) {
    _suffix = _updateChild(_suffix, value, _DecorationSlot.suffix);
  }

  RenderBox _prefixIcon;
  RenderBox get prefixIcon => _prefixIcon;
  set prefixIcon(RenderBox value) {
    _prefixIcon = _updateChild(_prefixIcon, value, _DecorationSlot.prefixIcon);
  }

  RenderBox _suffixIcon;
  RenderBox get suffixIcon => _suffixIcon;
  set suffixIcon(RenderBox value) {
    _suffixIcon = _updateChild(_suffixIcon, value, _DecorationSlot.suffixIcon);
  }

  RenderBox _helperError;
  RenderBox get helperError => _helperError;
  set helperError(RenderBox value) {
    _helperError =
        _updateChild(_helperError, value, _DecorationSlot.helperError);
  }

  RenderBox _counter;
  RenderBox get counter => _counter;
  set counter(RenderBox value) {
    _counter = _updateChild(_counter, value, _DecorationSlot.counter);
  }

  RenderBox _container;
  RenderBox get container => _container;
  set container(RenderBox value) {
    _container = _updateChild(_container, value, _DecorationSlot.container);
  }

  Iterable<RenderBox> get _children sync* {
    if (icon != null) yield icon;
    if (input != null) yield input;
    if (prefixIcon != null) yield prefixIcon;
    if (suffixIcon != null) yield suffixIcon;
    if (prefix != null) yield prefix;
    if (suffix != null) yield suffix;
    if (label != null) yield label;
    if (hint != null) yield hint;
    if (helperError != null) yield helperError;
    if (counter != null) yield counter;
    if (container != null) yield container;
  }

  _Decoration get decoration => _decoration;
  _Decoration _decoration;
  set decoration(_Decoration value) {
    assert(value != null);
    if (_decoration == value) return;
    _decoration = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  set textBaseline(TextBaseline value) {
    assert(value != null);
    if (_textBaseline == value) return;
    _textBaseline = value;
    markNeedsLayout();
  }

  bool get isFocused => _isFocused;
  bool _isFocused;
  set isFocused(bool value) {
    assert(value != null);
    if (_isFocused == value) return;
    _isFocused = value;
    markNeedsSemanticsUpdate();
  }

  bool get expands => _expands;
  bool _expands = false;
  set expands(bool value) {
    assert(value != null);
    if (_expands == value) return;
    _expands = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderBox child in _children) child.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    for (RenderBox child in _children) child.detach();
  }

  @override
  void redepthChildren() {
    _children.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _children.forEach(visitor);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (icon != null) visitor(icon);
    if (prefix != null) visitor(prefix);
    if (prefixIcon != null) visitor(prefixIcon);
    if (isFocused && hint != null) {
      final RenderProxyBox typedHint = hint;
      visitor(typedHint.child);
    } else if (!isFocused && label != null) {
      visitor(label);
    }
    if (input != null) visitor(input);
    if (suffixIcon != null) visitor(suffixIcon);
    if (suffix != null) visitor(suffix);
    if (container != null) visitor(container);
    if (helperError != null) visitor(helperError);
    if (counter != null) visitor(counter);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> value = <DiagnosticsNode>[];
    void add(RenderBox child, String name) {
      if (child != null) value.add(child.toDiagnosticsNode(name: name));
    }

    add(icon, 'icon');
    add(input, 'input');
    add(label, 'label');
    add(hint, 'hint');
    add(prefix, 'prefix');
    add(suffix, 'suffix');
    add(prefixIcon, 'prefixIcon');
    add(suffixIcon, 'suffixIcon');
    add(helperError, 'helperError');
    add(counter, 'counter');
    add(container, 'container');
    return value;
  }

  @override
  bool get sizedByParent => false;

  static double _minWidth(RenderBox box, double height) {
    return box == null ? 0.0 : box.getMinIntrinsicWidth(height);
  }

  static double _maxWidth(RenderBox box, double height) {
    return box == null ? 0.0 : box.getMaxIntrinsicWidth(height);
  }

  static double _minHeight(RenderBox box, double width) {
    return box == null ? 0.0 : box.getMinIntrinsicHeight(width);
  }

  static Size _boxSize(RenderBox box) => box == null ? Size.zero : box.size;

  static BoxParentData _boxParentData(RenderBox box) => box.parentData;

  EdgeInsets get contentPadding => decoration.contentPadding;

  double _layoutLineBox(RenderBox box, BoxConstraints constraints) {
    if (box == null) {
      return 0.0;
    }
    box.layout(constraints, parentUsesSize: true);
    final double baseline = box.getDistanceToBaseline(textBaseline);
    assert(baseline != null && baseline >= 0.0);
    return baseline;
  }

  _RenderDecorationLayout _layout(BoxConstraints layoutConstraints) {
    assert(
      layoutConstraints.maxWidth < double.infinity,
      'An InputDecorator, which is typically created by a TextField, cannot '
      'have an unbounded width.\n'
      'This happens when the parent widget does not provide a finite width '
      'constraint. For example, if the InputDecorator is contained by a Row, '
      'then its width must be constrained. An Expanded widget or a SizedBox '
      'can be used to constrain the width of the InputDecorator or the '
      'TextField that contains it.',
    );

    final Map<RenderBox, double> boxToBaseline = <RenderBox, double>{};
    final BoxConstraints boxConstraints = layoutConstraints.loosen();

    boxToBaseline[prefix] = _layoutLineBox(prefix, boxConstraints);
    boxToBaseline[suffix] = _layoutLineBox(suffix, boxConstraints);
    boxToBaseline[icon] = _layoutLineBox(icon, boxConstraints);
    boxToBaseline[prefixIcon] = _layoutLineBox(prefixIcon, boxConstraints);
    boxToBaseline[suffixIcon] = _layoutLineBox(suffixIcon, boxConstraints);

    final double inputWidth = math.max(
        0.0,
        constraints.maxWidth -
            (_boxSize(icon).width +
                contentPadding.left +
                _boxSize(prefixIcon).width +
                _boxSize(prefix).width +
                _boxSize(suffix).width +
                _boxSize(suffixIcon).width +
                contentPadding.right));
    boxToBaseline[label] = _layoutLineBox(
      label,
      boxConstraints.copyWith(maxWidth: inputWidth),
    );
    boxToBaseline[hint] = _layoutLineBox(
      hint,
      boxConstraints.copyWith(minWidth: inputWidth, maxWidth: inputWidth),
    );
    boxToBaseline[counter] = _layoutLineBox(counter, boxConstraints);

    boxToBaseline[helperError] = _layoutLineBox(
      helperError,
      boxConstraints.copyWith(
        maxWidth: math.max(
          0.0,
          boxConstraints.maxWidth -
              _boxSize(icon).width -
              _boxSize(counter).width -
              contentPadding.horizontal,
        ),
      ),
    );

    final double labelHeight =
        label == null ? 0 : decoration.floatingLabelHeight;
    final double topHeight = decoration.border.isOutline
        ? math.max(labelHeight - boxToBaseline[label], 0)
        : labelHeight;
    final double counterHeight =
        counter == null ? 0 : boxToBaseline[counter] + subtextGap;
    final bool helperErrorExists =
        helperError?.size != null && helperError.size.height > 0;
    final double helperErrorHeight =
        !helperErrorExists ? 0 : helperError.size.height + subtextGap;
    final double bottomHeight = math.max(
      counterHeight,
      helperErrorHeight,
    );
    boxToBaseline[input] = _layoutLineBox(
      input,
      boxConstraints
          .deflate(EdgeInsets.only(
            top: contentPadding.top + topHeight,
            bottom: contentPadding.bottom + bottomHeight,
          ))
          .copyWith(
            minWidth: inputWidth,
            maxWidth: inputWidth,
          ),
    );

    final double hintHeight = hint == null ? 0 : hint.size.height;
    final double inputDirectHeight = input == null ? 0 : input.size.height;
    final double inputHeight = math.max(hintHeight, inputDirectHeight);
    final double inputInternalBaseline = math.max(
      boxToBaseline[input],
      boxToBaseline[hint],
    );

    final double prefixHeight = prefix == null ? 0 : prefix.size.height;
    final double suffixHeight = suffix == null ? 0 : suffix.size.height;
    final double fixHeight = math.max(
      boxToBaseline[prefix],
      boxToBaseline[suffix],
    );
    final double fixAboveInput = math.max(0, fixHeight - inputInternalBaseline);
    final double fixBelowBaseline = math.max(
      prefixHeight - boxToBaseline[prefix],
      suffixHeight - boxToBaseline[suffix],
    );
    final double fixBelowInput = math.max(
      0,
      fixBelowBaseline - (inputHeight - inputInternalBaseline),
    );

    final double prefixIconHeight =
        prefixIcon == null ? 0 : prefixIcon.size.height;
    final double suffixIconHeight =
        suffixIcon == null ? 0 : suffixIcon.size.height;
    final double fixIconHeight = math.max(prefixIconHeight, suffixIconHeight);
    final double contentHeight = math.max(
      fixIconHeight,
      topHeight +
          contentPadding.top +
          fixAboveInput +
          inputHeight +
          fixBelowInput +
          contentPadding.bottom,
    );
    final double maxContainerHeight = boxConstraints.maxHeight - bottomHeight;
    final double containerHeight = expands
        ? maxContainerHeight
        : math.min(contentHeight, maxContainerHeight);

    final double overflow = math.max(0, contentHeight - maxContainerHeight);
    final double baselineAdjustment = fixAboveInput - overflow;

    final double inputBaseline = contentPadding.top +
        topHeight +
        inputInternalBaseline +
        baselineAdjustment;

    final double outlineBaseline = inputInternalBaseline +
        baselineAdjustment / 2 +
        (containerHeight - (2.0 + inputHeight)) / 2.0;

    double subtextCounterBaseline = 0;
    double subtextHelperBaseline = 0;
    double subtextCounterHeight = 0;
    double subtextHelperHeight = 0;
    if (counter != null) {
      subtextCounterBaseline =
          containerHeight + subtextGap + boxToBaseline[counter];
      subtextCounterHeight = counter.size.height + subtextGap;
    }
    if (helperErrorExists) {
      subtextHelperBaseline =
          containerHeight + subtextGap + boxToBaseline[helperError];
      subtextHelperHeight = helperErrorHeight;
    }
    final double subtextBaseline = math.max(
      subtextCounterBaseline,
      subtextHelperBaseline,
    );
    final double subtextHeight = math.max(
      subtextCounterHeight,
      subtextHelperHeight,
    );

    return _RenderDecorationLayout(
      boxToBaseline: boxToBaseline,
      containerHeight: containerHeight,
      inputBaseline: inputBaseline,
      outlineBaseline: outlineBaseline,
      subtextBaseline: subtextBaseline,
      subtextHeight: subtextHeight,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _minWidth(icon, height) +
        contentPadding.left +
        _minWidth(prefixIcon, height) +
        _minWidth(prefix, height) +
        math.max(_minWidth(input, height), _minWidth(hint, height)) +
        _minWidth(suffix, height) +
        _minWidth(suffixIcon, height) +
        contentPadding.right;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _maxWidth(icon, height) +
        contentPadding.left +
        _maxWidth(prefixIcon, height) +
        _maxWidth(prefix, height) +
        math.max(_maxWidth(input, height), _maxWidth(hint, height)) +
        _maxWidth(suffix, height) +
        _maxWidth(suffixIcon, height) +
        contentPadding.right;
  }

  double _lineHeight(double width, List<RenderBox> boxes) {
    double height = 0.0;
    for (RenderBox box in boxes) {
      if (box == null) continue;
      height = math.max(_minHeight(box, width), height);
    }
    return height;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    double subtextHeight =
        _lineHeight(width, <RenderBox>[helperError, counter]);
    if (subtextHeight > 0.0) subtextHeight += subtextGap;
    return contentPadding.top +
        (label == null ? 0.0 : decoration.floatingLabelHeight) +
        _lineHeight(width, <RenderBox>[prefix, input, suffix]) +
        subtextHeight +
        contentPadding.bottom;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeMinIntrinsicHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return _boxParentData(input).offset.dy +
        input.computeDistanceToActualBaseline(baseline);
  }

  Matrix4 _labelTransform;

  @override
  void performLayout() {
    _labelTransform = null;
    final _RenderDecorationLayout layout = _layout(constraints);

    final double overallWidth = constraints.maxWidth;
    final double overallHeight = layout.containerHeight + layout.subtextHeight;

    if (container != null) {
      final BoxConstraints containerConstraints = BoxConstraints.tightFor(
        height: layout.containerHeight,
        width: overallWidth - _boxSize(icon).width,
      );
      container.layout(containerConstraints, parentUsesSize: true);
      double x;
      switch (textDirection) {
        case TextDirection.rtl:
          x = 0.0;
          break;
        case TextDirection.ltr:
          x = _boxSize(icon).width;
          break;
      }
      _boxParentData(container).offset = Offset(x, 0.0);
    }

    double height;
    double centerLayout(RenderBox box, double x) {
      _boxParentData(box).offset = Offset(x, (height - box.size.height) / 2.0);
      return box.size.width;
    }

    double baseline;
    double baselineLayout(RenderBox box, double x) {
      _boxParentData(box).offset =
          Offset(x, baseline - layout.boxToBaseline[box]);
      return box.size.width;
    }

    final double left = contentPadding.left;
    final double right = overallWidth - contentPadding.right;

    height = layout.containerHeight;
    baseline = decoration.isCollapsed || !decoration.border.isOutline
        ? layout.inputBaseline
        : layout.outlineBaseline;

    if (icon != null) {
      double x;
      switch (textDirection) {
        case TextDirection.rtl:
          x = overallWidth - icon.size.width;
          break;
        case TextDirection.ltr:
          x = 0.0;
          break;
      }
      centerLayout(icon, x);
    }

    switch (textDirection) {
      case TextDirection.rtl:
        {
          double start = right - _boxSize(icon).width;
          double end = left;
          if (prefixIcon != null) {
            start += contentPadding.left;
            start -= centerLayout(prefixIcon, start - prefixIcon.size.width);
          }
          if (label != null) {
            if (decoration.alignLabelWithHint) {
              baselineLayout(label, start - label.size.width);
            } else {
              centerLayout(label, start - label.size.width);
            }
          }
          if (prefix != null)
            start -= baselineLayout(prefix, start - prefix.size.width);
          if (input != null) baselineLayout(input, start - input.size.width);
          if (hint != null) baselineLayout(hint, start - hint.size.width);
          if (suffixIcon != null) {
            end -= contentPadding.left;
            end += centerLayout(suffixIcon, end);
          }
          if (suffix != null) end += baselineLayout(suffix, end);
          break;
        }
      case TextDirection.ltr:
        {
          double start = left + _boxSize(icon).width;
          double end = right;
          if (prefixIcon != null) {
            start -= contentPadding.left;
            start += centerLayout(prefixIcon, start);
          }
          if (label != null) if (decoration.alignLabelWithHint) {
            baselineLayout(label, start);
          } else {
            centerLayout(label, start);
          }
          if (prefix != null) start += baselineLayout(prefix, start);
          if (input != null) baselineLayout(input, start);
          if (hint != null) baselineLayout(hint, start);
          if (suffixIcon != null) {
            end += contentPadding.right;
            end -= centerLayout(suffixIcon, end - suffixIcon.size.width);
          }
          if (suffix != null)
            end -= baselineLayout(suffix, end - suffix.size.width);
          break;
        }
    }

    if (helperError != null || counter != null) {
      height = layout.subtextHeight;
      baseline = layout.subtextBaseline;

      switch (textDirection) {
        case TextDirection.rtl:
          if (helperError != null)
            baselineLayout(helperError,
                right - helperError.size.width - _boxSize(icon).width);
          if (counter != null) baselineLayout(counter, left);
          break;
        case TextDirection.ltr:
          if (helperError != null)
            baselineLayout(helperError, left + _boxSize(icon).width);
          if (counter != null)
            baselineLayout(counter, right - counter.size.width);
          break;
      }
    }

    if (label != null) {
      final double labelX = _boxParentData(label).offset.dx;
      switch (textDirection) {
        case TextDirection.rtl:
          decoration.borderGap.start = labelX + label.size.width;
          break;
        case TextDirection.ltr:
          decoration.borderGap.start = labelX - _boxSize(icon).width;
          break;
      }
      decoration.borderGap.extent = label.size.width * 0.75;
    } else {
      decoration.borderGap.start = null;
      decoration.borderGap.extent = 0.0;
    }

    size = constraints.constrain(Size(overallWidth, overallHeight));
    assert(size.width == constraints.constrainWidth(overallWidth));
    assert(size.height == constraints.constrainHeight(overallHeight));
  }

  void _paintLabel(PaintingContext context, Offset offset) {
    context.paintChild(label, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void doPaint(RenderBox child) {
      if (child != null)
        context.paintChild(child, _boxParentData(child).offset + offset);
    }

    doPaint(container);

    if (label != null) {
      final Offset labelOffset = _boxParentData(label).offset;
      final double labelHeight = label.size.height;
      final double t = decoration.floatingLabelProgress;

      final bool isOutlineBorder =
          decoration.border != null && decoration.border.isOutline;
      final double floatingY =
          isOutlineBorder ? -labelHeight * 0.25 : contentPadding.top;
      final double scale = lerpDouble(1.0, 0.75, t);
      double dx;
      switch (textDirection) {
        case TextDirection.rtl:
          dx = labelOffset.dx + label.size.width * (1.0 - scale);
          break;
        case TextDirection.ltr:
          dx = labelOffset.dx;
          break;
      }
      final double dy = lerpDouble(0.0, floatingY - labelOffset.dy, t);
      _labelTransform = Matrix4.identity()
        ..translate(dx, labelOffset.dy + dy)
        ..scale(scale);
      context.pushTransform(
          needsCompositing, offset, _labelTransform, _paintLabel);
    }

    doPaint(icon);
    doPaint(prefix);
    doPaint(suffix);
    doPaint(prefixIcon);
    doPaint(suffixIcon);
    doPaint(hint);
    doPaint(input);
    doPaint(helperError);
    doPaint(counter);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {@required Offset position}) {
    assert(position != null);
    for (RenderBox child in _children) {
      final Offset offset = _boxParentData(child).offset;
      final bool isHit = result.addWithPaintOffset(
        offset: offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    if (child == label && _labelTransform != null) {
      final Offset labelOffset = _boxParentData(label).offset;
      transform
        ..multiply(_labelTransform)
        ..translate(-labelOffset.dx, -labelOffset.dy);
    }
    super.applyPaintTransform(child, transform);
  }
}

class _RenderDecorationElement extends RenderObjectElement {
  _RenderDecorationElement(_Decorator widget) : super(widget);

  final Map<_DecorationSlot, Element> slotToChild =
      <_DecorationSlot, Element>{};
  final Map<Element, _DecorationSlot> childToSlot =
      <Element, _DecorationSlot>{};

  @override
  _Decorator get widget => super.widget;

  @override
  _RenderDecoration get renderObject => super.renderObject;

  @override
  void visitChildren(ElementVisitor visitor) {
    slotToChild.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(slotToChild.values.contains(child));
    assert(childToSlot.keys.contains(child));
    final _DecorationSlot slot = childToSlot[child];
    childToSlot.remove(child);
    slotToChild.remove(slot);
  }

  void _mountChild(Widget widget, _DecorationSlot slot) {
    final Element oldChild = slotToChild[slot];
    final Element newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
      childToSlot.remove(oldChild);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
      childToSlot[newChild] = slot;
    }
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.decoration.icon, _DecorationSlot.icon);
    _mountChild(widget.decoration.input, _DecorationSlot.input);
    _mountChild(widget.decoration.label, _DecorationSlot.label);
    _mountChild(widget.decoration.hint, _DecorationSlot.hint);
    _mountChild(widget.decoration.prefix, _DecorationSlot.prefix);
    _mountChild(widget.decoration.suffix, _DecorationSlot.suffix);
    _mountChild(widget.decoration.prefixIcon, _DecorationSlot.prefixIcon);
    _mountChild(widget.decoration.suffixIcon, _DecorationSlot.suffixIcon);
    _mountChild(widget.decoration.helperError, _DecorationSlot.helperError);
    _mountChild(widget.decoration.counter, _DecorationSlot.counter);
    _mountChild(widget.decoration.container, _DecorationSlot.container);
  }

  void _updateChild(Widget widget, _DecorationSlot slot) {
    final Element oldChild = slotToChild[slot];
    final Element newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      childToSlot.remove(oldChild);
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
      childToSlot[newChild] = slot;
    }
  }

  @override
  void update(_Decorator newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.decoration.icon, _DecorationSlot.icon);
    _updateChild(widget.decoration.input, _DecorationSlot.input);
    _updateChild(widget.decoration.label, _DecorationSlot.label);
    _updateChild(widget.decoration.hint, _DecorationSlot.hint);
    _updateChild(widget.decoration.prefix, _DecorationSlot.prefix);
    _updateChild(widget.decoration.suffix, _DecorationSlot.suffix);
    _updateChild(widget.decoration.prefixIcon, _DecorationSlot.prefixIcon);
    _updateChild(widget.decoration.suffixIcon, _DecorationSlot.suffixIcon);
    _updateChild(widget.decoration.helperError, _DecorationSlot.helperError);
    _updateChild(widget.decoration.counter, _DecorationSlot.counter);
    _updateChild(widget.decoration.container, _DecorationSlot.container);
  }

  void _updateRenderObject(RenderObject child, _DecorationSlot slot) {
    switch (slot) {
      case _DecorationSlot.icon:
        renderObject.icon = child;
        break;
      case _DecorationSlot.input:
        renderObject.input = child;
        break;
      case _DecorationSlot.label:
        renderObject.label = child;
        break;
      case _DecorationSlot.hint:
        renderObject.hint = child;
        break;
      case _DecorationSlot.prefix:
        renderObject.prefix = child;
        break;
      case _DecorationSlot.suffix:
        renderObject.suffix = child;
        break;
      case _DecorationSlot.prefixIcon:
        renderObject.prefixIcon = child;
        break;
      case _DecorationSlot.suffixIcon:
        renderObject.suffixIcon = child;
        break;
      case _DecorationSlot.helperError:
        renderObject.helperError = child;
        break;
      case _DecorationSlot.counter:
        renderObject.counter = child;
        break;
      case _DecorationSlot.container:
        renderObject.container = child;
        break;
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slotValue) {
    assert(child is RenderBox);
    assert(slotValue is _DecorationSlot);
    final _DecorationSlot slot = slotValue;
    _updateRenderObject(child, slot);
    assert(renderObject.childToSlot.keys.contains(child));
    assert(renderObject.slotToChild.keys.contains(slot));
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(child is RenderBox);
    assert(renderObject.childToSlot.keys.contains(child));
    _updateRenderObject(null, renderObject.childToSlot[child]);
    assert(!renderObject.childToSlot.keys.contains(child));
    assert(!renderObject.slotToChild.keys.contains(slot));
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slotValue) {
    assert(false, 'not reachable');
  }
}

class _Decorator extends RenderObjectWidget {
  const _Decorator({
    Key key,
    @required this.decoration,
    @required this.textDirection,
    @required this.textBaseline,
    @required this.isFocused,
    @required this.expands,
  })  : assert(decoration != null),
        assert(textDirection != null),
        assert(textBaseline != null),
        assert(expands != null),
        super(key: key);

  final _Decoration decoration;
  final TextDirection textDirection;
  final TextBaseline textBaseline;
  final bool isFocused;
  final bool expands;

  @override
  _RenderDecorationElement createElement() => _RenderDecorationElement(this);

  @override
  _RenderDecoration createRenderObject(BuildContext context) {
    return _RenderDecoration(
      decoration: decoration,
      textDirection: textDirection,
      textBaseline: textBaseline,
      isFocused: isFocused,
      expands: expands,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderDecoration renderObject) {
    renderObject
      ..decoration = decoration
      ..textDirection = textDirection
      ..textBaseline = textBaseline
      ..expands = expands
      ..isFocused = isFocused;
  }
}

class _AffixText extends StatelessWidget {
  const _AffixText({
    this.labelIsFloating,
    this.text,
    this.style,
    this.child,
  });

  final bool labelIsFloating;
  final String text;
  final TextStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: style,
      child: AnimatedOpacity(
        duration: _kTransitionDuration,
        curve: _kTransitionCurve,
        opacity: labelIsFloating ? 1.0 : 0.0,
        child: child ??
            Text(
              text,
              style: style,
            ),
      ),
    );
  }
}

class InputDecorator extends StatefulWidget {
  const InputDecorator({
    Key key,
    this.decoration,
    this.baseStyle,
    this.textAlign,
    this.isFocused = false,
    this.isHovering = false,
    this.expands = false,
    this.isEmpty = false,
    this.child,
  })  : assert(isFocused != null),
        assert(isHovering != null),
        assert(expands != null),
        assert(isEmpty != null),
        super(key: key);

  final InputDecoration decoration;

  final TextStyle baseStyle;

  final TextAlign textAlign;

  final bool isFocused;

  final bool isHovering;

  final bool expands;

  final bool isEmpty;

  final Widget child;

  bool get _labelShouldWithdraw => !isEmpty || isFocused;

  @override
  _InputDecoratorState createState() => _InputDecoratorState();

  static RenderBox containerOf(BuildContext context) {
    final _RenderDecoration result = context
        .ancestorRenderObjectOfType(const TypeMatcher<_RenderDecoration>());
    return result?.container;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<InputDecoration>('decoration', decoration));
    properties.add(DiagnosticsProperty<TextStyle>('baseStyle', baseStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('isFocused', isFocused));
    properties.add(
        DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('isEmpty', isEmpty));
  }
}

class _InputDecoratorState extends State<InputDecorator>
    with TickerProviderStateMixin {
  AnimationController _floatingLabelController;
  AnimationController _shakingLabelController;
  final _InputBorderGap _borderGap = _InputBorderGap();

  @override
  void initState() {
    super.initState();
    _floatingLabelController = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
      value: (widget.decoration.hasFloatingPlaceholder &&
              widget._labelShouldWithdraw)
          ? 1.0
          : 0.0,
    );
    _floatingLabelController.addListener(_handleChange);

    _shakingLabelController = AnimationController(
      duration: _kTransitionDuration,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _effectiveDecoration = null;
  }

  @override
  void dispose() {
    _floatingLabelController.dispose();
    _shakingLabelController.dispose();
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
  }

  InputDecoration _effectiveDecoration;
  InputDecoration get decoration {
    _effectiveDecoration ??=
        widget.decoration.applyDefaults(Theme.of(context).inputDecorationTheme);
    return _effectiveDecoration;
  }

  TextAlign get textAlign => widget.textAlign;
  bool get isFocused => widget.isFocused && decoration.enabled;
  bool get isHovering => widget.isHovering && decoration.enabled;
  bool get isEmpty => widget.isEmpty;

  @override
  void didUpdateWidget(InputDecorator old) {
    super.didUpdateWidget(old);
    if (widget.decoration != old.decoration) _effectiveDecoration = null;

    if (widget._labelShouldWithdraw != old._labelShouldWithdraw &&
        widget.decoration.hasFloatingPlaceholder) {
      if (widget._labelShouldWithdraw)
        _floatingLabelController.forward();
      else
        _floatingLabelController.reverse();
    }

    final String errorText = decoration.errorText;
    final String oldErrorText = old.decoration.errorText;

    if (_floatingLabelController.isCompleted &&
        errorText != null &&
        errorText != oldErrorText) {
      _shakingLabelController
        ..value = 0.0
        ..forward();
    }
  }

  Color _getActiveColor(ThemeData themeData) {
    if (isFocused) {
      switch (themeData.brightness) {
        case Brightness.dark:
          return themeData.accentColor;
        case Brightness.light:
          return themeData.primaryColor;
      }
    }
    return themeData.hintColor;
  }

  Color _getDefaultBorderColor(ThemeData themeData) {
    if (isFocused) {
      switch (themeData.brightness) {
        case Brightness.dark:
          return themeData.accentColor;
        case Brightness.light:
          return themeData.primaryColor;
      }
    }
    if (decoration.filled) {
      return themeData.hintColor;
    }
    final Color enabledColor =
        themeData.colorScheme.onSurface.withOpacity(0.38);
    if (isHovering) {
      final Color hoverColor = decoration.hoverColor ??
          themeData.inputDecorationTheme?.hoverColor ??
          themeData.hoverColor;
      return Color.alphaBlend(hoverColor.withOpacity(0.12), enabledColor);
    }
    return enabledColor;
  }

  Color _getFillColor(ThemeData themeData) {
    if (decoration.filled != true) return Colors.transparent;
    if (decoration.fillColor != null) return decoration.fillColor;

    const Color darkEnabled = Color(0x1AFFFFFF);
    const Color darkDisabled = Color(0x0DFFFFFF);
    const Color lightEnabled = Color(0x0A000000);
    const Color lightDisabled = Color(0x05000000);

    switch (themeData.brightness) {
      case Brightness.dark:
        return decoration.enabled ? darkEnabled : darkDisabled;
      case Brightness.light:
        return decoration.enabled ? lightEnabled : lightDisabled;
    }
    return lightEnabled;
  }

  Color _getHoverColor(ThemeData themeData) {
    if (decoration.filled == null ||
        !decoration.filled ||
        isFocused ||
        !decoration.enabled) return Colors.transparent;
    return decoration.hoverColor ??
        themeData.inputDecorationTheme?.hoverColor ??
        themeData.hoverColor;
  }

  Color _getDefaultIconColor(ThemeData themeData) {
    if (!decoration.enabled) return themeData.disabledColor;

    switch (themeData.brightness) {
      case Brightness.dark:
        return Colors.white70;
      case Brightness.light:
        return Colors.black45;
      default:
        return themeData.iconTheme.color;
    }
  }

  bool get _hasInlineLabel =>
      !widget._labelShouldWithdraw && decoration.labelText != null;

  bool get _shouldShowLabel =>
      _hasInlineLabel || decoration.hasFloatingPlaceholder;

  TextStyle _getInlineStyle(ThemeData themeData) {
    return themeData.textTheme.subhead.merge(widget.baseStyle).copyWith(
        color:
            decoration.enabled ? themeData.hintColor : themeData.disabledColor);
  }

  TextStyle _getFloatingLabelStyle(ThemeData themeData) {
    final Color color = decoration.errorText != null
        ? decoration.errorStyle?.color ?? themeData.errorColor
        : _getActiveColor(themeData);
    final TextStyle style = themeData.textTheme.subhead.merge(widget.baseStyle);
    return style
        .copyWith(color: decoration.enabled ? color : themeData.disabledColor)
        .merge(decoration.labelStyle);
  }

  TextStyle _getHelperStyle(ThemeData themeData) {
    final Color color =
        decoration.enabled ? themeData.hintColor : Colors.transparent;
    return themeData.textTheme.caption
        .copyWith(color: color)
        .merge(decoration.helperStyle);
  }

  TextStyle _getErrorStyle(ThemeData themeData) {
    final Color color =
        decoration.enabled ? themeData.errorColor : Colors.transparent;
    return themeData.textTheme.caption
        .copyWith(color: color)
        .merge(decoration.errorStyle);
  }

  InputBorder _getDefaultBorder(ThemeData themeData) {
    if (decoration.border?.borderSide == BorderSide.none) {
      return decoration.border;
    }

    Color borderColor;
    if (decoration.enabled) {
      borderColor = decoration.errorText == null
          ? _getDefaultBorderColor(themeData)
          : themeData.errorColor;
    } else {
      borderColor =
          (decoration.filled == true && decoration.border?.isOutline != true)
              ? Colors.transparent
              : themeData.disabledColor;
    }

    double borderWeight;
    if (decoration.isCollapsed ||
        decoration?.border == InputBorder.none ||
        !decoration.enabled)
      borderWeight = 0.0;
    else
      borderWeight = isFocused ? 2.0 : 1.0;

    final InputBorder border =
        decoration.border ?? const UnderlineInputBorder();
    return border.copyWith(
        borderSide: BorderSide(color: borderColor, width: borderWeight));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final TextStyle inlineStyle = _getInlineStyle(themeData);
    final TextBaseline textBaseline = inlineStyle.textBaseline;

    final TextStyle hintStyle = inlineStyle.merge(decoration.hintStyle);
    final Widget hint = decoration.hintText == null
        ? null
        : AnimatedOpacity(
            opacity: (isEmpty && !_hasInlineLabel) ? 1.0 : 0.0,
            duration: _kTransitionDuration,
            curve: _kTransitionCurve,
            child: Text(
              decoration.hintText,
              style: hintStyle,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              maxLines: decoration.hintMaxLines,
            ),
          );

    final bool isError = decoration.errorText != null;
    InputBorder border;
    if (!decoration.enabled)
      border = isError ? decoration.errorBorder : decoration.disabledBorder;
    else if (isFocused)
      border =
          isError ? decoration.focusedErrorBorder : decoration.focusedBorder;
    else
      border = isError ? decoration.errorBorder : decoration.enabledBorder;
    border ??= _getDefaultBorder(themeData);

    final Widget container = _BorderContainer(
      border: border,
      gap: _borderGap,
      gapAnimation: _floatingLabelController.view,
      fillColor: _getFillColor(themeData),
      hoverColor: _getHoverColor(themeData),
      isHovering: isHovering,
    );

    final TextStyle inlineLabelStyle = inlineStyle.merge(decoration.labelStyle);
    final Widget label = decoration.labelText == null
        ? null
        : _Shaker(
            animation: _shakingLabelController.view,
            child: AnimatedOpacity(
              duration: _kTransitionDuration,
              curve: _kTransitionCurve,
              opacity: _shouldShowLabel ? 1.0 : 0.0,
              child: AnimatedDefaultTextStyle(
                duration: _kTransitionDuration,
                curve: _kTransitionCurve,
                style: widget._labelShouldWithdraw
                    ? _getFloatingLabelStyle(themeData)
                    : inlineLabelStyle,
                child: Text(
                  decoration.labelText,
                  overflow: TextOverflow.ellipsis,
                  textAlign: textAlign,
                ),
              ),
            ),
          );

    final Widget prefix =
        decoration.prefix == null && decoration.prefixText == null
            ? null
            : _AffixText(
                labelIsFloating: widget._labelShouldWithdraw,
                text: decoration.prefixText,
                style: decoration.prefixStyle ?? hintStyle,
                child: decoration.prefix,
              );

    final Widget suffix =
        decoration.suffix == null && decoration.suffixText == null
            ? null
            : _AffixText(
                labelIsFloating: widget._labelShouldWithdraw,
                text: decoration.suffixText,
                style: decoration.suffixStyle ?? hintStyle,
                child: decoration.suffix,
              );

    final Color activeColor = _getActiveColor(themeData);
    final bool decorationIsDense = decoration.isDense == true;
    final double iconSize = decorationIsDense ? 18.0 : 24.0;
    final Color iconColor =
        isFocused ? activeColor : _getDefaultIconColor(themeData);

    final Widget icon = decoration.icon == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(end: 16.0),
            child: IconTheme.merge(
              data: IconThemeData(
                color: iconColor,
                size: iconSize,
              ),
              child: decoration.icon,
            ),
          );

    final Widget prefixIcon = decoration.prefixIcon == null
        ? null
        : Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: iconColor,
                  size: iconSize,
                ),
                child: decoration.prefixIcon,
              ),
            ),
          );

    final Widget suffixIcon = decoration.suffixIcon == null
        ? null
        : Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: iconColor,
                  size: iconSize,
                ),
                child: decoration.suffixIcon,
              ),
            ),
          );

    final Widget helperError = _HelperError(
      textAlign: textAlign,
      helperText: decoration.helperText,
      helperStyle: _getHelperStyle(themeData),
      errorText: decoration.errorText,
      errorStyle: _getErrorStyle(themeData),
      errorMaxLines: decoration.errorMaxLines,
    );

    Widget counter;
    if (decoration.counter != null) {
      counter = decoration.counter;
    } else if (decoration.counterText != null && decoration.counterText != '') {
      counter = Semantics(
        container: true,
        liveRegion: isFocused,
        child: Text(
          decoration.counterText,
          style: _getHelperStyle(themeData).merge(decoration.counterStyle),
          overflow: TextOverflow.ellipsis,
          semanticsLabel: decoration.semanticCounterText,
        ),
      );
    }

    final TextDirection textDirection = Directionality.of(context);
    final EdgeInsets decorationContentPadding =
        decoration.contentPadding?.resolve(textDirection);

    EdgeInsets contentPadding;
    double floatingLabelHeight;
    if (decoration.isCollapsed) {
      floatingLabelHeight = 0.0;
      contentPadding = decorationContentPadding ?? EdgeInsets.zero;
    } else if (!border.isOutline) {
      floatingLabelHeight = (4.0 + 0.75 * inlineLabelStyle.fontSize) *
          MediaQuery.textScaleFactorOf(context);
      if (decoration.filled == true) {
        contentPadding = decorationContentPadding ??
            (decorationIsDense
                ? const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0)
                : const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 12.0));
      } else {
        contentPadding = decorationContentPadding ??
            (decorationIsDense
                ? const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 8.0)
                : const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 12.0));
      }
    } else {
      floatingLabelHeight = 0.0;
      contentPadding = decorationContentPadding ??
          (decorationIsDense
              ? const EdgeInsets.fromLTRB(12.0, 20.0, 12.0, 12.0)
              : const EdgeInsets.fromLTRB(12.0, 24.0, 12.0, 16.0));
    }

    return _Decorator(
      decoration: _Decoration(
        contentPadding: contentPadding,
        isCollapsed: decoration.isCollapsed,
        floatingLabelHeight: floatingLabelHeight,
        floatingLabelProgress: _floatingLabelController.value,
        border: border,
        borderGap: _borderGap,
        icon: icon,
        input: widget.child,
        label: label,
        alignLabelWithHint: decoration.alignLabelWithHint,
        hint: hint,
        prefix: prefix,
        suffix: suffix,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        helperError: helperError,
        counter: counter,
        container: container,
      ),
      textDirection: textDirection,
      textBaseline: textBaseline,
      isFocused: isFocused,
      expands: widget.expands,
    );
  }
}

@immutable
class InputDecoration {
  const InputDecoration({
    this.icon,
    this.labelText,
    this.labelStyle,
    this.helperText,
    this.helperStyle,
    this.hintText,
    this.hintStyle,
    this.hintMaxLines,
    this.errorText,
    this.errorStyle,
    this.errorMaxLines,
    this.hasFloatingPlaceholder = true,
    this.isDense,
    this.contentPadding,
    this.prefixIcon,
    this.prefix,
    this.prefixText,
    this.prefixStyle,
    this.suffixIcon,
    this.suffix,
    this.suffixText,
    this.suffixStyle,
    this.counter,
    this.counterText,
    this.counterStyle,
    this.filled,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.errorBorder,
    this.focusedBorder,
    this.focusedErrorBorder,
    this.disabledBorder,
    this.enabledBorder,
    this.border,
    this.enabled = true,
    this.semanticCounterText,
    this.alignLabelWithHint,
  })  : assert(enabled != null),
        assert(!(prefix != null && prefixText != null),
            'Declaring both prefix and prefixText is not supported.'),
        assert(!(suffix != null && suffixText != null),
            'Declaring both suffix and suffixText is not supported.'),
        isCollapsed = false;

  const InputDecoration.collapsed({
    @required this.hintText,
    this.hasFloatingPlaceholder = true,
    this.hintStyle,
    this.filled = false,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.border = InputBorder.none,
    this.enabled = true,
  })  : assert(enabled != null),
        icon = null,
        labelText = null,
        labelStyle = null,
        helperText = null,
        helperStyle = null,
        hintMaxLines = null,
        errorText = null,
        errorStyle = null,
        errorMaxLines = null,
        isDense = false,
        contentPadding = EdgeInsets.zero,
        isCollapsed = true,
        prefixIcon = null,
        prefix = null,
        prefixText = null,
        prefixStyle = null,
        suffix = null,
        suffixIcon = null,
        suffixText = null,
        suffixStyle = null,
        counter = null,
        counterText = null,
        counterStyle = null,
        errorBorder = null,
        focusedBorder = null,
        focusedErrorBorder = null,
        disabledBorder = null,
        enabledBorder = null,
        semanticCounterText = null,
        alignLabelWithHint = false;

  final Widget icon;

  final String labelText;

  final TextStyle labelStyle;

  final String helperText;

  final TextStyle helperStyle;

  final String hintText;

  final TextStyle hintStyle;

  final int hintMaxLines;

  final String errorText;

  final TextStyle errorStyle;

  final int errorMaxLines;

  final bool hasFloatingPlaceholder;

  final bool isDense;

  final EdgeInsetsGeometry contentPadding;

  final bool isCollapsed;

  final Widget prefixIcon;

  final Widget prefix;

  final String prefixText;

  final TextStyle prefixStyle;

  final Widget suffixIcon;

  final Widget suffix;

  final String suffixText;

  final TextStyle suffixStyle;

  final String counterText;

  final Widget counter;

  final TextStyle counterStyle;

  final bool filled;

  final Color fillColor;

  final Color focusColor;

  final Color hoverColor;

  final InputBorder errorBorder;

  final InputBorder focusedBorder;

  final InputBorder focusedErrorBorder;

  final InputBorder disabledBorder;

  final InputBorder enabledBorder;

  final InputBorder border;

  final bool enabled;

  final String semanticCounterText;

  final bool alignLabelWithHint;

  InputDecoration copyWith({
    Widget icon,
    String labelText,
    TextStyle labelStyle,
    String helperText,
    TextStyle helperStyle,
    String hintText,
    TextStyle hintStyle,
    int hintMaxLines,
    String errorText,
    TextStyle errorStyle,
    int errorMaxLines,
    bool hasFloatingPlaceholder,
    bool isDense,
    EdgeInsetsGeometry contentPadding,
    Widget prefixIcon,
    Widget prefix,
    String prefixText,
    TextStyle prefixStyle,
    Widget suffixIcon,
    Widget suffix,
    String suffixText,
    TextStyle suffixStyle,
    Widget counter,
    String counterText,
    TextStyle counterStyle,
    bool filled,
    Color fillColor,
    Color focusColor,
    Color hoverColor,
    InputBorder errorBorder,
    InputBorder focusedBorder,
    InputBorder focusedErrorBorder,
    InputBorder disabledBorder,
    InputBorder enabledBorder,
    InputBorder border,
    bool enabled,
    String semanticCounterText,
    bool alignLabelWithHint,
  }) {
    return InputDecoration(
      icon: icon ?? this.icon,
      labelText: labelText ?? this.labelText,
      labelStyle: labelStyle ?? this.labelStyle,
      helperText: helperText ?? this.helperText,
      helperStyle: helperStyle ?? this.helperStyle,
      hintText: hintText ?? this.hintText,
      hintStyle: hintStyle ?? this.hintStyle,
      hintMaxLines: hintMaxLines ?? this.hintMaxLines,
      errorText: errorText ?? this.errorText,
      errorStyle: errorStyle ?? this.errorStyle,
      errorMaxLines: errorMaxLines ?? this.errorMaxLines,
      hasFloatingPlaceholder:
          hasFloatingPlaceholder ?? this.hasFloatingPlaceholder,
      isDense: isDense ?? this.isDense,
      contentPadding: contentPadding ?? this.contentPadding,
      prefixIcon: prefixIcon ?? this.prefixIcon,
      prefix: prefix ?? this.prefix,
      prefixText: prefixText ?? this.prefixText,
      prefixStyle: prefixStyle ?? this.prefixStyle,
      suffixIcon: suffixIcon ?? this.suffixIcon,
      suffix: suffix ?? this.suffix,
      suffixText: suffixText ?? this.suffixText,
      suffixStyle: suffixStyle ?? this.suffixStyle,
      counter: counter ?? this.counter,
      counterText: counterText ?? this.counterText,
      counterStyle: counterStyle ?? this.counterStyle,
      filled: filled ?? this.filled,
      fillColor: fillColor ?? this.fillColor,
      focusColor: focusColor ?? this.focusColor,
      hoverColor: hoverColor ?? this.hoverColor,
      errorBorder: errorBorder ?? this.errorBorder,
      focusedBorder: focusedBorder ?? this.focusedBorder,
      focusedErrorBorder: focusedErrorBorder ?? this.focusedErrorBorder,
      disabledBorder: disabledBorder ?? this.disabledBorder,
      enabledBorder: enabledBorder ?? this.enabledBorder,
      border: border ?? this.border,
      enabled: enabled ?? this.enabled,
      semanticCounterText: semanticCounterText ?? this.semanticCounterText,
      alignLabelWithHint: alignLabelWithHint ?? this.alignLabelWithHint,
    );
  }

  InputDecoration applyDefaults(InputDecorationTheme theme) {
    return copyWith(
      labelStyle: labelStyle ?? theme.labelStyle,
      helperStyle: helperStyle ?? theme.helperStyle,
      hintStyle: hintStyle ?? theme.hintStyle,
      errorStyle: errorStyle ?? theme.errorStyle,
      errorMaxLines: errorMaxLines ?? theme.errorMaxLines,
      hasFloatingPlaceholder:
          hasFloatingPlaceholder ?? theme.hasFloatingPlaceholder,
      isDense: isDense ?? theme.isDense,
      contentPadding: contentPadding ?? theme.contentPadding,
      prefixStyle: prefixStyle ?? theme.prefixStyle,
      suffixStyle: suffixStyle ?? theme.suffixStyle,
      counterStyle: counterStyle ?? theme.counterStyle,
      filled: filled ?? theme.filled,
      fillColor: fillColor ?? theme.fillColor,
      focusColor: focusColor ?? theme.focusColor,
      hoverColor: hoverColor ?? theme.hoverColor,
      errorBorder: errorBorder ?? theme.errorBorder,
      focusedBorder: focusedBorder ?? theme.focusedBorder,
      focusedErrorBorder: focusedErrorBorder ?? theme.focusedErrorBorder,
      disabledBorder: disabledBorder ?? theme.disabledBorder,
      enabledBorder: enabledBorder ?? theme.enabledBorder,
      border: border ?? theme.border,
      alignLabelWithHint: alignLabelWithHint ?? theme.alignLabelWithHint,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final InputDecoration typedOther = other;
    return typedOther.icon == icon &&
        typedOther.labelText == labelText &&
        typedOther.labelStyle == labelStyle &&
        typedOther.helperText == helperText &&
        typedOther.helperStyle == helperStyle &&
        typedOther.hintText == hintText &&
        typedOther.hintStyle == hintStyle &&
        typedOther.hintMaxLines == hintMaxLines &&
        typedOther.errorText == errorText &&
        typedOther.errorStyle == errorStyle &&
        typedOther.errorMaxLines == errorMaxLines &&
        typedOther.hasFloatingPlaceholder == hasFloatingPlaceholder &&
        typedOther.isDense == isDense &&
        typedOther.contentPadding == contentPadding &&
        typedOther.isCollapsed == isCollapsed &&
        typedOther.prefixIcon == prefixIcon &&
        typedOther.prefix == prefix &&
        typedOther.prefixText == prefixText &&
        typedOther.prefixStyle == prefixStyle &&
        typedOther.suffixIcon == suffixIcon &&
        typedOther.suffix == suffix &&
        typedOther.suffixText == suffixText &&
        typedOther.suffixStyle == suffixStyle &&
        typedOther.counter == counter &&
        typedOther.counterText == counterText &&
        typedOther.counterStyle == counterStyle &&
        typedOther.filled == filled &&
        typedOther.fillColor == fillColor &&
        typedOther.focusColor == focusColor &&
        typedOther.hoverColor == hoverColor &&
        typedOther.errorBorder == errorBorder &&
        typedOther.focusedBorder == focusedBorder &&
        typedOther.focusedErrorBorder == focusedErrorBorder &&
        typedOther.disabledBorder == disabledBorder &&
        typedOther.enabledBorder == enabledBorder &&
        typedOther.border == border &&
        typedOther.enabled == enabled &&
        typedOther.semanticCounterText == semanticCounterText &&
        typedOther.alignLabelWithHint == alignLabelWithHint;
  }

  @override
  int get hashCode {
    final List<Object> values = <Object>[
      icon,
      labelText,
      labelStyle,
      helperText,
      helperStyle,
      hintText,
      hintStyle,
      hintMaxLines,
      errorText,
      errorStyle,
      errorMaxLines,
      hasFloatingPlaceholder,
      isDense,
      contentPadding,
      isCollapsed,
      filled,
      fillColor,
      focusColor,
      hoverColor,
      border,
      enabled,
      prefixIcon,
      prefix,
      prefixText,
      prefixStyle,
      suffixIcon,
      suffix,
      suffixText,
      suffixStyle,
      counter,
      counterText,
      counterStyle,
      errorBorder,
      focusedBorder,
      focusedErrorBorder,
      disabledBorder,
      enabledBorder,
      border,
      enabled,
      semanticCounterText,
      alignLabelWithHint,
    ];
    return hashList(values);
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    if (icon != null) description.add('icon: $icon');
    if (labelText != null) description.add('labelText: "$labelText"');
    if (helperText != null) description.add('helperText: "$helperText"');
    if (hintText != null) description.add('hintText: "$hintText"');
    if (hintMaxLines != null) description.add('hintMaxLines: "$hintMaxLines"');
    if (errorText != null) description.add('errorText: "$errorText"');
    if (errorStyle != null) description.add('errorStyle: "$errorStyle"');
    if (errorMaxLines != null)
      description.add('errorMaxLines: "$errorMaxLines"');
    if (hasFloatingPlaceholder == false)
      description.add('hasFloatingPlaceholder: false');
    if (isDense ?? false) description.add('isDense: $isDense');
    if (contentPadding != null)
      description.add('contentPadding: $contentPadding');
    if (isCollapsed) description.add('isCollapsed: $isCollapsed');
    if (prefixIcon != null) description.add('prefixIcon: $prefixIcon');
    if (prefix != null) description.add('prefix: $prefix');
    if (prefixText != null) description.add('prefixText: $prefixText');
    if (prefixStyle != null) description.add('prefixStyle: $prefixStyle');
    if (suffixIcon != null) description.add('suffixIcon: $suffixIcon');
    if (suffix != null) description.add('suffix: $suffix');
    if (suffixText != null) description.add('suffixText: $suffixText');
    if (suffixStyle != null) description.add('suffixStyle: $suffixStyle');
    if (counter != null) description.add('counter: $counter');
    if (counterText != null) description.add('counterText: $counterText');
    if (counterStyle != null) description.add('counterStyle: $counterStyle');
    if (filled == true) description.add('filled: true');
    if (fillColor != null) description.add('fillColor: $fillColor');
    if (focusColor != null) description.add('focusColor: $focusColor');
    if (hoverColor != null) description.add('hoverColor: $hoverColor');
    if (errorBorder != null) description.add('errorBorder: $errorBorder');
    if (focusedBorder != null) description.add('focusedBorder: $focusedBorder');
    if (focusedErrorBorder != null)
      description.add('focusedErrorBorder: $focusedErrorBorder');
    if (disabledBorder != null)
      description.add('disabledBorder: $disabledBorder');
    if (enabledBorder != null) description.add('enabledBorder: $enabledBorder');
    if (border != null) description.add('border: $border');
    if (!enabled) description.add('enabled: false');
    if (semanticCounterText != null)
      description.add('semanticCounterText: $semanticCounterText');
    if (alignLabelWithHint != null)
      description.add('alignLabelWithHint: $alignLabelWithHint');
    return 'InputDecoration(${description.join(', ')})';
  }
}

@immutable
class InputDecorationTheme extends Diagnosticable {
  const InputDecorationTheme({
    this.labelStyle,
    this.helperStyle,
    this.hintStyle,
    this.errorStyle,
    this.errorMaxLines,
    this.hasFloatingPlaceholder = true,
    this.isDense = false,
    this.contentPadding,
    this.isCollapsed = false,
    this.prefixStyle,
    this.suffixStyle,
    this.counterStyle,
    this.filled = false,
    this.fillColor,
    this.focusColor,
    this.hoverColor,
    this.errorBorder,
    this.focusedBorder,
    this.focusedErrorBorder,
    this.disabledBorder,
    this.enabledBorder,
    this.border,
    this.alignLabelWithHint = false,
  })  : assert(isDense != null),
        assert(isCollapsed != null),
        assert(filled != null),
        assert(alignLabelWithHint != null);

  final TextStyle labelStyle;

  final TextStyle helperStyle;

  final TextStyle hintStyle;

  final TextStyle errorStyle;

  final int errorMaxLines;

  final bool hasFloatingPlaceholder;

  final bool isDense;

  final EdgeInsetsGeometry contentPadding;

  final bool isCollapsed;

  final TextStyle prefixStyle;

  final TextStyle suffixStyle;

  final TextStyle counterStyle;

  final bool filled;

  final Color fillColor;

  final Color focusColor;

  final Color hoverColor;

  final InputBorder errorBorder;

  final InputBorder focusedBorder;

  final InputBorder focusedErrorBorder;

  final InputBorder disabledBorder;

  final InputBorder enabledBorder;

  final InputBorder border;

  final bool alignLabelWithHint;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const InputDecorationTheme defaultTheme = InputDecorationTheme();
    properties.add(DiagnosticsProperty<TextStyle>('labelStyle', labelStyle,
        defaultValue: defaultTheme.labelStyle));
    properties.add(DiagnosticsProperty<TextStyle>('helperStyle', helperStyle,
        defaultValue: defaultTheme.helperStyle));
    properties.add(DiagnosticsProperty<TextStyle>('hintStyle', hintStyle,
        defaultValue: defaultTheme.hintStyle));
    properties.add(DiagnosticsProperty<TextStyle>('errorStyle', errorStyle,
        defaultValue: defaultTheme.errorStyle));
    properties.add(IntProperty('errorMaxLines', errorMaxLines,
        defaultValue: defaultTheme.errorMaxLines));
    properties.add(DiagnosticsProperty<bool>(
        'hasFloatingPlaceholder', hasFloatingPlaceholder,
        defaultValue: defaultTheme.hasFloatingPlaceholder));
    properties.add(DiagnosticsProperty<bool>('isDense', isDense,
        defaultValue: defaultTheme.isDense));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>(
        'contentPadding', contentPadding,
        defaultValue: defaultTheme.contentPadding));
    properties.add(DiagnosticsProperty<bool>('isCollapsed', isCollapsed,
        defaultValue: defaultTheme.isCollapsed));
    properties.add(DiagnosticsProperty<TextStyle>('prefixStyle', prefixStyle,
        defaultValue: defaultTheme.prefixStyle));
    properties.add(DiagnosticsProperty<TextStyle>('suffixStyle', suffixStyle,
        defaultValue: defaultTheme.suffixStyle));
    properties.add(DiagnosticsProperty<TextStyle>('counterStyle', counterStyle,
        defaultValue: defaultTheme.counterStyle));
    properties.add(DiagnosticsProperty<bool>('filled', filled,
        defaultValue: defaultTheme.filled));
    properties.add(DiagnosticsProperty<Color>('fillColor', fillColor,
        defaultValue: defaultTheme.fillColor));
    properties.add(DiagnosticsProperty<Color>('focusColor', focusColor,
        defaultValue: defaultTheme.focusColor));
    properties.add(DiagnosticsProperty<Color>('hoverColor', hoverColor,
        defaultValue: defaultTheme.hoverColor));
    properties.add(DiagnosticsProperty<InputBorder>('errorBorder', errorBorder,
        defaultValue: defaultTheme.errorBorder));
    properties.add(DiagnosticsProperty<InputBorder>(
        'focusedBorder', focusedBorder,
        defaultValue: defaultTheme.focusedErrorBorder));
    properties.add(DiagnosticsProperty<InputBorder>(
        'focusedErrorBorder', focusedErrorBorder,
        defaultValue: defaultTheme.focusedErrorBorder));
    properties.add(DiagnosticsProperty<InputBorder>(
        'disabledBorder', disabledBorder,
        defaultValue: defaultTheme.disabledBorder));
    properties.add(DiagnosticsProperty<InputBorder>(
        'enabledBorder', enabledBorder,
        defaultValue: defaultTheme.enabledBorder));
    properties.add(DiagnosticsProperty<InputBorder>('border', border,
        defaultValue: defaultTheme.border));
    properties.add(DiagnosticsProperty<bool>(
        'alignLabelWithHint', alignLabelWithHint,
        defaultValue: defaultTheme.alignLabelWithHint));
  }
}

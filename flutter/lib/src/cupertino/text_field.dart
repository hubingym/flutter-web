import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/services.dart';
import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'icons.dart';
import 'text_selection.dart';
import 'theme.dart';

export 'package:flutter_web/services.dart'
    show TextInputType, TextInputAction, TextCapitalization;

const BorderSide _kDefaultRoundedBorderSide = BorderSide(
  color: CupertinoColors.lightBackgroundGray,
  style: BorderStyle.solid,
  width: 0.0,
);
const Border _kDefaultRoundedBorder = Border(
  top: _kDefaultRoundedBorderSide,
  bottom: _kDefaultRoundedBorderSide,
  left: _kDefaultRoundedBorderSide,
  right: _kDefaultRoundedBorderSide,
);

const BoxDecoration _kDefaultRoundedBorderDecoration = BoxDecoration(
  border: _kDefaultRoundedBorder,
  borderRadius: BorderRadius.all(Radius.circular(4.0)),
);

const Color _kSelectionHighlightColor = Color(0x667FAACF);
const Color _kInactiveTextColor = Color(0xFFC2C2C2);
const Color _kDisabledBackground = Color(0xFFFAFAFA);

const int _iOSHorizontalCursorOffsetPixels = -2;

enum OverlayVisibilityMode {
  never,

  editing,

  notEditing,

  always,
}

class _CupertinoTextFieldSelectionGestureDetectorBuilder
    extends TextSelectionGestureDetectorBuilder {
  _CupertinoTextFieldSelectionGestureDetectorBuilder(
      {@required _CupertinoTextFieldState state})
      : _state = state,
        super(delegate: state);

  final _CupertinoTextFieldState _state;

  @override
  void onSingleTapUp(TapUpDetails details) {
    if (_state._clearGlobalKey.currentContext != null) {
      final RenderBox renderBox =
          _state._clearGlobalKey.currentContext.findRenderObject();
      final Offset localOffset =
          renderBox.globalToLocal(details.globalPosition);
      if (renderBox.hitTest(BoxHitTestResult(), position: localOffset)) {
        return;
      }
    }
    super.onSingleTapUp(details);
    _state._requestKeyboard();
    if (_state.widget.onTap != null) _state.widget.onTap();
  }

  @override
  void onDragSelectionEnd(DragEndDetails details) {
    _state._requestKeyboard();
  }
}

class CupertinoTextField extends StatefulWidget {
  const CupertinoTextField({
    Key key,
    this.controller,
    this.focusNode,
    this.decoration = _kDefaultRoundedBorderDecoration,
    this.padding = const EdgeInsets.all(6.0),
    this.placeholder,
    this.placeholderStyle = const TextStyle(
        fontWeight: FontWeight.w300, color: _kInactiveTextColor),
    this.prefix,
    this.prefixMode = OverlayVisibilityMode.always,
    this.suffix,
    this.suffixMode = OverlayVisibilityMode.always,
    this.clearButtonMode = OverlayVisibilityMode.never,
    TextInputType keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.readOnly = false,
    ToolbarOptions toolbarOptions,
    this.showCursor,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforced = true,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorRadius = const Radius.circular(2.0),
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.onTap,
    this.scrollController,
    this.scrollPhysics,
  })  : assert(textAlign != null),
        assert(readOnly != null),
        assert(autofocus != null),
        assert(obscureText != null),
        assert(autocorrect != null),
        assert(maxLengthEnforced != null),
        assert(scrollPadding != null),
        assert(dragStartBehavior != null),
        assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          'minLines can\'t be greater than maxLines',
        ),
        assert(expands != null),
        assert(
          !expands || (maxLines == null && minLines == null),
          'minLines and maxLines must be null when expands is true.',
        ),
        assert(maxLength == null || maxLength > 0),
        assert(clearButtonMode != null),
        assert(prefixMode != null),
        assert(suffixMode != null),
        keyboardType = keyboardType ??
            (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
        toolbarOptions = toolbarOptions ?? obscureText
            ? const ToolbarOptions(
                selectAll: true,
                paste: true,
              )
            : const ToolbarOptions(
                copy: true,
                cut: true,
                selectAll: true,
                paste: true,
              ),
        super(key: key);

  final TextEditingController controller;

  final FocusNode focusNode;

  final BoxDecoration decoration;

  final EdgeInsetsGeometry padding;

  final String placeholder;

  final TextStyle placeholderStyle;

  final Widget prefix;

  final OverlayVisibilityMode prefixMode;

  final Widget suffix;

  final OverlayVisibilityMode suffixMode;

  final OverlayVisibilityMode clearButtonMode;

  final TextInputType keyboardType;

  final TextInputAction textInputAction;

  final TextCapitalization textCapitalization;

  final TextStyle style;

  final StrutStyle strutStyle;

  final TextAlign textAlign;

  final ToolbarOptions toolbarOptions;

  final TextAlignVertical textAlignVertical;

  final bool readOnly;

  final bool showCursor;

  final bool autofocus;

  final bool obscureText;

  final bool autocorrect;

  final int maxLines;

  final int minLines;

  final bool expands;

  final int maxLength;

  final bool maxLengthEnforced;

  final ValueChanged<String> onChanged;

  final VoidCallback onEditingComplete;

  final ValueChanged<String> onSubmitted;

  final List<TextInputFormatter> inputFormatters;

  final bool enabled;

  final double cursorWidth;

  final Radius cursorRadius;

  final Color cursorColor;

  final Brightness keyboardAppearance;

  final EdgeInsets scrollPadding;

  final bool enableInteractiveSelection;

  final DragStartBehavior dragStartBehavior;

  final ScrollController scrollController;

  final ScrollPhysics scrollPhysics;

  bool get selectionEnabled => enableInteractiveSelection;

  final GestureTapCallback onTap;

  @override
  _CupertinoTextFieldState createState() => _CupertinoTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextEditingController>(
        'controller', controller,
        defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<BoxDecoration>('decoration', decoration));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(StringProperty('placeholder', placeholder));
    properties.add(
        DiagnosticsProperty<TextStyle>('placeholderStyle', placeholderStyle));
    properties.add(DiagnosticsProperty<OverlayVisibilityMode>(
        'prefix', prefix == null ? null : prefixMode));
    properties.add(DiagnosticsProperty<OverlayVisibilityMode>(
        'suffix', suffix == null ? null : suffixMode));
    properties.add(DiagnosticsProperty<OverlayVisibilityMode>(
        'clearButtonMode', clearButtonMode));
    properties.add(DiagnosticsProperty<TextInputType>(
        'keyboardType', keyboardType,
        defaultValue: TextInputType.text));
    properties.add(
        DiagnosticsProperty<TextStyle>('style', style, defaultValue: null));
    properties.add(
        DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('obscureText', obscureText,
        defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('autocorrect', autocorrect,
        defaultValue: false));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: 1));
    properties.add(IntProperty('minLines', minLines, defaultValue: null));
    properties.add(
        DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties.add(IntProperty('maxLength', maxLength, defaultValue: null));
    properties.add(FlagProperty('maxLengthEnforced',
        value: maxLengthEnforced, ifTrue: 'max length enforced'));
    properties
        .add(ColorProperty('cursorColor', cursorColor, defaultValue: null));
    properties.add(FlagProperty('selectionEnabled',
        value: selectionEnabled,
        defaultValue: true,
        ifFalse: 'selection disabled'));
    properties.add(DiagnosticsProperty<ScrollController>(
        'scrollController', scrollController,
        defaultValue: null));
    properties.add(DiagnosticsProperty<ScrollPhysics>(
        'scrollPhysics', scrollPhysics,
        defaultValue: null));
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign,
        defaultValue: TextAlign.start));
    properties.add(DiagnosticsProperty<TextAlignVertical>(
        'textAlignVertical', textAlignVertical,
        defaultValue: null));
  }
}

class _CupertinoTextFieldState extends State<CupertinoTextField>
    with AutomaticKeepAliveClientMixin
    implements TextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey _clearGlobalKey = GlobalKey();

  TextEditingController _controller;
  TextEditingController get _effectiveController =>
      widget.controller ?? _controller;

  FocusNode _focusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= FocusNode());

  bool _showSelectionHandles = false;

  _CupertinoTextFieldSelectionGestureDetectorBuilder
      _selectionGestureDetectorBuilder;

  @override
  bool get forcePressEnabled => true;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get selectionEnabled => widget.selectionEnabled;

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder =
        _CupertinoTextFieldSelectionGestureDetectorBuilder(state: this);
    if (widget.controller == null) {
      _controller = TextEditingController();
      _controller.addListener(updateKeepAlive);
    }
  }

  @override
  void didUpdateWidget(CupertinoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null) {
      _controller = TextEditingController.fromValue(oldWidget.controller.value);
      _controller.addListener(updateKeepAlive);
    } else if (widget.controller != null && oldWidget.controller == null) {
      _controller = null;
    }
    final bool isEnabled = widget.enabled ?? true;
    final bool wasEnabled = oldWidget.enabled ?? true;
    if (wasEnabled && !isEnabled) {
      _effectiveFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    _controller?.removeListener(updateKeepAlive);
    super.dispose();
  }

  EditableTextState get _editableText => editableTextKey.currentState;

  void _requestKeyboard() {
    _editableText?.requestKeyboard();
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause cause) {
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar)
      return false;

    if (_effectiveController.selection.isCollapsed) return false;

    if (cause == SelectionChangedCause.keyboard) return false;

    if (_effectiveController.text.isNotEmpty) return true;

    return false;
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause cause) {
    if (cause == SelectionChangedCause.longPress) {
      _editableText?.bringIntoView(selection.base);
    }
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }
  }

  @override
  bool get wantKeepAlive => _controller?.text?.isNotEmpty == true;

  bool _shouldShowAttachment({
    OverlayVisibilityMode attachment,
    bool hasText,
  }) {
    switch (attachment) {
      case OverlayVisibilityMode.never:
        return false;
      case OverlayVisibilityMode.always:
        return true;
      case OverlayVisibilityMode.editing:
        return hasText;
      case OverlayVisibilityMode.notEditing:
        return !hasText;
    }
    assert(false);
    return null;
  }

  bool _showPrefixWidget(TextEditingValue text) {
    return widget.prefix != null &&
        _shouldShowAttachment(
          attachment: widget.prefixMode,
          hasText: text.text.isNotEmpty,
        );
  }

  bool _showSuffixWidget(TextEditingValue text) {
    return widget.suffix != null &&
        _shouldShowAttachment(
          attachment: widget.suffixMode,
          hasText: text.text.isNotEmpty,
        );
  }

  bool _showClearButton(TextEditingValue text) {
    return _shouldShowAttachment(
      attachment: widget.clearButtonMode,
      hasText: text.text.isNotEmpty,
    );
  }

  bool get _hasDecoration {
    return widget.placeholder != null ||
        widget.clearButtonMode != OverlayVisibilityMode.never ||
        widget.prefix != null ||
        widget.suffix != null;
  }

  TextAlignVertical get _textAlignVertical {
    if (widget.textAlignVertical != null) {
      return widget.textAlignVertical;
    }
    return _hasDecoration ? TextAlignVertical.center : TextAlignVertical.top;
  }

  Widget _addTextDependentAttachments(
      Widget editableText, TextStyle textStyle, TextStyle placeholderStyle) {
    assert(editableText != null);
    assert(textStyle != null);
    assert(placeholderStyle != null);

    if (!_hasDecoration) {
      return editableText;
    }

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _effectiveController,
      child: editableText,
      builder: (BuildContext context, TextEditingValue text, Widget child) {
        final List<Widget> rowChildren = <Widget>[];

        if (_showPrefixWidget(text)) {
          rowChildren.add(widget.prefix);
        }

        final List<Widget> stackChildren = <Widget>[];

        if (widget.placeholder != null && text.text.isEmpty) {
          stackChildren.add(
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: widget.padding,
                child: Text(
                  widget.placeholder,
                  maxLines: widget.maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: placeholderStyle,
                  textAlign: widget.textAlign,
                ),
              ),
            ),
          );
        }

        rowChildren
            .add(Expanded(child: Stack(children: stackChildren..add(child))));

        if (_showSuffixWidget(text)) {
          rowChildren.add(widget.suffix);
        } else if (_showClearButton(text)) {
          rowChildren.add(
            GestureDetector(
              key: _clearGlobalKey,
              onTap: widget.enabled ?? true
                  ? () {
                      final bool textChanged =
                          _effectiveController.text.isNotEmpty;
                      _effectiveController.clear();
                      if (widget.onChanged != null && textChanged)
                        widget.onChanged(_effectiveController.text);
                    }
                  : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0),
                child: Icon(
                  CupertinoIcons.clear_thick_circled,
                  size: 18.0,
                  color: _kInactiveTextColor,
                ),
              ),
            ),
          );
        }

        return Row(children: rowChildren);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    assert(debugCheckHasDirectionality(context));
    final TextEditingController controller = _effectiveController;
    final List<TextInputFormatter> formatters =
        widget.inputFormatters ?? <TextInputFormatter>[];
    final bool enabled = widget.enabled ?? true;
    final Offset cursorOffset = Offset(
        _iOSHorizontalCursorOffsetPixels /
            MediaQuery.of(context).devicePixelRatio,
        0);
    if (widget.maxLength != null && widget.maxLengthEnforced) {
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength));
    }
    final CupertinoThemeData themeData = CupertinoTheme.of(context);
    final TextStyle textStyle =
        themeData.textTheme.textStyle.merge(widget.style);
    final TextStyle placeholderStyle = textStyle.merge(widget.placeholderStyle);
    final Brightness keyboardAppearance =
        widget.keyboardAppearance ?? themeData.brightness;
    final Color cursorColor = widget.cursorColor ?? themeData.primaryColor;
    final Color disabledColor =
        CupertinoTheme.of(context).brightness == Brightness.light
            ? _kDisabledBackground
            : CupertinoColors.darkBackgroundGray;

    final BoxDecoration effectiveDecoration = enabled
        ? widget.decoration
        : widget.decoration
            ?.copyWith(color: widget.decoration?.color ?? disabledColor);

    final Widget paddedEditable = Padding(
      padding: widget.padding,
      child: RepaintBoundary(
        child: EditableText(
          key: editableTextKey,
          controller: controller,
          readOnly: widget.readOnly,
          toolbarOptions: widget.toolbarOptions,
          showCursor: widget.showCursor,
          showSelectionHandles: _showSelectionHandles,
          focusNode: _effectiveFocusNode,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          style: textStyle,
          strutStyle: widget.strutStyle,
          textAlign: widget.textAlign,
          autofocus: widget.autofocus,
          obscureText: widget.obscureText,
          autocorrect: widget.autocorrect,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          expands: widget.expands,
          selectionColor: _kSelectionHighlightColor,
          selectionControls:
              widget.selectionEnabled ? cupertinoTextSelectionControls : null,
          onChanged: widget.onChanged,
          onSelectionChanged: _handleSelectionChanged,
          onEditingComplete: widget.onEditingComplete,
          onSubmitted: widget.onSubmitted,
          inputFormatters: formatters,
          rendererIgnoresPointer: true,
          cursorWidth: widget.cursorWidth,
          cursorRadius: widget.cursorRadius,
          cursorColor: cursorColor,
          cursorOpacityAnimates: true,
          cursorOffset: cursorOffset,
          paintCursorAboveText: true,
          backgroundCursorColor: CupertinoColors.inactiveGray,
          scrollPadding: widget.scrollPadding,
          keyboardAppearance: keyboardAppearance,
          dragStartBehavior: widget.dragStartBehavior,
          scrollController: widget.scrollController,
          scrollPhysics: widget.scrollPhysics,
          enableInteractiveSelection: widget.enableInteractiveSelection,
        ),
      ),
    );

    return Semantics(
      onTap: () {
        if (!controller.selection.isValid) {
          controller.selection =
              TextSelection.collapsed(offset: controller.text.length);
        }
        _requestKeyboard();
      },
      child: IgnorePointer(
        ignoring: !enabled,
        child: Container(
          decoration: effectiveDecoration,
          child: _selectionGestureDetectorBuilder.buildGestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Align(
              alignment: Alignment(-1.0, _textAlignVertical.y),
              widthFactor: 1.0,
              heightFactor: 1.0,
              child: _addTextDependentAttachments(
                  paddedEditable, textStyle, placeholderStyle),
            ),
          ),
        ),
      ),
    );
  }
}

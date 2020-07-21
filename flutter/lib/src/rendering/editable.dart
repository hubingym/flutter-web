import 'dart:math' as math;
import 'package:flutter_web/ui.dart' as ui show TextBox, lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/semantics.dart';
import 'package:flutter_web/services.dart';

import 'box.dart';
import 'object.dart';
import 'viewport_offset.dart';

const double _kCaretGap = 1.0;
const double _kCaretHeightOffset = 2.0;

const Offset _kFloatingCaretSizeIncrease = Offset(0.5, 1.0);

const double _kFloatingCaretRadius = 1.0;

typedef SelectionChangedHandler = void Function(TextSelection selection,
    RenderEditable renderObject, SelectionChangedCause cause);

typedef PlatformInputPaintCallback = void Function();

enum SelectionChangedCause {
  tap,

  doubleTap,

  longPress,

  forcePress,

  keyboard,

  drag,
}

typedef CaretChangedHandler = void Function(Rect caretRect);

@immutable
class TextSelectionPoint {
  const TextSelectionPoint(this.point, this.direction) : assert(point != null);

  final Offset point;

  final TextDirection direction;

  @override
  String toString() {
    switch (direction) {
      case TextDirection.ltr:
        return '$point-ltr';
      case TextDirection.rtl:
        return '$point-rtl';
    }
    return '$point';
  }
}

class RenderEditable extends RenderBox {
  RenderEditable({
    TextSpan text,
    @required TextDirection textDirection,
    TextAlign textAlign = TextAlign.start,
    Color cursorColor,
    Color backgroundCursorColor,
    ValueNotifier<bool> showCursor,
    bool hasFocus,
    int maxLines = 1,
    int minLines,
    bool expands = false,
    StrutStyle strutStyle,
    Color selectionColor,
    double textScaleFactor = 1.0,
    TextSelection selection,
    @required ViewportOffset offset,
    this.onSelectionChanged,
    this.onCaretChanged,
    this.ignorePointer = false,
    bool obscureText = false,
    Locale locale,
    double cursorWidth = 1.0,
    Radius cursorRadius,
    bool paintCursorAboveText = false,
    Offset cursorOffset,
    double devicePixelRatio = 1.0,
    bool enableInteractiveSelection,
    EdgeInsets floatingCursorAddedMargin =
        const EdgeInsets.fromLTRB(4, 4, 4, 5),
    @required this.textSelectionDelegate,
  })  : assert(textAlign != null),
        assert(textDirection != null,
            'RenderEditable created without a textDirection.'),
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
        assert(textScaleFactor != null),
        assert(offset != null),
        assert(ignorePointer != null),
        assert(paintCursorAboveText != null),
        assert(obscureText != null),
        assert(textSelectionDelegate != null),
        assert(cursorWidth != null && cursorWidth >= 0.0),
        assert(devicePixelRatio != null),
        _textPainter = TextPainter(
          text: text,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaleFactor: textScaleFactor,
          locale: locale,
          strutStyle: strutStyle,
        ),
        _cursorColor = cursorColor,
        _backgroundCursorColor = backgroundCursorColor,
        _showCursor = showCursor ?? ValueNotifier<bool>(false),
        _maxLines = maxLines,
        _minLines = minLines,
        _expands = expands,
        _selectionColor = selectionColor,
        _selection = selection,
        _offset = offset,
        _cursorWidth = cursorWidth,
        _cursorRadius = cursorRadius,
        _paintCursorOnTop = paintCursorAboveText,
        _cursorOffset = cursorOffset,
        _floatingCursorAddedMargin = floatingCursorAddedMargin,
        _enableInteractiveSelection = enableInteractiveSelection,
        _devicePixelRatio = devicePixelRatio,
        _obscureText = obscureText {
    assert(_showCursor != null);
    assert(!_showCursor.value || cursorColor != null);
    this.hasFocus = hasFocus ?? false;
    _tap = TapGestureRecognizer(debugOwner: this)
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap;
    _longPress = LongPressGestureRecognizer(debugOwner: this)
      ..onLongPress = _handleLongPress;
  }

  static const String obscuringCharacter = '•';

  PlatformInputPaintCallback platformInputPaintCallback;

  SelectionChangedHandler onSelectionChanged;

  double _textLayoutLastWidth;

  CaretChangedHandler onCaretChanged;

  bool ignorePointer;

  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (devicePixelRatio == value) return;
    _devicePixelRatio = value;
    markNeedsTextLayout();
  }

  bool get obscureText => _obscureText;
  bool _obscureText;
  set obscureText(bool value) {
    if (_obscureText == value) return;
    _obscureText = value;
    markNeedsSemanticsUpdate();
  }

  TextSelectionDelegate textSelectionDelegate;

  Rect _lastCaretRect;

  ValueListenable<bool> get selectionStartInViewport =>
      _selectionStartInViewport;
  final ValueNotifier<bool> _selectionStartInViewport =
      ValueNotifier<bool>(true);

  ValueListenable<bool> get selectionEndInViewport => _selectionEndInViewport;
  final ValueNotifier<bool> _selectionEndInViewport = ValueNotifier<bool>(true);

  void _updateSelectionExtentsVisibility(Offset effectiveOffset) {
    final Rect visibleRegion = Offset.zero & size;

    final Offset startOffset = _textPainter.getOffsetForCaret(
      TextPosition(offset: _selection.start, affinity: _selection.affinity),
      Rect.zero,
    );

    const double visibleRegionSlop = 0.5;
    _selectionStartInViewport.value = visibleRegion
        .inflate(visibleRegionSlop)
        .contains(startOffset + effectiveOffset);

    final Offset endOffset = _textPainter.getOffsetForCaret(
      TextPosition(offset: _selection.end, affinity: _selection.affinity),
      Rect.zero,
    );
    _selectionEndInViewport.value = visibleRegion
        .inflate(visibleRegionSlop)
        .contains(endOffset + effectiveOffset);
  }

  static const int _kLeftArrowCode = 21;
  static const int _kRightArrowCode = 22;
  static const int _kUpArrowCode = 19;
  static const int _kDownArrowCode = 20;
  static const int _kXKeyCode = 52;
  static const int _kCKeyCode = 31;
  static const int _kVKeyCode = 50;
  static const int _kAKeyCode = 29;
  static const int _kDelKeyCode = 112;

  int _extentOffset = -1;

  int _baseOffset = -1;

  int _previousCursorLocation = -1;

  bool _resetCursor = false;

  static const int _kShiftMask = 1;
  static const int _kControlMask = 1 << 12;

  void _handlePotentialSelectionChange(
    TextSelection nextSelection,
    SelectionChangedCause cause,
  ) {
    if (nextSelection == selection) {
      return;
    }
    onSelectionChanged(nextSelection, this, cause);
  }

  void _handleKeyEvent(RawKeyEvent keyEvent) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return;
    }

    if (keyEvent is RawKeyUpEvent) return;

    final RawKeyEventDataAndroid rawAndroidEvent = keyEvent.data;
    final int pressedKeyCode = rawAndroidEvent.keyCode;
    final int pressedKeyMetaState = rawAndroidEvent.metaState;

    if (selection.isCollapsed) {
      _extentOffset = selection.extentOffset;
      _baseOffset = selection.baseOffset;
    }

    final bool shift = pressedKeyMetaState & _kShiftMask > 0;
    final bool ctrl = pressedKeyMetaState & _kControlMask > 0;

    final bool rightArrow = pressedKeyCode == _kRightArrowCode;
    final bool leftArrow = pressedKeyCode == _kLeftArrowCode;
    final bool upArrow = pressedKeyCode == _kUpArrowCode;
    final bool downArrow = pressedKeyCode == _kDownArrowCode;
    final bool arrow = leftArrow || rightArrow || upArrow || downArrow;
    final bool aKey = pressedKeyCode == _kAKeyCode;
    final bool xKey = pressedKeyCode == _kXKeyCode;
    final bool vKey = pressedKeyCode == _kVKeyCode;
    final bool cKey = pressedKeyCode == _kCKeyCode;
    final bool del = pressedKeyCode == _kDelKeyCode;

    if (arrow) {
      int newOffset = _extentOffset;

      if (ctrl)
        newOffset = _handleControl(rightArrow, leftArrow, ctrl, newOffset);
      newOffset =
          _handleHorizontalArrows(rightArrow, leftArrow, shift, newOffset);
      if (downArrow || upArrow)
        newOffset = _handleVerticalArrows(upArrow, downArrow, shift, newOffset);
      newOffset = _handleShift(rightArrow, leftArrow, shift, newOffset);

      _extentOffset = newOffset;
    } else if (ctrl && (xKey || vKey || cKey || aKey)) {
      _handleShortcuts(pressedKeyCode);
    }
    if (del) _handleDelete();
  }

  int _handleControl(
      bool rightArrow, bool leftArrow, bool ctrl, int newOffset) {
    if (leftArrow && _extentOffset > 2) {
      final TextSelection textSelection =
          _selectWordAtOffset(TextPosition(offset: _extentOffset - 2));
      newOffset = textSelection.baseOffset + 1;
    } else if (rightArrow && _extentOffset < text.text.length - 2) {
      final TextSelection textSelection =
          _selectWordAtOffset(TextPosition(offset: _extentOffset + 1));
      newOffset = textSelection.extentOffset - 1;
    }
    return newOffset;
  }

  int _handleHorizontalArrows(
      bool rightArrow, bool leftArrow, bool shift, int newOffset) {
    if (rightArrow && _extentOffset < text.toPlainText().length) {
      newOffset += 1;
      if (shift) _previousCursorLocation += 1;
    }
    if (leftArrow && _extentOffset > 0) {
      newOffset -= 1;
      if (shift) _previousCursorLocation -= 1;
    }
    return newOffset;
  }

  int _handleVerticalArrows(
      bool upArrow, bool downArrow, bool shift, int newOffset) {
    final double plh = _textPainter.preferredLineHeight;
    final double verticalOffset = upArrow ? -0.5 * plh : 1.5 * plh;

    final Offset caretOffset = _textPainter.getOffsetForCaret(
        TextPosition(offset: _extentOffset), _caretPrototype);
    final Offset caretOffsetTranslated =
        caretOffset.translate(0.0, verticalOffset);
    final TextPosition position =
        _textPainter.getPositionForOffset(caretOffsetTranslated);

    if (position.offset == _extentOffset) {
      if (downArrow)
        newOffset = text.text.length;
      else if (upArrow) newOffset = 0;
      _resetCursor = shift;
    } else if (_resetCursor && shift) {
      newOffset = _previousCursorLocation;
      _resetCursor = false;
    } else {
      newOffset = position.offset;
      _previousCursorLocation = newOffset;
    }
    return newOffset;
  }

  int _handleShift(bool rightArrow, bool leftArrow, bool shift, int newOffset) {
    if (onSelectionChanged == null) return newOffset;

    if (shift) {
      if (_baseOffset < newOffset) {
        _handlePotentialSelectionChange(
          TextSelection(
            baseOffset: _baseOffset,
            extentOffset: newOffset,
          ),
          SelectionChangedCause.keyboard,
        );
      } else {
        _handlePotentialSelectionChange(
          TextSelection(
            baseOffset: newOffset,
            extentOffset: _baseOffset,
          ),
          SelectionChangedCause.keyboard,
        );
      }
    } else {
      if (!selection.isCollapsed) {
        if (leftArrow)
          newOffset = _baseOffset < _extentOffset ? _baseOffset : _extentOffset;
        else if (rightArrow)
          newOffset = _baseOffset > _extentOffset ? _baseOffset : _extentOffset;
      }
      _handlePotentialSelectionChange(
        TextSelection.fromPosition(TextPosition(offset: newOffset)),
        SelectionChangedCause.keyboard,
      );
    }
    return newOffset;
  }

  Future<void> _handleShortcuts(int pressedKeyCode) async {
    switch (pressedKeyCode) {
      case _kCKeyCode:
        if (!selection.isCollapsed) {
          Clipboard.setData(
              ClipboardData(text: selection.textInside(text.text)));
        }
        break;
      case _kXKeyCode:
        if (!selection.isCollapsed) {
          Clipboard.setData(
              ClipboardData(text: selection.textInside(text.text)));
          textSelectionDelegate.textEditingValue = TextEditingValue(
            text: selection.textBefore(text.text) +
                selection.textAfter(text.text),
            selection: TextSelection.collapsed(offset: selection.start),
          );
        }
        break;
      case _kVKeyCode:
        final TextEditingValue value = textSelectionDelegate.textEditingValue;
        final ClipboardData data =
            await Clipboard.getData(Clipboard.kTextPlain);
        if (data != null) {
          textSelectionDelegate.textEditingValue = TextEditingValue(
            text: value.selection.textBefore(value.text) +
                data.text +
                value.selection.textAfter(value.text),
            selection: TextSelection.collapsed(
                offset: value.selection.start + data.text.length),
          );
        }
        break;
      case _kAKeyCode:
        _baseOffset = 0;
        _extentOffset = textSelectionDelegate.textEditingValue.text.length;
        _handlePotentialSelectionChange(
          TextSelection(
            baseOffset: 0,
            extentOffset: textSelectionDelegate.textEditingValue.text.length,
          ),
          SelectionChangedCause.keyboard,
        );
        break;
      default:
        assert(false);
    }
  }

  void _handleDelete() {
    if (selection.textAfter(text.text).isNotEmpty) {
      textSelectionDelegate.textEditingValue = TextEditingValue(
        text: selection.textBefore(text.text) +
            selection.textAfter(text.text).substring(1),
        selection: TextSelection.collapsed(offset: selection.start),
      );
    } else {
      textSelectionDelegate.textEditingValue = TextEditingValue(
        text: selection.textBefore(text.text),
        selection: TextSelection.collapsed(offset: selection.start),
      );
    }
  }

  @protected
  void markNeedsTextLayout() {
    _textLayoutLastWidth = null;
    markNeedsLayout();
  }

  TextSpan get text => _textPainter.text;
  final TextPainter _textPainter;
  set text(TextSpan value) {
    if (_textPainter.text == value) return;
    _textPainter.text = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  TextAlign get textAlign => _textPainter.textAlign;
  set textAlign(TextAlign value) {
    assert(value != null);
    if (_textPainter.textAlign == value) return;
    _textPainter.textAlign = value;
    markNeedsPaint();
  }

  TextDirection get textDirection => _textPainter.textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textPainter.textDirection == value) return;
    _textPainter.textDirection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  Locale get locale => _textPainter.locale;
  set locale(Locale value) {
    if (_textPainter.locale == value) return;
    _textPainter.locale = value;
    markNeedsTextLayout();
  }

  StrutStyle get strutStyle => _textPainter.strutStyle;
  set strutStyle(StrutStyle value) {
    if (_textPainter.strutStyle == value) return;
    _textPainter.strutStyle = value;
    markNeedsTextLayout();
  }

  Color get cursorColor => _cursorColor;
  Color _cursorColor;
  set cursorColor(Color value) {
    if (_cursorColor == value) return;
    _cursorColor = value;
    markNeedsPaint();
  }

  Color get backgroundCursorColor => _backgroundCursorColor;
  Color _backgroundCursorColor;
  set backgroundCursorColor(Color value) {
    if (backgroundCursorColor == value) return;
    _backgroundCursorColor = value;
    markNeedsPaint();
  }

  ValueNotifier<bool> get showCursor => _showCursor;
  ValueNotifier<bool> _showCursor;
  set showCursor(ValueNotifier<bool> value) {
    assert(value != null);
    if (_showCursor == value) return;
    if (attached) _showCursor.removeListener(markNeedsPaint);
    _showCursor = value;
    if (attached) _showCursor.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  bool get hasFocus => _hasFocus;
  bool _hasFocus = false;
  bool _listenerAttached = false;
  set hasFocus(bool value) {
    assert(value != null);
    if (_hasFocus == value) return;
    _hasFocus = value;
    if (_hasFocus) {
      assert(!_listenerAttached);
      RawKeyboard.instance.addListener(_handleKeyEvent);
      _listenerAttached = true;
    } else {
      assert(_listenerAttached);
      RawKeyboard.instance.removeListener(_handleKeyEvent);
      _listenerAttached = false;
    }
    markNeedsSemanticsUpdate();
  }

  int get maxLines => _maxLines;
  int _maxLines;

  set maxLines(int value) {
    assert(value == null || value > 0);
    if (maxLines == value) return;
    _maxLines = value;
    markNeedsTextLayout();
  }

  int get minLines => _minLines;
  int _minLines;

  set minLines(int value) {
    assert(value == null || value > 0);
    if (minLines == value) return;
    _minLines = value;
    markNeedsTextLayout();
  }

  bool get expands => _expands;
  bool _expands;
  set expands(bool value) {
    assert(value != null);
    if (expands == value) return;
    _expands = value;
    markNeedsTextLayout();
  }

  Color get selectionColor => _selectionColor;
  Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value) return;
    _selectionColor = value;
    markNeedsPaint();
  }

  double get textScaleFactor => _textPainter.textScaleFactor;
  set textScaleFactor(double value) {
    assert(value != null);
    if (_textPainter.textScaleFactor == value) return;
    _textPainter.textScaleFactor = value;
    markNeedsTextLayout();
  }

  List<ui.TextBox> _selectionRects;

  TextSelection get selection => _selection;
  TextSelection _selection;
  set selection(TextSelection value) {
    if (_selection == value) return;
    _selection = value;
    _selectionRects = null;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (_offset == value) return;
    if (attached) _offset.removeListener(markNeedsPaint);
    _offset = value;
    if (attached) _offset.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  double get cursorWidth => _cursorWidth;
  double _cursorWidth = 1.0;
  set cursorWidth(double value) {
    if (_cursorWidth == value) return;
    _cursorWidth = value;
    markNeedsLayout();
  }

  bool get paintCursorAboveText => _paintCursorOnTop;
  bool _paintCursorOnTop;
  set paintCursorAboveText(bool value) {
    if (_paintCursorOnTop == value) return;
    _paintCursorOnTop = value;
    markNeedsLayout();
  }

  Offset get cursorOffset => _cursorOffset;
  Offset _cursorOffset;
  set cursorOffset(Offset value) {
    if (_cursorOffset == value) return;
    _cursorOffset = value;
    markNeedsLayout();
  }

  Radius get cursorRadius => _cursorRadius;
  Radius _cursorRadius;
  set cursorRadius(Radius value) {
    if (_cursorRadius == value) return;
    _cursorRadius = value;
    markNeedsPaint();
  }

  EdgeInsets get floatingCursorAddedMargin => _floatingCursorAddedMargin;
  EdgeInsets _floatingCursorAddedMargin;
  set floatingCursorAddedMargin(EdgeInsets value) {
    if (_floatingCursorAddedMargin == value) return;
    _floatingCursorAddedMargin = value;
    markNeedsPaint();
  }

  bool _floatingCursorOn = false;
  Offset _floatingCursorOffset;
  TextPosition _floatingCursorTextPosition;

  bool get enableInteractiveSelection => _enableInteractiveSelection;
  bool _enableInteractiveSelection;
  set enableInteractiveSelection(bool value) {
    if (_enableInteractiveSelection == value) return;
    _enableInteractiveSelection = value;
    markNeedsTextLayout();
    markNeedsSemanticsUpdate();
  }

  bool get selectionEnabled {
    return enableInteractiveSelection ?? !obscureText;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config
      ..value = obscureText
          ? obscuringCharacter * text.toPlainText().length
          : text.toPlainText()
      ..isObscured = obscureText
      ..textDirection = textDirection
      ..isFocused = hasFocus
      ..isTextField = true;

    if (hasFocus && selectionEnabled)
      config.onSetSelection = _handleSetSelection;

    if (selectionEnabled && _selection?.isValid == true) {
      config.textSelection = _selection;
      if (_textPainter.getOffsetBefore(_selection.extentOffset) != null) {
        config
          ..onMoveCursorBackwardByWord = _handleMoveCursorBackwardByWord
          ..onMoveCursorBackwardByCharacter =
              _handleMoveCursorBackwardByCharacter;
      }
      if (_textPainter.getOffsetAfter(_selection.extentOffset) != null) {
        config
          ..onMoveCursorForwardByWord = _handleMoveCursorForwardByWord
          ..onMoveCursorForwardByCharacter =
              _handleMoveCursorForwardByCharacter;
      }
    }
  }

  void _handleSetSelection(TextSelection selection) {
    _handlePotentialSelectionChange(selection, SelectionChangedCause.keyboard);
  }

  void _handleMoveCursorForwardByCharacter(bool extentSelection) {
    final int extentOffset =
        _textPainter.getOffsetAfter(_selection.extentOffset);
    if (extentOffset == null) return;
    final int baseOffset =
        !extentSelection ? extentOffset : _selection.baseOffset;
    _handlePotentialSelectionChange(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByCharacter(bool extentSelection) {
    final int extentOffset =
        _textPainter.getOffsetBefore(_selection.extentOffset);
    if (extentOffset == null) return;
    final int baseOffset =
        !extentSelection ? extentOffset : _selection.baseOffset;
    _handlePotentialSelectionChange(
      TextSelection(baseOffset: baseOffset, extentOffset: extentOffset),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorForwardByWord(bool extentSelection) {
    final TextRange currentWord =
        _textPainter.getWordBoundary(_selection.extent);
    if (currentWord == null) return;
    final TextRange nextWord = _getNextWord(currentWord.end);
    if (nextWord == null) return;
    final int baseOffset =
        extentSelection ? _selection.baseOffset : nextWord.start;
    _handlePotentialSelectionChange(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: nextWord.start,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  void _handleMoveCursorBackwardByWord(bool extentSelection) {
    final TextRange currentWord =
        _textPainter.getWordBoundary(_selection.extent);
    if (currentWord == null) return;
    final TextRange previousWord = _getPreviousWord(currentWord.start - 1);
    if (previousWord == null) return;
    final int baseOffset =
        extentSelection ? _selection.baseOffset : previousWord.start;
    _handlePotentialSelectionChange(
      TextSelection(
        baseOffset: baseOffset,
        extentOffset: previousWord.start,
      ),
      SelectionChangedCause.keyboard,
    );
  }

  TextRange _getNextWord(int offset) {
    while (true) {
      final TextRange range =
          _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed) return null;
      if (!_onlyWhitespace(range)) return range;
      offset = range.end;
    }
  }

  TextRange _getPreviousWord(int offset) {
    while (offset >= 0) {
      final TextRange range =
          _textPainter.getWordBoundary(TextPosition(offset: offset));
      if (range == null || !range.isValid || range.isCollapsed) return null;
      if (!_onlyWhitespace(range)) return range;
      offset = range.start - 1;
    }
    return null;
  }

  bool _onlyWhitespace(TextRange range) {
    for (int i = range.start; i < range.end; i++) {
      final int codeUnit = text.codeUnitAt(i);
      switch (codeUnit) {
        case 0x9:
        case 0xA:
        case 0xB:
        case 0xC:
        case 0xD:
        case 0x1C:
        case 0x1D:
        case 0x1E:
        case 0x1F:
        case 0x20:
        case 0xA0:
        case 0x1680:
        case 0x2000:
        case 0x2001:
        case 0x2002:
        case 0x2003:
        case 0x2004:
        case 0x2005:
        case 0x2006:
        case 0x2007:
        case 0x2008:
        case 0x2009:
        case 0x200A:
        case 0x202F:
        case 0x205F:
        case 0x3000:
          break;
        default:
          return false;
      }
    }
    return true;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsPaint);
    _showCursor.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsPaint);
    _showCursor.removeListener(markNeedsPaint);
    if (_listenerAttached) RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.detach();
  }

  bool get _isMultiline => maxLines != 1;

  Axis get _viewportAxis => _isMultiline ? Axis.vertical : Axis.horizontal;

  Offset get _paintOffset {
    switch (_viewportAxis) {
      case Axis.horizontal:
        return Offset(-offset.pixels, 0.0);
      case Axis.vertical:
        return Offset(0.0, -offset.pixels);
    }
    return null;
  }

  double get _viewportExtent {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return size.width;
      case Axis.vertical:
        return size.height;
    }
    return null;
  }

  double _getMaxScrollExtent(Size contentSize) {
    assert(hasSize);
    switch (_viewportAxis) {
      case Axis.horizontal:
        return math.max(0.0, contentSize.width - size.width);
      case Axis.vertical:
        return math.max(0.0, contentSize.height - size.height);
    }
    return null;
  }

  double _maxScrollExtent = 0;

  bool get _hasVisualOverflow =>
      _maxScrollExtent > 0 || _paintOffset != Offset.zero;

  List<TextSelectionPoint> getEndpointsForSelection(TextSelection selection) {
    assert(constraints != null);
    _layoutText(constraints.maxWidth);

    final Offset paintOffset = _paintOffset;

    if (selection.isCollapsed) {
      final Offset caretOffset =
          _textPainter.getOffsetForCaret(selection.extent, _caretPrototype);
      final Offset start =
          Offset(0.0, preferredLineHeight) + caretOffset + paintOffset;
      return <TextSelectionPoint>[TextSelectionPoint(start, null)];
    } else {
      final List<ui.TextBox> boxes =
          _textPainter.getBoxesForSelection(selection);
      final Offset start =
          Offset(boxes.first.start, boxes.first.bottom) + paintOffset;
      final Offset end =
          Offset(boxes.last.end, boxes.last.bottom) + paintOffset;
      return <TextSelectionPoint>[
        TextSelectionPoint(start, boxes.first.direction),
        TextSelectionPoint(end, boxes.last.direction),
      ];
    }
  }

  TextPosition getPositionForPoint(Offset globalPosition) {
    _layoutText(constraints.maxWidth);
    globalPosition += -_paintOffset;
    return _textPainter.getPositionForOffset(globalToLocal(globalPosition));
  }

  Rect getLocalRectForCaret(TextPosition caretPosition) {
    _layoutText(constraints.maxWidth);
    final Offset caretOffset =
        _textPainter.getOffsetForCaret(caretPosition, _caretPrototype);

    Rect rect = Rect.fromLTWH(0.0, 0.0, cursorWidth, preferredLineHeight)
        .shift(caretOffset + _paintOffset);

    if (_cursorOffset != null) rect = rect.shift(_cursorOffset);

    return rect.shift(_getPixelPerfectCursorOffset(rect));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutText(double.infinity);
    return _textPainter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutText(double.infinity);
    return _textPainter.maxIntrinsicWidth + cursorWidth;
  }

  double get preferredLineHeight => _textPainter.preferredLineHeight;

  double _preferredHeight(double width) {
    final bool lockedMax = maxLines != null && minLines == null;
    final bool lockedBoth = minLines != null && minLines == maxLines;
    final bool singleLine = maxLines == 1;
    if (singleLine || lockedMax || lockedBoth) {
      return preferredLineHeight * maxLines;
    }

    final bool minLimited = minLines != null && minLines > 1;
    final bool maxLimited = maxLines != null;
    if (minLimited || maxLimited) {
      _layoutText(width);
      if (minLimited && _textPainter.height < preferredLineHeight * minLines) {
        return preferredLineHeight * minLines;
      }
      if (maxLimited && _textPainter.height > preferredLineHeight * maxLines) {
        return preferredLineHeight * maxLines;
      }
    }

    if (width == double.infinity) {
      final String text = _textPainter.text.toPlainText();
      int lines = 1;
      for (int index = 0; index < text.length; index += 1) {
        if (text.codeUnitAt(index) == 0x0A) lines += 1;
      }
      return preferredLineHeight * lines;
    }
    _layoutText(width);
    return math.max(preferredLineHeight, _textPainter.height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _preferredHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _preferredHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    _layoutText(constraints.maxWidth);
    return _textPainter.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  TapGestureRecognizer _tap;
  LongPressGestureRecognizer _longPress;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (ignorePointer) return;
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && onSelectionChanged != null) {
      _tap.addPointer(event);
      _longPress.addPointer(event);
    }
  }

  Offset _lastTapDownPosition;

  void handleTapDown(TapDownDetails details) {
    _lastTapDownPosition = details.globalPosition;
  }

  void _handleTapDown(TapDownDetails details) {
    assert(!ignorePointer);
    handleTapDown(details);
  }

  void handleTap() {
    selectPosition(cause: SelectionChangedCause.tap);
  }

  void _handleTap() {
    assert(!ignorePointer);
    handleTap();
  }

  void handleDoubleTap() {
    selectWord(cause: SelectionChangedCause.doubleTap);
  }

  void handleLongPress() {
    selectWord(cause: SelectionChangedCause.longPress);
  }

  void _handleLongPress() {
    assert(!ignorePointer);
    handleLongPress();
  }

  void selectPosition({@required SelectionChangedCause cause}) {
    selectPositionAt(from: _lastTapDownPosition, cause: cause);
  }

  void selectPositionAt(
      {@required Offset from,
      Offset to,
      @required SelectionChangedCause cause}) {
    assert(cause != null);
    assert(from != null);
    _layoutText(constraints.maxWidth);
    if (onSelectionChanged != null) {
      final TextPosition fromPosition =
          _textPainter.getPositionForOffset(globalToLocal(from - _paintOffset));
      final TextPosition toPosition = to == null
          ? null
          : _textPainter.getPositionForOffset(globalToLocal(to - _paintOffset));

      int baseOffset = fromPosition.offset;
      int extentOffset = fromPosition.offset;
      if (toPosition != null) {
        baseOffset = math.min(fromPosition.offset, toPosition.offset);
        extentOffset = math.max(fromPosition.offset, toPosition.offset);
      }

      final TextSelection newSelection = TextSelection(
        baseOffset: baseOffset,
        extentOffset: extentOffset,
        affinity: fromPosition.affinity,
      );

      if (newSelection != _selection) {
        _handlePotentialSelectionChange(newSelection, cause);
      }
    }
  }

  void selectWord({@required SelectionChangedCause cause}) {
    selectWordsInRange(from: _lastTapDownPosition, cause: cause);
  }

  void selectWordsInRange(
      {@required Offset from,
      Offset to,
      @required SelectionChangedCause cause}) {
    assert(cause != null);
    assert(from != null);
    _layoutText(constraints.maxWidth);
    if (onSelectionChanged != null) {
      final TextPosition firstPosition =
          _textPainter.getPositionForOffset(globalToLocal(from - _paintOffset));
      final TextSelection firstWord = _selectWordAtOffset(firstPosition);
      final TextSelection lastWord = to == null
          ? firstWord
          : _selectWordAtOffset(_textPainter
              .getPositionForOffset(globalToLocal(to - _paintOffset)));

      _handlePotentialSelectionChange(
        TextSelection(
          baseOffset: firstWord.base.offset,
          extentOffset: lastWord.extent.offset,
          affinity: firstWord.affinity,
        ),
        cause,
      );
    }
  }

  void selectWordEdge({@required SelectionChangedCause cause}) {
    assert(cause != null);
    _layoutText(constraints.maxWidth);
    assert(_lastTapDownPosition != null);
    if (onSelectionChanged != null) {
      final TextPosition position = _textPainter.getPositionForOffset(
          globalToLocal(_lastTapDownPosition - _paintOffset));
      final TextRange word = _textPainter.getWordBoundary(position);
      if (position.offset - word.start <= 1) {
        _handlePotentialSelectionChange(
          TextSelection.collapsed(
              offset: word.start, affinity: TextAffinity.downstream),
          cause,
        );
      } else {
        _handlePotentialSelectionChange(
          TextSelection.collapsed(
              offset: word.end, affinity: TextAffinity.upstream),
          cause,
        );
      }
    }
  }

  TextSelection _selectWordAtOffset(TextPosition position) {
    assert(_textLayoutLastWidth == constraints.maxWidth,
        'Last width ($_textLayoutLastWidth) not the same as max width constraint (${constraints.maxWidth}).');
    final TextRange word = _textPainter.getWordBoundary(position);

    if (position.offset >= word.end)
      return TextSelection.fromPosition(position);
    return TextSelection(baseOffset: word.start, extentOffset: word.end);
  }

  Rect _caretPrototype;

  void _layoutText(double constraintWidth) {
    assert(constraintWidth != null);
    if (_textLayoutLastWidth == constraintWidth) return;
    final double caretMargin = _kCaretGap + cursorWidth;
    final double availableWidth = math.max(0.0, constraintWidth - caretMargin);
    final double maxWidth = _isMultiline ? availableWidth : double.infinity;
    _textPainter.layout(minWidth: availableWidth, maxWidth: maxWidth);
    _textLayoutLastWidth = constraintWidth;
  }

  Rect get _getCaretPrototype {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return Rect.fromLTWH(0.0, 0.0, cursorWidth, preferredLineHeight + 2);
      default:
        return Rect.fromLTWH(0.0, _kCaretHeightOffset, cursorWidth,
            preferredLineHeight - 2.0 * _kCaretHeightOffset);
    }
  }

  @override
  void performLayout() {
    _layoutText(constraints.maxWidth);
    _caretPrototype = _getCaretPrototype;
    _selectionRects = null;

    final Size textPainterSize = _textPainter.size;
    size = Size(constraints.maxWidth,
        constraints.constrainHeight(_preferredHeight(constraints.maxWidth)));
    final Size contentSize = Size(
        textPainterSize.width + _kCaretGap + cursorWidth,
        textPainterSize.height);
    _maxScrollExtent = _getMaxScrollExtent(contentSize);
    offset.applyViewportDimension(_viewportExtent);
    offset.applyContentDimensions(0.0, _maxScrollExtent);
  }

  Offset _getPixelPerfectCursorOffset(Rect caretRect) {
    final Offset caretPosition = localToGlobal(caretRect.topLeft);
    final double pixelMultiple = 1.0 / _devicePixelRatio;
    final int quotientX = (caretPosition.dx / pixelMultiple).round();
    final int quotientY = (caretPosition.dy / pixelMultiple).round();
    final double pixelPerfectOffsetX =
        quotientX * pixelMultiple - caretPosition.dx;
    final double pixelPerfectOffsetY =
        quotientY * pixelMultiple - caretPosition.dy;
    return Offset(pixelPerfectOffsetX, pixelPerfectOffsetY);
  }

  void _paintCaret(
      Canvas canvas, Offset effectiveOffset, TextPosition textPosition) {
    assert(_textLayoutLastWidth == constraints.maxWidth,
        'Last width ($_textLayoutLastWidth) not the same as max width constraint (${constraints.maxWidth}).');

    final Paint paint = Paint()
      ..color = _floatingCursorOn ? backgroundCursorColor : _cursorColor;
    final Offset caretOffset =
        _textPainter.getOffsetForCaret(textPosition, _caretPrototype) +
            effectiveOffset;
    Rect caretRect = _caretPrototype.shift(caretOffset);
    if (_cursorOffset != null) caretRect = caretRect.shift(_cursorOffset);

    if (_textPainter.getFullHeightForCaret(textPosition, _caretPrototype) !=
        null) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          {
            final double heightDiff = _textPainter.getFullHeightForCaret(
                    textPosition, _caretPrototype) -
                caretRect.height;

            caretRect = Rect.fromLTWH(
              caretRect.left,
              caretRect.top + heightDiff / 2,
              caretRect.width,
              caretRect.height,
            );
            break;
          }
        default:
          {
            caretRect = Rect.fromLTWH(
              caretRect.left,
              caretRect.top - _kCaretHeightOffset,
              caretRect.width,
              _textPainter.getFullHeightForCaret(textPosition, _caretPrototype),
            );
            break;
          }
      }
    }

    caretRect = caretRect.shift(_getPixelPerfectCursorOffset(caretRect));

    if (cursorRadius == null) {
      canvas.drawRect(caretRect, paint);
    } else {
      final RRect caretRRect = RRect.fromRectAndRadius(caretRect, cursorRadius);
      canvas.drawRRect(caretRRect, paint);
    }

    if (caretRect != _lastCaretRect) {
      _lastCaretRect = caretRect;
      if (onCaretChanged != null) onCaretChanged(caretRect);
    }
  }

  void setFloatingCursor(FloatingCursorDragState state, Offset boundedOffset,
      TextPosition lastTextPosition,
      {double resetLerpValue}) {
    assert(state != null);
    assert(boundedOffset != null);
    assert(lastTextPosition != null);
    if (state == FloatingCursorDragState.Start) {
      _relativeOrigin = const Offset(0, 0);
      _previousOffset = null;
      _resetOriginOnBottom = false;
      _resetOriginOnTop = false;
      _resetOriginOnRight = false;
      _resetOriginOnBottom = false;
    }
    _floatingCursorOn = state != FloatingCursorDragState.End;
    _resetFloatingCursorAnimationValue = resetLerpValue;
    if (_floatingCursorOn) {
      _floatingCursorOffset = boundedOffset;
      _floatingCursorTextPosition = lastTextPosition;
    }
    markNeedsPaint();
  }

  void _paintFloatingCaret(Canvas canvas, Offset effectiveOffset) {
    assert(_textLayoutLastWidth == constraints.maxWidth,
        'Last width ($_textLayoutLastWidth) not the same as max width constraint (${constraints.maxWidth}).');
    assert(_floatingCursorOn);

    final Paint paint = Paint()..color = _cursorColor.withOpacity(0.75);

    double sizeAdjustmentX = _kFloatingCaretSizeIncrease.dx;
    double sizeAdjustmentY = _kFloatingCaretSizeIncrease.dy;

    if (_resetFloatingCursorAnimationValue != null) {
      sizeAdjustmentX =
          ui.lerpDouble(sizeAdjustmentX, 0, _resetFloatingCursorAnimationValue);
      sizeAdjustmentY =
          ui.lerpDouble(sizeAdjustmentY, 0, _resetFloatingCursorAnimationValue);
    }

    final Rect floatingCaretPrototype = Rect.fromLTRB(
      _caretPrototype.left - sizeAdjustmentX,
      _caretPrototype.top - sizeAdjustmentY,
      _caretPrototype.right + sizeAdjustmentX,
      _caretPrototype.bottom + sizeAdjustmentY,
    );

    final Rect caretRect = floatingCaretPrototype.shift(effectiveOffset);
    const Radius floatingCursorRadius = Radius.circular(_kFloatingCaretRadius);
    final RRect caretRRect =
        RRect.fromRectAndRadius(caretRect, floatingCursorRadius);
    canvas.drawRRect(caretRRect, paint);
  }

  Offset _relativeOrigin = const Offset(0, 0);
  Offset _previousOffset;
  bool _resetOriginOnLeft = false;
  bool _resetOriginOnRight = false;
  bool _resetOriginOnTop = false;
  bool _resetOriginOnBottom = false;
  double _resetFloatingCursorAnimationValue;

  Offset calculateBoundedFloatingCursorOffset(Offset rawCursorOffset) {
    Offset deltaPosition = const Offset(0, 0);
    final double topBound = -floatingCursorAddedMargin.top;
    final double bottomBound = _textPainter.height -
        preferredLineHeight +
        floatingCursorAddedMargin.bottom;
    final double leftBound = -floatingCursorAddedMargin.left;
    final double rightBound =
        _textPainter.width + floatingCursorAddedMargin.right;

    if (_previousOffset != null)
      deltaPosition = rawCursorOffset - _previousOffset;

    if (_resetOriginOnLeft && deltaPosition.dx > 0) {
      _relativeOrigin =
          Offset(rawCursorOffset.dx - leftBound, _relativeOrigin.dy);
      _resetOriginOnLeft = false;
    } else if (_resetOriginOnRight && deltaPosition.dx < 0) {
      _relativeOrigin =
          Offset(rawCursorOffset.dx - rightBound, _relativeOrigin.dy);
      _resetOriginOnRight = false;
    }
    if (_resetOriginOnTop && deltaPosition.dy > 0) {
      _relativeOrigin =
          Offset(_relativeOrigin.dx, rawCursorOffset.dy - topBound);
      _resetOriginOnTop = false;
    } else if (_resetOriginOnBottom && deltaPosition.dy < 0) {
      _relativeOrigin =
          Offset(_relativeOrigin.dx, rawCursorOffset.dy - bottomBound);
      _resetOriginOnBottom = false;
    }

    final double currentX = rawCursorOffset.dx - _relativeOrigin.dx;
    final double currentY = rawCursorOffset.dy - _relativeOrigin.dy;
    final double adjustedX =
        math.min(math.max(currentX, leftBound), rightBound);
    final double adjustedY =
        math.min(math.max(currentY, topBound), bottomBound);
    final Offset adjustedOffset = Offset(adjustedX, adjustedY);

    if (currentX < leftBound && deltaPosition.dx < 0)
      _resetOriginOnLeft = true;
    else if (currentX > rightBound && deltaPosition.dx > 0)
      _resetOriginOnRight = true;
    if (currentY < topBound && deltaPosition.dy < 0)
      _resetOriginOnTop = true;
    else if (currentY > bottomBound && deltaPosition.dy > 0)
      _resetOriginOnBottom = true;

    _previousOffset = rawCursorOffset;

    return adjustedOffset;
  }

  void _paintSelection(Canvas canvas, Offset effectiveOffset) {
    assert(_textLayoutLastWidth == constraints.maxWidth,
        'Last width ($_textLayoutLastWidth) not the same as max width constraint (${constraints.maxWidth}).');
    assert(_selectionRects != null);
    final Paint paint = Paint()..color = _selectionColor;
    for (ui.TextBox box in _selectionRects)
      canvas.drawRect(box.toRect().shift(effectiveOffset), paint);
  }

  void _paintContents(PaintingContext context, Offset offset) {
    assert(_textLayoutLastWidth == constraints.maxWidth,
        'Last width ($_textLayoutLastWidth) not the same as max width constraint (${constraints.maxWidth}).');
    final Offset effectiveOffset = offset + _paintOffset;

    bool showSelection = false;
    bool showCaret = false;

    if (_selection != null && !_floatingCursorOn) {
      if (_selection.isCollapsed && _showCursor.value && cursorColor != null)
        showCaret = true;
      else if (!_selection.isCollapsed && _selectionColor != null)
        showSelection = true;
      _updateSelectionExtentsVisibility(effectiveOffset);
    }

    if (showSelection) {
      _selectionRects ??= _textPainter.getBoxesForSelection(_selection);
      _paintSelection(context.canvas, effectiveOffset);
    }

    if (paintCursorAboveText)
      _textPainter.paint(context.canvas, effectiveOffset);

    if (showCaret)
      _paintCaret(context.canvas, effectiveOffset, _selection.extent);

    if (!paintCursorAboveText)
      _textPainter.paint(context.canvas, effectiveOffset);

    if (_floatingCursorOn) {
      if (_resetFloatingCursorAnimationValue == null)
        _paintCaret(
            context.canvas, effectiveOffset, _floatingCursorTextPosition);
      _paintFloatingCaret(context.canvas, _floatingCursorOffset);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (platformInputPaintCallback != null) {
      platformInputPaintCallback();
    }
    _layoutText(constraints.maxWidth);
    if (_hasVisualOverflow)
      context.pushClipRect(
          needsCompositing, offset, Offset.zero & size, _paintContents);
    else
      _paintContents(context, offset);
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) =>
      _hasVisualOverflow ? Offset.zero & size : null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Color>('cursorColor', cursorColor));
    properties.add(
        DiagnosticsProperty<ValueNotifier<bool>>('showCursor', showCursor));
    properties.add(IntProperty('maxLines', maxLines));
    properties.add(IntProperty('minLines', minLines));
    properties.add(
        DiagnosticsProperty<bool>('expands', expands, defaultValue: false));
    properties
        .add(DiagnosticsProperty<Color>('selectionColor', selectionColor));
    properties.add(DoubleProperty('textScaleFactor', textScaleFactor));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(DiagnosticsProperty<TextSelection>('selection', selection));
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      text.toDiagnosticsNode(
        name: 'text',
        style: DiagnosticsTreeStyle.transition,
      ),
    ];
  }
}

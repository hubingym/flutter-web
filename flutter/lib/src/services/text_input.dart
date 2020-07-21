import 'dart:async';
import 'package:flutter_web/io.dart' show Platform;
import 'package:flutter_web/ui.dart' show TextAffinity, hashValues, Offset;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart';
import 'package:vector_math/vector_math_64.dart';

import 'message_codec.dart';
import 'system_channels.dart';
import 'system_chrome.dart';
import 'text_editing.dart';

export 'package:flutter_web/ui.dart' show Rect, TextAffinity;

class TextInputType {
  const TextInputType._(this.index)
      : signed = null,
        decimal = null;

  const TextInputType.numberWithOptions({
    this.signed = false,
    this.decimal = false,
  }) : index = 2;

  final int index;

  final bool signed;

  final bool decimal;

  static const TextInputType text = TextInputType._(0);

  static const TextInputType multiline = TextInputType._(1);

  static const TextInputType number = TextInputType.numberWithOptions();

  static const TextInputType phone = TextInputType._(3);

  static const TextInputType datetime = TextInputType._(4);

  static const TextInputType emailAddress = TextInputType._(5);

  static const TextInputType url = TextInputType._(6);

  static const List<TextInputType> values = <TextInputType>[
    text,
    multiline,
    number,
    phone,
    datetime,
    emailAddress,
    url,
  ];

  static const List<String> _names = <String>[
    'text',
    'multiline',
    'number',
    'phone',
    'datetime',
    'emailAddress',
    'url',
  ];

  String get _name => 'TextInputType.${_names[index]}';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': _name,
      'signed': signed,
      'decimal': decimal,
    };
  }

  @override
  String toString() {
    return '$runtimeType('
        'name: $_name, '
        'signed: $signed, '
        'decimal: $decimal)';
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! TextInputType) return false;
    final TextInputType typedOther = other;
    return typedOther.index == index &&
        typedOther.signed == signed &&
        typedOther.decimal == decimal;
  }

  @override
  int get hashCode => hashValues(index, signed, decimal);
}

enum TextInputAction {
  none,

  unspecified,

  done,

  go,

  search,

  send,

  next,

  previous,

  continueAction,

  join,

  route,

  emergencyCall,

  newline,
}

enum TextCapitalization {
  words,

  sentences,

  characters,

  none,
}

@immutable
class TextInputConfiguration {
  const TextInputConfiguration({
    this.inputType = TextInputType.text,
    this.obscureText = false,
    this.autocorrect = true,
    this.actionLabel,
    this.inputAction = TextInputAction.done,
    this.keyboardAppearance = Brightness.light,
    this.textCapitalization = TextCapitalization.none,
  })  : assert(inputType != null),
        assert(obscureText != null),
        assert(autocorrect != null),
        assert(keyboardAppearance != null),
        assert(inputAction != null),
        assert(textCapitalization != null);

  final TextInputType inputType;

  final bool obscureText;

  final bool autocorrect;

  final String actionLabel;

  final TextInputAction inputAction;

  final TextCapitalization textCapitalization;

  final Brightness keyboardAppearance;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'inputType': inputType.toJson(),
      'obscureText': obscureText,
      'autocorrect': autocorrect,
      'actionLabel': actionLabel,
      'inputAction': inputAction.toString(),
      'textCapitalization': textCapitalization.toString(),
      'keyboardAppearance': keyboardAppearance.toString(),
    };
  }
}

TextAffinity _toTextAffinity(String affinity) {
  switch (affinity) {
    case 'TextAffinity.downstream':
      return TextAffinity.downstream;
    case 'TextAffinity.upstream':
      return TextAffinity.upstream;
  }
  return null;
}

enum FloatingCursorDragState {
  Start,

  Update,

  End,
}

class RawFloatingCursorPoint {
  RawFloatingCursorPoint({
    this.offset,
    @required this.state,
  })  : assert(state != null),
        assert(state == FloatingCursorDragState.Update ? offset != null : true);

  final Offset offset;

  final FloatingCursorDragState state;
}

@immutable
class TextEditingValue {
  const TextEditingValue(
      {this.text = '',
      this.selection = const TextSelection.collapsed(offset: -1),
      this.composing = TextRange.empty})
      : assert(text != null),
        assert(selection != null),
        assert(composing != null);

  factory TextEditingValue.fromJSON(Map<String, dynamic> encoded) {
    return TextEditingValue(
      text: encoded['text'],
      selection: TextSelection(
        baseOffset: encoded['selectionBase'] ?? -1,
        extentOffset: encoded['selectionExtent'] ?? -1,
        affinity: _toTextAffinity(encoded['selectionAffinity']) ??
            TextAffinity.downstream,
        isDirectional: encoded['selectionIsDirectional'] ?? false,
      ),
      composing: TextRange(
        start: encoded['composingBase'] ?? -1,
        end: encoded['composingExtent'] ?? -1,
      ),
    );
  }

  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'text': text,
      'selectionBase': selection.baseOffset,
      'selectionExtent': selection.extentOffset,
      'selectionAffinity': selection.affinity.toString(),
      'selectionIsDirectional': selection.isDirectional,
      'composingBase': composing.start,
      'composingExtent': composing.end,
    };
  }

  final String text;

  final TextSelection selection;

  final TextRange composing;

  static const TextEditingValue empty = TextEditingValue();

  TextEditingValue copyWith(
      {String text, TextSelection selection, TextRange composing}) {
    return TextEditingValue(
        text: text ?? this.text,
        selection: selection ?? this.selection,
        composing: composing ?? this.composing);
  }

  @override
  String toString() =>
      '$runtimeType(text: \u2524$text\u251C, selection: $selection, composing: $composing)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! TextEditingValue) return false;
    final TextEditingValue typedOther = other;
    return typedOther.text == text &&
        typedOther.selection == selection &&
        typedOther.composing == composing;
  }

  @override
  int get hashCode =>
      hashValues(text.hashCode, selection.hashCode, composing.hashCode);
}

abstract class TextSelectionDelegate {
  TextEditingValue get textEditingValue;

  set textEditingValue(TextEditingValue value);

  void hideToolbar();

  void bringIntoView(TextPosition position);

  bool get cutEnabled => true;

  bool get copyEnabled => true;

  bool get pasteEnabled => true;

  bool get selectAllEnabled => true;
}

abstract class TextInputClient {
  const TextInputClient();

  void updateEditingValue(TextEditingValue value);

  void performAction(TextInputAction action);

  void updateFloatingCursor(RawFloatingCursorPoint point);
}

class TextInputConnection {
  TextInputConnection._(this._client)
      : assert(_client != null),
        _id = _nextId++;

  static int _nextId = 1;
  final int _id;

  final TextInputClient _client;

  bool get attached => _clientHandler._currentConnection == this;

  void show() {
    assert(attached);
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  void setEditingState(TextEditingValue value) {
    assert(attached);
    SystemChannels.textInput.invokeMethod(
      'TextInput.setEditingState',
      value.toJSON(),
    );
  }

  void setEditableSizeAndTransform(Size renderBoxSize, Matrix4 transform) {
    final List<double> transformList = List<double>(16);
    transform.copyIntoArray(transformList);

    SystemChannels.textInput.invokeMethod(
      'TextInput.setEditableSizeAndTransform',
      <String, dynamic>{
        'width': renderBoxSize.width,
        'height': renderBoxSize.height,
        'transform': transformList,
      },
    );
  }

  void setStyle(
      TextStyle textStyle, TextDirection textDirection, TextAlign textAlign) {
    assert(attached);

    SystemChannels.textInput.invokeMethod(
      'TextInput.setStyle',
      <String, dynamic>{
        'fontFamily': textStyle.fontFamily,
        'fontSize': textStyle.fontSize,
        'fontWeightIndex': textStyle.fontWeight?.index,
        'textAlignIndex': textAlign.index,
        'textDirectionIndex': textDirection.index,
      },
    );
  }

  void close() {
    if (attached) {
      SystemChannels.textInput.invokeMethod('TextInput.clearClient');
      _clientHandler
        .._currentConnection = null
        .._scheduleHide();
    }
    assert(!attached);
  }
}

TextInputAction _toTextInputAction(String action) {
  switch (action) {
    case 'TextInputAction.none':
      return TextInputAction.none;
    case 'TextInputAction.unspecified':
      return TextInputAction.unspecified;
    case 'TextInputAction.go':
      return TextInputAction.go;
    case 'TextInputAction.search':
      return TextInputAction.search;
    case 'TextInputAction.send':
      return TextInputAction.send;
    case 'TextInputAction.next':
      return TextInputAction.next;
    case 'TextInputAction.previuos':
      return TextInputAction.previous;
    case 'TextInputAction.continue_action':
      return TextInputAction.continueAction;
    case 'TextInputAction.join':
      return TextInputAction.join;
    case 'TextInputAction.route':
      return TextInputAction.route;
    case 'TextInputAction.emergencyCall':
      return TextInputAction.emergencyCall;
    case 'TextInputAction.done':
      return TextInputAction.done;
    case 'TextInputAction.newline':
      return TextInputAction.newline;
  }
  throw FlutterError('Unknown text input action: $action');
}

FloatingCursorDragState _toTextCursorAction(String state) {
  switch (state) {
    case 'FloatingCursorDragState.start':
      return FloatingCursorDragState.Start;
    case 'FloatingCursorDragState.update':
      return FloatingCursorDragState.Update;
    case 'FloatingCursorDragState.end':
      return FloatingCursorDragState.End;
  }
  throw FlutterError('Unknown text cursor action: $state');
}

RawFloatingCursorPoint _toTextPoint(
    FloatingCursorDragState state, Map<String, dynamic> encoded) {
  assert(state != null, 'You must provide a state to set a new editing point.');
  assert(encoded['X'] != null,
      'You must provide a value for the horizontal location of the floating cursor.');
  assert(encoded['Y'] != null,
      'You must provide a value for the vertical location of the floating cursor.');
  final Offset offset = state == FloatingCursorDragState.Update
      ? Offset(encoded['X'], encoded['Y'])
      : const Offset(0, 0);
  return RawFloatingCursorPoint(offset: offset, state: state);
}

class _TextInputClientHandler {
  _TextInputClientHandler() {
    SystemChannels.textInput.setMethodCallHandler(_handleTextInputInvocation);
  }

  TextInputConnection _currentConnection;

  Future<dynamic> _handleTextInputInvocation(MethodCall methodCall) async {
    if (_currentConnection == null) return;
    final String method = methodCall.method;
    final List<dynamic> args = methodCall.arguments;
    final int client = args[0];

    if (client != _currentConnection._id) return;
    switch (method) {
      case 'TextInputClient.updateEditingState':
        _currentConnection._client
            .updateEditingValue(TextEditingValue.fromJSON(args[1]));
        break;
      case 'TextInputClient.performAction':
        _currentConnection._client.performAction(_toTextInputAction(args[1]));
        break;
      case 'TextInputClient.updateFloatingCursor':
        _currentConnection._client.updateFloatingCursor(
            _toTextPoint(_toTextCursorAction(args[1]), args[2]));
        break;
      default:
        throw MissingPluginException();
    }
  }

  bool _hidePending = false;

  void _scheduleHide() {
    if (_hidePending) return;
    _hidePending = true;

    scheduleMicrotask(() {
      _hidePending = false;
      if (_currentConnection == null)
        SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }
}

final _TextInputClientHandler _clientHandler = _TextInputClientHandler();

class TextInput {
  TextInput._();

  static const List<TextInputAction> _androidSupportedInputActions =
      <TextInputAction>[
    TextInputAction.none,
    TextInputAction.unspecified,
    TextInputAction.done,
    TextInputAction.send,
    TextInputAction.go,
    TextInputAction.search,
    TextInputAction.next,
    TextInputAction.previous,
    TextInputAction.newline,
  ];

  static const List<TextInputAction> _iOSSupportedInputActions =
      <TextInputAction>[
    TextInputAction.unspecified,
    TextInputAction.done,
    TextInputAction.send,
    TextInputAction.go,
    TextInputAction.search,
    TextInputAction.next,
    TextInputAction.newline,
    TextInputAction.continueAction,
    TextInputAction.join,
    TextInputAction.route,
    TextInputAction.emergencyCall,
  ];

  static TextInputConnection attach(
      TextInputClient client, TextInputConfiguration configuration) {
    assert(client != null);
    assert(configuration != null);
    assert(_debugEnsureInputActionWorksOnPlatform(configuration.inputAction));
    final TextInputConnection connection = TextInputConnection._(client);
    _clientHandler._currentConnection = connection;
    SystemChannels.textInput.invokeMethod(
      'TextInput.setClient',
      <dynamic>[connection._id, configuration.toJson()],
    );
    return connection;
  }

  static bool _debugEnsureInputActionWorksOnPlatform(
      TextInputAction inputAction) {
    assert(() {
      if (Platform.isIOS) {
        assert(
          _iOSSupportedInputActions.contains(inputAction),
          'The requested TextInputAction "$inputAction" is not supported on iOS.',
        );
      } else if (Platform.isAndroid) {
        assert(
          _androidSupportedInputActions.contains(inputAction),
          'The requested TextInputAction "$inputAction" is not supported on Android.',
        );
      }
      return true;
    }());
    return true;
  }
}

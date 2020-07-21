import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/ui.dart' as ui show isWeb;

import 'keyboard_key.dart';
import 'raw_keyboard_android.dart';
import 'raw_keyboard_fuchsia.dart';
import 'raw_keyboard_macos.dart';
import 'raw_keyboard_linux.dart';
import 'system_channels.dart';

enum KeyboardSide {
  any,

  left,

  right,

  all,
}

enum ModifierKey {
  controlModifier,

  shiftModifier,

  altModifier,

  metaModifier,

  capsLockModifier,

  numLockModifier,

  scrollLockModifier,

  functionModifier,

  symbolModifier,
}

@immutable
abstract class RawKeyEventData {
  const RawKeyEventData();

  bool isModifierPressed(ModifierKey key,
      {KeyboardSide side = KeyboardSide.any});

  KeyboardSide getModifierSide(ModifierKey key);

  bool get isControlPressed =>
      isModifierPressed(ModifierKey.controlModifier, side: KeyboardSide.any);

  bool get isShiftPressed =>
      isModifierPressed(ModifierKey.shiftModifier, side: KeyboardSide.any);

  bool get isAltPressed =>
      isModifierPressed(ModifierKey.altModifier, side: KeyboardSide.any);

  bool get isMetaPressed =>
      isModifierPressed(ModifierKey.metaModifier, side: KeyboardSide.any);

  Map<ModifierKey, KeyboardSide> get modifiersPressed {
    final Map<ModifierKey, KeyboardSide> result = <ModifierKey, KeyboardSide>{};
    for (ModifierKey key in ModifierKey.values) {
      if (isModifierPressed(key)) {
        result[key] = getModifierSide(key);
      }
    }
    return result;
  }

  PhysicalKeyboardKey get physicalKey;

  LogicalKeyboardKey get logicalKey;

  String get keyLabel;
}

@immutable
abstract class RawKeyEvent {
  const RawKeyEvent({
    @required this.data,
    this.character,
  });

  factory RawKeyEvent.fromMessage(Map<String, dynamic> message) {
    RawKeyEventData data;

    final String keymap = message['keymap'];
    switch (keymap) {
      case 'fuchsia':
        data = RawKeyEventDataFuchsia(
          hidUsage: message['hidUsage'] ?? 0,
          codePoint: message['codePoint'] ?? 0,
          modifiers: message['modifiers'] ?? 0,
        );
        break;
      case 'android':
        data = RawKeyEventDataAndroid(
          flags: message['flags'] ?? 0,
          codePoint: message['codePoint'] ?? 0,
          keyCode: message['keyCode'] ?? 0,
          plainCodePoint: message['plainCodePoint'] ?? 0,
          scanCode: message['scanCode'] ?? 0,
          metaState: message['metaState'] ?? 0,
        );
        break;
      default:
        throw FlutterError('Unknown keymap for key events: $keymap');
    }

    if (!ui.isWeb) {
      switch (keymap) {
        case 'macos':
          data = RawKeyEventDataMacOs(
              characters: message['characters'] ?? '',
              charactersIgnoringModifiers:
                  message['charactersIgnoringModifiers'] ?? '',
              keyCode: message['keyCode'] ?? 0,
              modifiers: message['modifiers'] ?? 0);
          break;
        case 'linux':
          data = RawKeyEventDataLinux(
              keyHelper: KeyHelper(message['toolkit'] ?? ''),
              codePoint: message['codePoint'] ?? 0,
              keyCode: message['keyCode'] ?? 0,
              scanCode: message['scanCode'] ?? 0,
              modifiers: message['modifiers'] ?? 0);
          break;
        default:
          throw FlutterError('Unknown keymap for key events: $keymap');
      }
    }

    final String type = message['type'];
    switch (type) {
      case 'keydown':
        return RawKeyDownEvent(data: data, character: message['character']);
      case 'keyup':
        return RawKeyUpEvent(data: data);
      default:
        throw FlutterError('Unknown key event type: $type');
    }
  }

  bool isKeyPressed(LogicalKeyboardKey key) =>
      RawKeyboard.instance.keysPressed.contains(key);

  bool get isControlPressed {
    return isKeyPressed(LogicalKeyboardKey.controlLeft) ||
        isKeyPressed(LogicalKeyboardKey.controlRight);
  }

  bool get isShiftPressed {
    return isKeyPressed(LogicalKeyboardKey.shiftLeft) ||
        isKeyPressed(LogicalKeyboardKey.shiftRight);
  }

  bool get isAltPressed {
    return isKeyPressed(LogicalKeyboardKey.altLeft) ||
        isKeyPressed(LogicalKeyboardKey.altRight);
  }

  bool get isMetaPressed {
    return isKeyPressed(LogicalKeyboardKey.metaLeft) ||
        isKeyPressed(LogicalKeyboardKey.metaRight);
  }

  PhysicalKeyboardKey get physicalKey => data.physicalKey;

  LogicalKeyboardKey get logicalKey => data.logicalKey;

  final String character;

  final RawKeyEventData data;
}

class RawKeyDownEvent extends RawKeyEvent {
  const RawKeyDownEvent({
    @required RawKeyEventData data,
    String character,
  }) : super(data: data, character: character);
}

class RawKeyUpEvent extends RawKeyEvent {
  const RawKeyUpEvent({
    @required RawKeyEventData data,
    String character,
  }) : super(data: data, character: character);
}

class RawKeyboard {
  RawKeyboard._() {
    SystemChannels.keyEvent.setMessageHandler(_handleKeyEvent);
  }

  static final RawKeyboard instance = RawKeyboard._();

  final List<ValueChanged<RawKeyEvent>> _listeners =
      <ValueChanged<RawKeyEvent>>[];

  void addListener(ValueChanged<RawKeyEvent> listener) {
    _listeners.add(listener);
  }

  void removeListener(ValueChanged<RawKeyEvent> listener) {
    _listeners.remove(listener);
  }

  Future<dynamic> _handleKeyEvent(dynamic message) async {
    final RawKeyEvent event = RawKeyEvent.fromMessage(message);
    if (event == null) {
      return;
    }
    if (event is RawKeyDownEvent) {
      _keysPressed.add(event.logicalKey);
    }
    if (event is RawKeyUpEvent) {
      _keysPressed.remove(event.logicalKey);
    }
    if (_listeners.isEmpty) {
      return;
    }
    for (ValueChanged<RawKeyEvent> listener
        in List<ValueChanged<RawKeyEvent>>.from(_listeners)) {
      if (_listeners.contains(listener)) {
        listener(event);
      }
    }
  }

  final Set<LogicalKeyboardKey> _keysPressed = <LogicalKeyboardKey>{};

  Set<LogicalKeyboardKey> get keysPressed {
    return _keysPressed.toSet();
  }
}

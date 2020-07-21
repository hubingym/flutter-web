import 'package:flutter_web/ui.dart';

import 'message_codecs.dart';
import 'platform_channel.dart';

class SystemChannels {
  SystemChannels._();

  static const MethodChannel navigation = const MethodChannel(
    'flutter/navigation',
    const JSONMethodCodec(),
  );

  static const MethodChannel platform = const OptionalMethodChannel(
    'flutter/platform',
    const JSONMethodCodec(),
  );

  static const MethodChannel textInput = const OptionalMethodChannel(
    'flutter/textinput',
    const JSONMethodCodec(),
  );

  static const BasicMessageChannel<dynamic> keyEvent =
      const BasicMessageChannel<dynamic>(
    'flutter/keyevent',
    const JSONMessageCodec(),
  );

  static const BasicMessageChannel<String> lifecycle =
      const BasicMessageChannel<String>(
    'flutter/lifecycle',
    const StringCodec(),
  );

  static const BasicMessageChannel<dynamic> system =
      const BasicMessageChannel<dynamic>(
    'flutter/system',
    const JSONMessageCodec(),
  );

  static const BasicMessageChannel<dynamic> accessibility =
      const BasicMessageChannel<dynamic>(
    'flutter/accessibility',
    const StandardMessageCodec(),
  );

  static const MethodChannel platform_views = MethodChannel(
    'flutter/platform_views',
    StandardMethodCodec(),
  );
}

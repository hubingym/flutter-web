import 'dart:async';

import 'system_channels.dart';

enum SystemSoundType {
  click,
}

class SystemSound {
  SystemSound._();

  static Future<void> play(SystemSoundType type) async {
    await SystemChannels.platform.invokeMethod(
      'SystemSound.play',
      type.toString(),
    );
  }
}

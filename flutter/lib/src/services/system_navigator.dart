import 'dart:async';

import 'system_channels.dart';

class SystemNavigator {
  SystemNavigator._();

  static Future<void> pop() async {
    await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }
}

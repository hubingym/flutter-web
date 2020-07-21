import 'dart:async';

import 'system_channels.dart';

class HapticFeedback {
  HapticFeedback._();

  static Future<void> vibrate() async {
    await SystemChannels.platform.invokeMethod('HapticFeedback.vibrate');
  }

  static Future<void> lightImpact() async {
    await SystemChannels.platform.invokeMethod(
      'HapticFeedback.vibrate',
      'HapticFeedbackType.lightImpact',
    );
  }

  static Future<void> mediumImpact() async {
    await SystemChannels.platform.invokeMethod(
      'HapticFeedback.vibrate',
      'HapticFeedbackType.mediumImpact',
    );
  }

  static Future<void> heavyImpact() async {
    await SystemChannels.platform.invokeMethod(
      'HapticFeedback.vibrate',
      'HapticFeedbackType.heavyImpact',
    );
  }

  static Future<void> selectionClick() async {
    await SystemChannels.platform.invokeMethod(
      'HapticFeedback.vibrate',
      'HapticFeedbackType.selectionClick',
    );
  }
}

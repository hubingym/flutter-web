import 'dart:async';
import 'package:flutter_web/ui.dart' show TextDirection;

import 'package:flutter_web/services.dart' show SystemChannels;

import 'semantics_event.dart'
    show AnnounceSemanticsEvent, TooltipSemanticsEvent;

class SemanticsService {
  SemanticsService._();

  static Future<void> announce(
      String message, TextDirection textDirection) async {
    final AnnounceSemanticsEvent event =
        new AnnounceSemanticsEvent(message, textDirection);
    await SystemChannels.accessibility.send(event.toMap());
  }

  static Future<void> tooltip(String message) async {
    final TooltipSemanticsEvent event = new TooltipSemanticsEvent(message);
    await SystemChannels.accessibility.send(event.toMap());
  }
}

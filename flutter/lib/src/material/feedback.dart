import 'dart:async';

import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/semantics.dart';
import 'package:flutter_web/services.dart';
import 'package:flutter_web/widgets.dart';

import 'theme.dart';

class Feedback {
  Feedback._();

  static Future<void> forTap(BuildContext context) async {
    context.findRenderObject().sendSemanticsEvent(const TapSemanticEvent());
    switch (_platform(context)) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return SystemSound.play(SystemSoundType.click);
      default:
        return new Future<void>.value();
    }
  }

  static GestureTapCallback wrapForTap(
      GestureTapCallback callback, BuildContext context) {
    if (callback == null) return null;
    return () {
      Feedback.forTap(context);
      callback();
    };
  }

  static Future<void> forLongPress(BuildContext context) {
    context
        .findRenderObject()
        .sendSemanticsEvent(const LongPressSemanticsEvent());
    switch (_platform(context)) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return HapticFeedback.vibrate();
      default:
        return new Future<void>.value();
    }
  }

  static GestureLongPressCallback wrapForLongPress(
      GestureLongPressCallback callback, BuildContext context) {
    if (callback == null) return null;
    return () {
      Feedback.forLongPress(context);
      callback();
    };
  }

  static TargetPlatform _platform(BuildContext context) =>
      Theme.of(context).platform;
}

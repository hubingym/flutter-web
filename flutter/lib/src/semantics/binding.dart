import 'package:flutter_web/ui.dart' as ui show AccessibilityFeatures, window;

import 'package:flutter_web/foundation.dart';

import 'debug.dart';

export 'package:flutter_web/ui.dart' show AccessibilityFeatures;

mixin SemanticsBinding on BindingBase {
  static SemanticsBinding get instance => _instance;
  static SemanticsBinding _instance;

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _accessibilityFeatures = ui.window.accessibilityFeatures;
  }

  @protected
  void handleAccessibilityFeaturesChanged() {
    _accessibilityFeatures = ui.window.accessibilityFeatures;
  }

  ui.AccessibilityFeatures get accessibilityFeatures => _accessibilityFeatures;
  ui.AccessibilityFeatures _accessibilityFeatures;

  bool get disableAnimations {
    bool value = _accessibilityFeatures.disableAnimations;
    assert(() {
      if (debugSemanticsDisableAnimations != null)
        value = debugSemanticsDisableAnimations;
      return true;
    }());
    return value;
  }
}

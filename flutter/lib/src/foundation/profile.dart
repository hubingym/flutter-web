import 'package:flutter_web/ui.dart' show VoidCallback;

const bool _kReleaseMode = bool.fromEnvironment('dart.vm.product');

void profile(VoidCallback function) {
  if (_kReleaseMode) return;
  function();
}

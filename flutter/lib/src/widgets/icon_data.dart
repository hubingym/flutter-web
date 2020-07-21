import 'package:flutter_web/src/util.dart';
import 'package:flutter_web/ui.dart';
import 'package:flutter_web/foundation.dart';

@immutable
class IconData {
  const IconData(
    this.codePoint, {
    this.fontFamily,
    this.fontPackage,
    this.matchTextDirection = false,
  });

  final int codePoint;

  final String fontFamily;

  final String fontPackage;

  final bool matchTextDirection;

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType) return false;
    final IconData typedOther = other;
    return codePoint == typedOther.codePoint &&
        fontFamily == typedOther.fontFamily &&
        fontPackage == typedOther.fontPackage &&
        matchTextDirection == typedOther.matchTextDirection;
  }

  @override
  int get hashCode =>
      hashValues(codePoint, fontFamily, fontPackage, matchTextDirection);

  @override
  String toString() {
    if (assertionsEnabled) {
      var data = codePoint.toRadixString(16).toUpperCase().padLeft(5, '0');
      return 'IconData(U+$data)';
    } else {
      return super.toString();
    }
  }
}

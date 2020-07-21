import 'package:flutter_web/ui.dart'
    show hashValues, TextAffinity, TextPosition;

import 'package:flutter_web/foundation.dart';

export 'package:flutter_web/ui.dart' show TextAffinity, TextPosition;

@immutable
class TextRange {
  const TextRange({@required this.start, @required this.end})
      : assert(start != null && start >= -1),
        assert(end != null && end >= -1);

  const TextRange.collapsed(int offset)
      : assert(offset != null && offset >= -1),
        start = offset,
        end = offset;

  static const TextRange empty = TextRange(start: -1, end: -1);

  final int start;

  final int end;

  bool get isValid => start >= 0 && end >= 0;

  bool get isCollapsed => start == end;

  bool get isNormalized => end >= start;

  String textBefore(String text) {
    assert(isNormalized);
    return text.substring(0, start);
  }

  String textAfter(String text) {
    assert(isNormalized);
    return text.substring(end);
  }

  String textInside(String text) {
    assert(isNormalized);
    return text.substring(start, end);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! TextRange) return false;
    final TextRange typedOther = other;
    return typedOther.start == start && typedOther.end == end;
  }

  @override
  int get hashCode => hashValues(start.hashCode, end.hashCode);

  @override
  String toString() => 'TextRange(start: $start, end: $end)';
}

@immutable
class TextSelection extends TextRange {
  const TextSelection(
      {@required this.baseOffset,
      @required this.extentOffset,
      this.affinity = TextAffinity.downstream,
      this.isDirectional = false})
      : super(
            start: baseOffset < extentOffset ? baseOffset : extentOffset,
            end: baseOffset < extentOffset ? extentOffset : baseOffset);

  const TextSelection.collapsed(
      {@required int offset, this.affinity = TextAffinity.downstream})
      : baseOffset = offset,
        extentOffset = offset,
        isDirectional = false,
        super.collapsed(offset);

  TextSelection.fromPosition(TextPosition position)
      : baseOffset = position.offset,
        extentOffset = position.offset,
        affinity = position.affinity,
        isDirectional = false,
        super.collapsed(position.offset);

  final int baseOffset;

  final int extentOffset;

  final TextAffinity affinity;

  final bool isDirectional;

  TextPosition get base => TextPosition(offset: baseOffset, affinity: affinity);

  TextPosition get extent =>
      TextPosition(offset: extentOffset, affinity: affinity);

  @override
  String toString() {
    return '$runtimeType(baseOffset: $baseOffset, extentOffset: $extentOffset, affinity: $affinity, isDirectional: $isDirectional)';
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! TextSelection) return false;
    final TextSelection typedOther = other;
    return typedOther.baseOffset == baseOffset &&
        typedOther.extentOffset == extentOffset &&
        typedOther.affinity == affinity &&
        typedOther.isDirectional == isDirectional;
  }

  @override
  int get hashCode => hashValues(baseOffset.hashCode, extentOffset.hashCode,
      affinity.hashCode, isDirectional.hashCode);

  TextSelection copyWith({
    int baseOffset,
    int extentOffset,
    TextAffinity affinity,
    bool isDirectional,
  }) {
    return TextSelection(
      baseOffset: baseOffset ?? this.baseOffset,
      extentOffset: extentOffset ?? this.extentOffset,
      affinity: affinity ?? this.affinity,
      isDirectional: isDirectional ?? this.isDirectional,
    );
  }
}

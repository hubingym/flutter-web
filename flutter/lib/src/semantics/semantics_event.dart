import 'package:flutter_web/painting.dart';

abstract class SemanticsEvent {
  const SemanticsEvent(this.type);

  final String type;

  Map<String, dynamic> toMap({int nodeId}) {
    final Map<String, dynamic> event = <String, dynamic>{
      'type': type,
      'data': getDataMap(),
    };
    if (nodeId != null) event['nodeId'] = nodeId;

    return event;
  }

  Map<String, dynamic> getDataMap();

  @override
  String toString() {
    final List<String> pairs = <String>[];
    final Map<String, dynamic> dataMap = getDataMap();
    final List<String> sortedKeys = dataMap.keys.toList()..sort();
    for (String key in sortedKeys) pairs.add('$key: ${dataMap[key]}');
    return '$runtimeType(${pairs.join(', ')})';
  }
}

class AnnounceSemanticsEvent extends SemanticsEvent {
  const AnnounceSemanticsEvent(this.message, this.textDirection)
      : assert(message != null),
        assert(textDirection != null),
        super('announce');

  final String message;

  final TextDirection textDirection;

  @override
  Map<String, dynamic> getDataMap() {
    return <String, dynamic>{
      'message': message,
      'textDirection': textDirection.index,
    };
  }
}

class TooltipSemanticsEvent extends SemanticsEvent {
  const TooltipSemanticsEvent(this.message) : super('tooltip');

  final String message;

  @override
  Map<String, dynamic> getDataMap() {
    return <String, dynamic>{
      'message': message,
    };
  }
}

class LongPressSemanticsEvent extends SemanticsEvent {
  const LongPressSemanticsEvent() : super('longPress');

  @override
  Map<String, dynamic> getDataMap() => const <String, dynamic>{};
}

class TapSemanticEvent extends SemanticsEvent {
  const TapSemanticEvent() : super('tap');

  @override
  Map<String, dynamic> getDataMap() => const <String, dynamic>{};
}

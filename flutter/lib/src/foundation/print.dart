import 'dart:async';
import 'dart:collection';

typedef DebugPrintCallback = void Function(String message, {int wrapWidth});

DebugPrintCallback debugPrint = debugPrintThrottled;

void debugPrintSynchronously(String message, {int wrapWidth}) {
  if (wrapWidth != null) {
    print(message
        .split('\n')
        .expand<String>((String line) => debugWordWrap(line, wrapWidth))
        .join('\n'));
  } else {
    print(message);
  }
}

void debugPrintThrottled(String message, {int wrapWidth}) {
  final List<String> messageLines = message?.split('\n') ?? <String>['null'];
  if (wrapWidth != null) {
    _debugPrintBuffer.addAll(messageLines
        .expand<String>((String line) => debugWordWrap(line, wrapWidth)));
  } else {
    _debugPrintBuffer.addAll(messageLines);
  }
  if (!_debugPrintScheduled) _debugPrintTask();
}

int _debugPrintedCharacters = 0;
const int _kDebugPrintCapacity = 12 * 1024;
const Duration _kDebugPrintPauseTime = Duration(seconds: 1);
final Queue<String> _debugPrintBuffer = Queue<String>();
final Stopwatch _debugPrintStopwatch = Stopwatch();
Completer<void> _debugPrintCompleter;
bool _debugPrintScheduled = false;
void _debugPrintTask() {
  _debugPrintScheduled = false;
  if (_debugPrintStopwatch.elapsed > _kDebugPrintPauseTime) {
    _debugPrintStopwatch.stop();
    _debugPrintStopwatch.reset();
    _debugPrintedCharacters = 0;
  }
  while (_debugPrintedCharacters < _kDebugPrintCapacity &&
      _debugPrintBuffer.isNotEmpty) {
    final String line = _debugPrintBuffer.removeFirst();
    _debugPrintedCharacters += line.length;
    print(line);
  }
  if (_debugPrintBuffer.isNotEmpty) {
    _debugPrintScheduled = true;
    _debugPrintedCharacters = 0;
    Timer(_kDebugPrintPauseTime, _debugPrintTask);
    _debugPrintCompleter ??= Completer<void>();
  } else {
    _debugPrintStopwatch.start();
    _debugPrintCompleter?.complete();
    _debugPrintCompleter = null;
  }
}

Future<void> get debugPrintDone =>
    _debugPrintCompleter?.future ?? Future<void>.value();

final RegExp _indentPattern = RegExp('^ *(?:[-+*] |[0-9]+[.):] )?');
enum _WordWrapParseMode { inSpace, inWord, atBreak }

Iterable<String> debugWordWrap(String message, int width,
    {String wrapIndent = ''}) sync* {
  if (message.length < width || message.trimLeft()[0] == '#') {
    yield message;
    return;
  }
  final Match prefixMatch = _indentPattern.matchAsPrefix(message);
  final String prefix = wrapIndent + ' ' * prefixMatch.group(0).length;
  int start = 0;
  int startForLengthCalculations = 0;
  bool addPrefix = false;
  int index = prefix.length;
  _WordWrapParseMode mode = _WordWrapParseMode.inSpace;
  int lastWordStart;
  int lastWordEnd;
  while (true) {
    switch (mode) {
      case _WordWrapParseMode.inSpace:
        while ((index < message.length) && (message[index] == ' ')) index += 1;
        lastWordStart = index;
        mode = _WordWrapParseMode.inWord;
        break;
      case _WordWrapParseMode.inWord:
        while ((index < message.length) && (message[index] != ' ')) index += 1;
        mode = _WordWrapParseMode.atBreak;
        break;
      case _WordWrapParseMode.atBreak:
        if ((index - startForLengthCalculations > width) ||
            (index == message.length)) {
          if ((index - startForLengthCalculations <= width) ||
              (lastWordEnd == null)) {
            lastWordEnd = index;
          }
          if (addPrefix) {
            yield prefix + message.substring(start, lastWordEnd);
          } else {
            yield message.substring(start, lastWordEnd);
            addPrefix = true;
          }
          if (lastWordEnd >= message.length) return;

          if (lastWordEnd == index) {
            while ((index < message.length) && (message[index] == ' '))
              index += 1;
            start = index;
            mode = _WordWrapParseMode.inWord;
          } else {
            assert(lastWordStart > lastWordEnd);
            start = lastWordStart;
            mode = _WordWrapParseMode.atBreak;
          }
          startForLengthCalculations = start - prefix.length;
          assert(addPrefix);
          lastWordEnd = null;
        } else {
          lastWordEnd = index;

          mode = _WordWrapParseMode.inSpace;
        }
        break;
    }
  }
}

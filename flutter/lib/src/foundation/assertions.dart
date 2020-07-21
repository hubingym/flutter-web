import 'package:meta/meta.dart';

import 'basic_types.dart';
import 'constants.dart';
import 'diagnostics.dart';
import 'print.dart';

typedef FlutterExceptionHandler = void Function(FlutterErrorDetails details);

typedef DiagnosticPropertiesTransformer = Iterable<DiagnosticsNode> Function(
    Iterable<DiagnosticsNode> properties);

typedef InformationCollector = Iterable<DiagnosticsNode> Function();

abstract class _ErrorDiagnostic extends DiagnosticsProperty<List<Object>> {
  _ErrorDiagnostic(
    String message, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.flat,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(message != null),
        super(
          null,
          <Object>[message],
          showName: false,
          showSeparator: false,
          defaultValue: null,
          style: style,
          level: level,
        );

  _ErrorDiagnostic._fromParts(
    List<Object> messageParts, {
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.flat,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(messageParts != null),
        super(
          null,
          messageParts,
          showName: false,
          showSeparator: false,
          defaultValue: null,
          style: style,
          level: level,
        );

  @override
  String valueToString({TextTreeConfiguration parentConfiguration}) {
    return value.join('');
  }
}

class ErrorDescription extends _ErrorDiagnostic {
  ErrorDescription(String message)
      : super(message, level: DiagnosticLevel.info);

  ErrorDescription._fromParts(List<Object> messageParts)
      : super._fromParts(messageParts, level: DiagnosticLevel.info);
}

class ErrorSummary extends _ErrorDiagnostic {
  ErrorSummary(String message) : super(message, level: DiagnosticLevel.summary);

  ErrorSummary._fromParts(List<Object> messageParts)
      : super._fromParts(messageParts, level: DiagnosticLevel.summary);
}

class ErrorHint extends _ErrorDiagnostic {
  ErrorHint(String message) : super(message, level: DiagnosticLevel.hint);

  ErrorHint._fromParts(List<Object> messageParts)
      : super._fromParts(messageParts, level: DiagnosticLevel.hint);
}

class ErrorSpacer extends DiagnosticsProperty<void> {
  ErrorSpacer()
      : super(
          '',
          null,
          description: '',
          showName: false,
        );
}

class FlutterErrorDetails extends Diagnosticable {
  const FlutterErrorDetails({
    this.exception,
    this.stack,
    this.library = 'Flutter framework',
    this.context,
    this.stackFilter,
    this.informationCollector,
    this.silent = false,
  });

  static final List<DiagnosticPropertiesTransformer> propertiesTransformers =
      <DiagnosticPropertiesTransformer>[];

  final dynamic exception;

  final StackTrace stack;

  final String library;

  final DiagnosticsNode context;

  final IterableFilter<String> stackFilter;

  final InformationCollector informationCollector;

  final bool silent;

  String exceptionAsString() {
    String longMessage;
    if (exception is AssertionError) {
      final Object message = exception.message;
      final String fullMessage = exception.toString();
      if (message is String && message != fullMessage) {
        if (fullMessage.length > message.length) {
          final int position = fullMessage.lastIndexOf(message);
          if (position == fullMessage.length - message.length &&
              position > 2 &&
              fullMessage.substring(position - 2, position) == ': ') {
            String body = fullMessage.substring(0, position - 2);
            final int splitPoint = body.indexOf(' Failed assertion:');
            if (splitPoint >= 0) {
              body =
                  '${body.substring(0, splitPoint)}\n${body.substring(splitPoint + 1)}';
            }
            longMessage = '${message.trimRight()}\n$body';
          }
        }
      }
      longMessage ??= fullMessage;
    } else if (exception is String) {
      longMessage = exception;
    } else if (exception is Error || exception is Exception) {
      longMessage = exception.toString();
    } else {
      longMessage = '  ${exception.toString()}';
    }
    longMessage = longMessage.trimRight();
    if (longMessage.isEmpty) longMessage = '  <no message available>';
    return longMessage;
  }

  Diagnosticable _exceptionToDiagnosticable() {
    if (exception is FlutterError) {
      return exception;
    }
    if (exception is AssertionError && exception.message is FlutterError) {
      return exception.message;
    }
    return null;
  }

  DiagnosticsNode get summary {
    String formatException() => exceptionAsString().split('\n')[0].trimLeft();
    if (kReleaseMode) {
      return DiagnosticsNode.message(formatException());
    }
    final Diagnosticable diagnosticable = _exceptionToDiagnosticable();
    DiagnosticsNode summary;
    if (diagnosticable != null) {
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      debugFillProperties(builder);
      summary = builder.properties.firstWhere(
          (DiagnosticsNode node) => node.level == DiagnosticLevel.summary,
          orElse: () => null);
    }
    return summary ?? ErrorSummary('${formatException()}');
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final DiagnosticsNode verb = ErrorDescription(
        'thrown${context != null ? ErrorDescription(" $context") : ""}');
    final Diagnosticable diagnosticable = _exceptionToDiagnosticable();
    if (exception is NullThrownError) {
      properties.add(ErrorDescription('The null value was $verb.'));
    } else if (exception is num) {
      properties.add(ErrorDescription('The number $exception was $verb.'));
    } else {
      DiagnosticsNode errorName;
      if (exception is AssertionError) {
        errorName = ErrorDescription('assertion');
      } else if (exception is String) {
        errorName = ErrorDescription('message');
      } else if (exception is Error || exception is Exception) {
        errorName = ErrorDescription('${exception.runtimeType}');
      } else {
        errorName = ErrorDescription('${exception.runtimeType} object');
      }
      properties.add(ErrorDescription('The following $errorName was $verb:'));
      if (diagnosticable != null) {
        diagnosticable.debugFillProperties(properties);
      } else {
        final String prefix = '${exception.runtimeType}: ';
        String message = exceptionAsString();
        if (message.startsWith(prefix))
          message = message.substring(prefix.length);
        properties.add(ErrorDescription('$message'));
      }
    }

    final Iterable<String> stackLines =
        (stack != null) ? stack.toString().trimRight().split('\n') : null;
    if (exception is AssertionError && diagnosticable == null) {
      bool ourFault = true;
      if (stackLines != null) {
        final List<String> stackList = stackLines.take(2).toList();
        if (stackList.length >= 2) {
          final RegExp throwPattern =
              RegExp(r'^#0 +_AssertionError._throwNew \(dart:.+\)$');
          final RegExp assertPattern =
              RegExp(r'^#1 +[^(]+ \((.+?):([0-9]+)(?::[0-9]+)?\)$');
          if (throwPattern.hasMatch(stackList[0])) {
            final Match assertMatch = assertPattern.firstMatch(stackList[1]);
            if (assertMatch != null) {
              assert(assertMatch.groupCount == 2);
              final RegExp ourLibraryPattern = RegExp(r'^package:flutter/');
              ourFault = ourLibraryPattern.hasMatch(assertMatch.group(1));
            }
          }
        }
      }
      if (ourFault) {
        properties.add(ErrorSpacer());
        properties.add(ErrorHint(
            'Either the assertion indicates an error in the framework itself, or we should '
            'provide substantially more information in this error message to help you determine '
            'and fix the underlying cause.\n'
            'In either case, please report this assertion by filing a bug on GitHub:\n'
            '  https://github.com/flutter/flutter/issues/new?template=BUG.md'));
      }
    }
    if (stack != null) {
      properties.add(ErrorSpacer());
      properties.add(DiagnosticsStackTrace(
          'When the exception was thrown, this was the stack', stack,
          stackFilter: stackFilter));
    }
    if (informationCollector != null) {
      properties.add(ErrorSpacer());
      informationCollector().forEach(properties.add);
    }
  }

  @override
  String toStringShort() {
    return library != null
        ? 'Exception caught by $library'
        : 'Exception caught';
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return toDiagnosticsNode(style: DiagnosticsTreeStyle.error)
        .toStringDeep(minLevel: minLevel);
  }

  @override
  DiagnosticsNode toDiagnosticsNode({String name, DiagnosticsTreeStyle style}) {
    return _FlutterErrorDetailsNode(
      name: name,
      value: this,
      style: style,
    );
  }
}

class FlutterError extends Error
    with DiagnosticableTreeMixin
    implements AssertionError {
  factory FlutterError(String message) {
    final List<String> lines = message.split('\n');
    return FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(lines.first),
      ...lines
          .skip(1)
          .map<DiagnosticsNode>((String line) => ErrorDescription(line)),
    ]);
  }

  FlutterError.fromParts(this.diagnostics)
      : assert(
            diagnostics.isNotEmpty,
            FlutterError.fromParts(
                <DiagnosticsNode>[ErrorSummary('Empty FlutterError')])) {
    assert(
        diagnostics.first.level == DiagnosticLevel.summary,
        FlutterError.fromParts(
          <DiagnosticsNode>[
            ErrorSummary('FlutterError is missing a summary.'),
            ErrorDescription(
                'All FlutterError objects should start with a short (one line) '
                'summary description of the problem that was detected.'),
            DiagnosticsProperty<FlutterError>('Malformed', this,
                expandableValue: true,
                showSeparator: false,
                style: DiagnosticsTreeStyle.whitespace),
            ErrorDescription(
                '\nThis error should still help you solve your problem, '
                'however please also report this malformed error in the '
                'framework by filing a bug on GitHub:\n'
                '  https://github.com/flutter/flutter/issues/new?template=BUG.md'),
          ],
        ));
    assert(() {
      final Iterable<DiagnosticsNode> summaries = diagnostics.where(
          (DiagnosticsNode node) => node.level == DiagnosticLevel.summary);
      if (summaries.length > 1) {
        final List<DiagnosticsNode> message = <DiagnosticsNode>[
          ErrorSummary('FlutterError contained multiple error summaries.'),
          ErrorDescription(
              'All FlutterError objects should have only a single short '
              '(one line) summary description of the problem that was '
              'detected.'),
        ];
        message.add(DiagnosticsProperty<FlutterError>('Malformed', this,
            expandableValue: true,
            showSeparator: false,
            style: DiagnosticsTreeStyle.whitespace));
        message.add(ErrorDescription(
            '\nThe malformed error has ${summaries.length} summaries.'));
        int i = 1;
        for (DiagnosticsNode summary in summaries) {
          message.add(DiagnosticsProperty<DiagnosticsNode>(
              'Summary $i', summary,
              expandableValue: true));
          i += 1;
        }
        message.add(ErrorDescription(
            '\nThis error should still help you solve your problem, '
            'however please also report this malformed error in the '
            'framework by filing a bug on GitHub:\n'
            '  https://github.com/flutter/flutter/issues/new?template=BUG.md'));
        throw FlutterError.fromParts(message);
      }
      return true;
    }());
  }

  final List<DiagnosticsNode> diagnostics;

  @override
  String get message => toString();

  static FlutterExceptionHandler onError = dumpErrorToConsole;

  static int _errorCount = 0;

  static void resetErrorCount() {
    _errorCount = 0;
  }

  static const int wrapWidth = 100;

  static void dumpErrorToConsole(FlutterErrorDetails details,
      {bool forceReport = false}) {
    assert(details != null);
    assert(details.exception != null);
    bool reportError = details.silent != true;
    assert(() {
      reportError = true;
      return true;
    }());
    if (!reportError && !forceReport) return;
    if (_errorCount == 0 || forceReport) {
      debugPrint(TextTreeRenderer(
        wrapWidth: wrapWidth,
        wrapWidthProperties: wrapWidth,
        maxDescendentsTruncatableNode: 5,
      )
          .render(details.toDiagnosticsNode(style: DiagnosticsTreeStyle.error))
          .trimRight());
    } else {
      debugPrint('Another exception was thrown: ${details.summary}');
    }
    _errorCount += 1;
  }

  static Iterable<String> defaultStackFilter(Iterable<String> frames) {
    const List<String> filteredPackages = <String>[
      'dart:async-patch',
      'dart:async',
      'package:stack_trace',
    ];
    const List<String> filteredClasses = <String>[
      '_AssertionError',
      '_FakeAsync',
      '_FrameCallbackEntry',
    ];
    final RegExp stackParser =
        RegExp(r'^#[0-9]+ +([^.]+).* \(([^/\\]*)[/\\].+:[0-9]+(?::[0-9]+)?\)$');
    final RegExp packageParser = RegExp(r'^([^:]+):(.+)$');
    final List<String> result = <String>[];
    final List<String> skipped = <String>[];
    for (String line in frames) {
      final Match match = stackParser.firstMatch(line);
      if (match != null) {
        assert(match.groupCount == 2);
        if (filteredPackages.contains(match.group(2))) {
          final Match packageMatch = packageParser.firstMatch(match.group(2));
          if (packageMatch != null && packageMatch.group(1) == 'package') {
            skipped.add('package ${packageMatch.group(2)}');
          } else {
            skipped.add('package ${match.group(2)}');
          }
          continue;
        }
        if (filteredClasses.contains(match.group(1))) {
          skipped.add('class ${match.group(1)}');
          continue;
        }
      }
      result.add(line);
    }
    if (skipped.length == 1) {
      result.add('(elided one frame from ${skipped.single})');
    } else if (skipped.length > 1) {
      final List<String> where = Set<String>.from(skipped).toList()..sort();
      if (where.length > 1) where[where.length - 1] = 'and ${where.last}';
      if (where.length > 2) {
        result
            .add('(elided ${skipped.length} frames from ${where.join(", ")})');
      } else {
        result.add('(elided ${skipped.length} frames from ${where.join(" ")})');
      }
    }
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    diagnostics?.forEach(properties.add);
  }

  @override
  String toStringShort() => 'FlutterError';

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    final TextTreeRenderer renderer = TextTreeRenderer(wrapWidth: 4000000000);
    return diagnostics
        .map((DiagnosticsNode node) => renderer.render(node).trimRight())
        .join('\n');
  }

  static void reportError(FlutterErrorDetails details) {
    assert(details != null);
    assert(details.exception != null);
    if (onError != null) onError(details);
  }
}

void debugPrintStack({String label, int maxFrames}) {
  if (label != null) debugPrint(label);
  Iterable<String> lines =
      StackTrace.current.toString().trimRight().split('\n');
  if (kIsWeb) {
    lines = lines.skip(1);
  }
  if (maxFrames != null) lines = lines.take(maxFrames);
  debugPrint(FlutterError.defaultStackFilter(lines).join('\n'));
}

class DiagnosticsStackTrace extends DiagnosticsBlock {
  DiagnosticsStackTrace(
    String name,
    StackTrace stack, {
    IterableFilter<String> stackFilter,
    bool showSeparator = true,
  }) : super(
          name: name,
          value: stack,
          properties: (stackFilter ?? FlutterError.defaultStackFilter)(
                  stack.toString().trimRight().split('\n'))
              .map<DiagnosticsNode>(_createStackFrame)
              .toList(),
          style: DiagnosticsTreeStyle.flat,
          showSeparator: showSeparator,
          allowTruncate: true,
        );

  DiagnosticsStackTrace.singleFrame(
    String name, {
    @required String frame,
    bool showSeparator = true,
  }) : super(
          name: name,
          properties: <DiagnosticsNode>[_createStackFrame(frame)],
          style: DiagnosticsTreeStyle.whitespace,
          showSeparator: showSeparator,
        );

  static DiagnosticsNode _createStackFrame(String frame) {
    return DiagnosticsNode.message(frame, allowWrap: false);
  }
}

class _FlutterErrorDetailsNode extends DiagnosticableNode<FlutterErrorDetails> {
  _FlutterErrorDetailsNode({
    String name,
    @required FlutterErrorDetails value,
    @required DiagnosticsTreeStyle style,
  }) : super(
          name: name,
          value: value,
          style: style,
        );

  @override
  DiagnosticPropertiesBuilder get builder {
    final DiagnosticPropertiesBuilder builder = super.builder;
    if (builder == null) {
      return null;
    }
    Iterable<DiagnosticsNode> properties = builder.properties;
    for (DiagnosticPropertiesTransformer transformer
        in FlutterErrorDetails.propertiesTransformers) {
      properties = transformer(properties);
    }
    return DiagnosticPropertiesBuilder.fromProperties(properties.toList());
  }
}

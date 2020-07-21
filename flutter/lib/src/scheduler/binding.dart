import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'package:flutter_web/ui.dart' show AppLifecycleState;

import 'package:collection/collection.dart'
    show PriorityQueue, HeapPriorityQueue;
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart';

import 'debug.dart';
import 'priority.dart';

export 'package:flutter_web/ui.dart' show AppLifecycleState, VoidCallback;

double get timeDilation => _timeDilation;
double _timeDilation = 1.0;

set timeDilation(double value) {
  assert(value > 0.0);
  if (_timeDilation == value) return;

  SchedulerBinding.instance?.resetEpoch();
  _timeDilation = value;
}

typedef FrameCallback = void Function(Duration timeStamp);

typedef TaskCallback<T> = T Function();

typedef SchedulingStrategy = bool Function(
    {int priority, SchedulerBinding scheduler});

class _TaskEntry<T> {
  _TaskEntry(this.task, this.priority, this.debugLabel, this.flow) {
    assert(() {
      debugStack = StackTrace.current;
      return true;
    }());
    completer = Completer<T>();
  }
  final TaskCallback<T> task;
  final int priority;
  final String debugLabel;
  final Flow flow;

  StackTrace debugStack;
  Completer<T> completer;

  void run() {
    if (!kReleaseMode) {
      Timeline.timeSync(
        debugLabel ?? 'Scheduled Task',
        () {
          completer.complete(task());
        },
        flow: flow != null ? Flow.step(flow.id) : null,
      );
    } else {
      completer.complete(task());
    }
  }
}

class _FrameCallbackEntry {
  _FrameCallbackEntry(this.callback, {bool rescheduling = false}) {
    assert(() {
      if (rescheduling) {
        assert(() {
          if (debugCurrentCallbackStack == null) {
            throw FlutterError(
                'scheduleFrameCallback called with rescheduling true, but no callback is in scope.\n'
                'The "rescheduling" argument should only be set to true if the '
                'callback is being reregistered from within the callback itself, '
                'and only then if the callback itself is entirely synchronous. '
                'If this is the initial registration of the callback, or if the '
                'callback is asynchronous, then do not use the "rescheduling" '
                'argument.');
          }
          return true;
        }());
        debugStack = debugCurrentCallbackStack;
      } else {
        debugStack = StackTrace.current;
      }
      return true;
    }());
  }

  final FrameCallback callback;

  static StackTrace debugCurrentCallbackStack;
  StackTrace debugStack;
}

enum SchedulerPhase {
  idle,

  transientCallbacks,

  midFrameMicrotasks,

  persistentCallbacks,

  postFrameCallbacks,
}

mixin SchedulerBinding on BindingBase, ServicesBinding {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    window.onBeginFrame = _handleBeginFrame;
    window.onDrawFrame = _handleDrawFrame;
    SystemChannels.lifecycle.setMessageHandler(_handleLifecycleMessage);
    readInitialLifecycleStateFromNativeWindow();
  }

  static SchedulerBinding get instance => _instance;
  static SchedulerBinding _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    if (!kReleaseMode) {
      registerNumericServiceExtension(
        name: 'timeDilation',
        getter: () async => timeDilation,
        setter: (double value) async {
          timeDilation = value;
        },
      );
    }
  }

  AppLifecycleState get lifecycleState => _lifecycleState;
  AppLifecycleState _lifecycleState;

  @protected
  void readInitialLifecycleStateFromNativeWindow() {
    if (_lifecycleState == null &&
        _parseAppLifecycleMessage(window.initialLifecycleState) != null) {
      _handleLifecycleMessage(window.initialLifecycleState);
    }
  }

  @protected
  @mustCallSuper
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    assert(state != null);
    _lifecycleState = state;
    switch (state) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        _setFramesEnabledState(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.suspending:
        _setFramesEnabledState(false);
        break;
    }
  }

  Future<String> _handleLifecycleMessage(String message) async {
    handleAppLifecycleStateChanged(_parseAppLifecycleMessage(message));
    return null;
  }

  static AppLifecycleState _parseAppLifecycleMessage(String message) {
    switch (message) {
      case 'AppLifecycleState.paused':
        return AppLifecycleState.paused;
      case 'AppLifecycleState.resumed':
        return AppLifecycleState.resumed;
      case 'AppLifecycleState.inactive':
        return AppLifecycleState.inactive;
      case 'AppLifecycleState.suspending':
        return AppLifecycleState.suspending;
    }
    return null;
  }

  SchedulingStrategy schedulingStrategy = defaultSchedulingStrategy;

  static int _taskSorter(_TaskEntry<dynamic> e1, _TaskEntry<dynamic> e2) {
    return -e1.priority.compareTo(e2.priority);
  }

  final PriorityQueue<_TaskEntry<dynamic>> _taskQueue =
      HeapPriorityQueue<_TaskEntry<dynamic>>(_taskSorter);

  Future<T> scheduleTask<T>(
    TaskCallback<T> task,
    Priority priority, {
    String debugLabel,
    Flow flow,
  }) {
    final bool isFirstTask = _taskQueue.isEmpty;
    final _TaskEntry<T> entry = _TaskEntry<T>(
      task,
      priority.value,
      debugLabel,
      flow,
    );
    _taskQueue.add(entry);
    if (isFirstTask && !locked) _ensureEventLoopCallback();
    return entry.completer.future;
  }

  @override
  void unlocked() {
    super.unlocked();
    if (_taskQueue.isNotEmpty) _ensureEventLoopCallback();
  }

  bool _hasRequestedAnEventLoopCallback = false;

  void _ensureEventLoopCallback() {
    assert(!locked);
    assert(_taskQueue.isNotEmpty);
    if (_hasRequestedAnEventLoopCallback) return;
    _hasRequestedAnEventLoopCallback = true;
    Timer.run(_runTasks);
  }

  void _runTasks() {
    _hasRequestedAnEventLoopCallback = false;
    if (handleEventLoopCallback()) _ensureEventLoopCallback();
  }

  @visibleForTesting
  bool handleEventLoopCallback() {
    if (_taskQueue.isEmpty || locked) return false;
    final _TaskEntry<dynamic> entry = _taskQueue.first;
    if (schedulingStrategy(priority: entry.priority, scheduler: this)) {
      try {
        _taskQueue.removeFirst();
        entry.run();
      } catch (exception, exceptionStack) {
        StackTrace callbackStack;
        assert(() {
          callbackStack = entry.debugStack;
          return true;
        }());
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: exceptionStack,
          library: 'scheduler library',
          context: ErrorDescription('during a task callback'),
          informationCollector: (callbackStack == null)
              ? null
              : () sync* {
                  yield DiagnosticsStackTrace(
                    '\nThis exception was thrown in the context of a scheduler callback. '
                    'When the scheduler callback was _registered_ (as opposed to when the '
                    'exception was thrown), this was the stack',
                    callbackStack,
                  );
                },
        ));
      }
      return _taskQueue.isNotEmpty;
    }
    return false;
  }

  int _nextFrameCallbackId = 0;
  Map<int, _FrameCallbackEntry> _transientCallbacks =
      <int, _FrameCallbackEntry>{};
  final Set<int> _removedIds = HashSet<int>();

  int get transientCallbackCount => _transientCallbacks.length;

  int scheduleFrameCallback(FrameCallback callback,
      {bool rescheduling = false}) {
    scheduleFrame();
    _nextFrameCallbackId += 1;
    _transientCallbacks[_nextFrameCallbackId] =
        _FrameCallbackEntry(callback, rescheduling: rescheduling);
    return _nextFrameCallbackId;
  }

  void cancelFrameCallbackWithId(int id) {
    assert(id > 0);
    _transientCallbacks.remove(id);
    _removedIds.add(id);
  }

  bool debugAssertNoTransientCallbacks(String reason) {
    assert(() {
      if (transientCallbackCount > 0) {
        final int count = transientCallbackCount;
        final Map<int, _FrameCallbackEntry> callbacks =
            Map<int, _FrameCallbackEntry>.from(_transientCallbacks);
        FlutterError.reportError(FlutterErrorDetails(
          exception: reason,
          library: 'scheduler library',
          informationCollector: () sync* {
            if (count == 1) {
              yield ErrorDescription('There was one transient callback left. '
                  'The stack trace for when it was registered is as follows:');
            } else {
              yield ErrorDescription(
                  'There were $count transient callbacks left. '
                  'The stack traces for when they were registered are as follows:');
            }
            for (int id in callbacks.keys) {
              final _FrameCallbackEntry entry = callbacks[id];
              yield DiagnosticsStackTrace(
                  '── callback $id ──', entry.debugStack,
                  showSeparator: false);
            }
          },
        ));
      }
      return true;
    }());
    return true;
  }

  static void debugPrintTransientCallbackRegistrationStack() {
    assert(() {
      if (_FrameCallbackEntry.debugCurrentCallbackStack != null) {
        debugPrint(
            'When the current transient callback was registered, this was the stack:');
        debugPrint(FlutterError.defaultStackFilter(_FrameCallbackEntry
                .debugCurrentCallbackStack
                .toString()
                .trimRight()
                .split('\n'))
            .join('\n'));
      } else {
        debugPrint('No transient callback is currently executing.');
      }
      return true;
    }());
  }

  final List<FrameCallback> _persistentCallbacks = <FrameCallback>[];

  void addPersistentFrameCallback(FrameCallback callback) {
    _persistentCallbacks.add(callback);
  }

  final List<FrameCallback> _postFrameCallbacks = <FrameCallback>[];

  void addPostFrameCallback(FrameCallback callback) {
    _postFrameCallbacks.add(callback);
  }

  Completer<void> _nextFrameCompleter;

  Future<void> get endOfFrame {
    if (_nextFrameCompleter == null) {
      if (schedulerPhase == SchedulerPhase.idle) scheduleFrame();
      _nextFrameCompleter = Completer<void>();
      addPostFrameCallback((Duration timeStamp) {
        _nextFrameCompleter.complete();
        _nextFrameCompleter = null;
      });
    }
    return _nextFrameCompleter.future;
  }

  bool get hasScheduledFrame => _hasScheduledFrame;
  bool _hasScheduledFrame = false;

  SchedulerPhase get schedulerPhase => _schedulerPhase;
  SchedulerPhase _schedulerPhase = SchedulerPhase.idle;

  bool get framesEnabled => _framesEnabled;

  bool _framesEnabled = true;
  void _setFramesEnabledState(bool enabled) {
    if (_framesEnabled == enabled) return;
    _framesEnabled = enabled;
    if (enabled) scheduleFrame();
  }

  void ensureVisualUpdate() {
    switch (schedulerPhase) {
      case SchedulerPhase.idle:
      case SchedulerPhase.postFrameCallbacks:
        scheduleFrame();
        return;
      case SchedulerPhase.transientCallbacks:
      case SchedulerPhase.midFrameMicrotasks:
      case SchedulerPhase.persistentCallbacks:
        return;
    }
  }

  void scheduleFrame() {
    if (_hasScheduledFrame || !_framesEnabled) return;
    assert(() {
      if (debugPrintScheduleFrameStacks)
        debugPrintStack(
            label: 'scheduleFrame() called. Current phase is $schedulerPhase.');
      return true;
    }());
    window.scheduleFrame();
    _hasScheduledFrame = true;
  }

  void scheduleForcedFrame() {
    if (_hasScheduledFrame) return;
    assert(() {
      if (debugPrintScheduleFrameStacks)
        debugPrintStack(
            label:
                'scheduleForcedFrame() called. Current phase is $schedulerPhase.');
      return true;
    }());
    window.scheduleFrame();
    _hasScheduledFrame = true;
  }

  bool _warmUpFrame = false;

  void scheduleWarmUpFrame() {
    if (_warmUpFrame || schedulerPhase != SchedulerPhase.idle) return;

    _warmUpFrame = true;
    Timeline.startSync('Warm-up frame');
    final bool hadScheduledFrame = _hasScheduledFrame;

    Timer.run(() {
      assert(_warmUpFrame);
      handleBeginFrame(null);
    });
    Timer.run(() {
      assert(_warmUpFrame);
      handleDrawFrame();

      resetEpoch();
      _warmUpFrame = false;
      if (hadScheduledFrame) scheduleFrame();
    });

    lockEvents(() async {
      await endOfFrame;
      Timeline.finishSync();
    });
  }

  Duration _firstRawTimeStampInEpoch;
  Duration _epochStart = Duration.zero;
  Duration _lastRawTimeStamp = Duration.zero;

  void resetEpoch() {
    _epochStart = _adjustForEpoch(_lastRawTimeStamp);
    _firstRawTimeStampInEpoch = null;
  }

  Duration _adjustForEpoch(Duration rawTimeStamp) {
    final Duration rawDurationSinceEpoch = _firstRawTimeStampInEpoch == null
        ? Duration.zero
        : rawTimeStamp - _firstRawTimeStampInEpoch;
    return Duration(
        microseconds:
            (rawDurationSinceEpoch.inMicroseconds / timeDilation).round() +
                _epochStart.inMicroseconds);
  }

  Duration get currentFrameTimeStamp {
    assert(_currentFrameTimeStamp != null);
    return _currentFrameTimeStamp;
  }

  Duration _currentFrameTimeStamp;

  int _profileFrameNumber = 0;
  final Stopwatch _profileFrameStopwatch = Stopwatch();
  String _debugBanner;
  bool _ignoreNextEngineDrawFrame = false;

  void _handleBeginFrame(Duration rawTimeStamp) {
    if (_warmUpFrame) {
      assert(!_ignoreNextEngineDrawFrame);
      _ignoreNextEngineDrawFrame = true;
      return;
    }
    handleBeginFrame(rawTimeStamp);
  }

  void _handleDrawFrame() {
    if (_ignoreNextEngineDrawFrame) {
      _ignoreNextEngineDrawFrame = false;
      return;
    }
    handleDrawFrame();
  }

  void handleBeginFrame(Duration rawTimeStamp) {
    Timeline.startSync('Frame', arguments: timelineWhitelistArguments);
    _firstRawTimeStampInEpoch ??= rawTimeStamp;
    _currentFrameTimeStamp = _adjustForEpoch(rawTimeStamp ?? _lastRawTimeStamp);
    if (rawTimeStamp != null) _lastRawTimeStamp = rawTimeStamp;

    if (!kReleaseMode) {
      _profileFrameNumber += 1;
      _profileFrameStopwatch.reset();
      _profileFrameStopwatch.start();
    }

    assert(() {
      if (debugPrintBeginFrameBanner || debugPrintEndFrameBanner) {
        final StringBuffer frameTimeStampDescription = StringBuffer();
        if (rawTimeStamp != null) {
          _debugDescribeTimeStamp(
              _currentFrameTimeStamp, frameTimeStampDescription);
        } else {
          frameTimeStampDescription.write('(warm-up frame)');
        }
        _debugBanner =
            '▄▄▄▄▄▄▄▄ Frame ${_profileFrameNumber.toString().padRight(7)}   ${frameTimeStampDescription.toString().padLeft(18)} ▄▄▄▄▄▄▄▄';
        if (debugPrintBeginFrameBanner) debugPrint(_debugBanner);
      }
      return true;
    }());

    assert(schedulerPhase == SchedulerPhase.idle);
    _hasScheduledFrame = false;
    try {
      Timeline.startSync('Animate', arguments: timelineWhitelistArguments);
      _schedulerPhase = SchedulerPhase.transientCallbacks;
      final Map<int, _FrameCallbackEntry> callbacks = _transientCallbacks;
      _transientCallbacks = <int, _FrameCallbackEntry>{};
      callbacks.forEach((int id, _FrameCallbackEntry callbackEntry) {
        if (!_removedIds.contains(id))
          _invokeFrameCallback(callbackEntry.callback, _currentFrameTimeStamp,
              callbackEntry.debugStack);
      });
      _removedIds.clear();
    } finally {
      _schedulerPhase = SchedulerPhase.midFrameMicrotasks;
    }
  }

  void handleDrawFrame() {
    assert(_schedulerPhase == SchedulerPhase.midFrameMicrotasks);
    Timeline.finishSync();
    try {
      _schedulerPhase = SchedulerPhase.persistentCallbacks;
      for (FrameCallback callback in _persistentCallbacks)
        _invokeFrameCallback(callback, _currentFrameTimeStamp);

      _schedulerPhase = SchedulerPhase.postFrameCallbacks;
      final List<FrameCallback> localPostFrameCallbacks =
          List<FrameCallback>.from(_postFrameCallbacks);
      _postFrameCallbacks.clear();
      for (FrameCallback callback in localPostFrameCallbacks)
        _invokeFrameCallback(callback, _currentFrameTimeStamp);
    } finally {
      _schedulerPhase = SchedulerPhase.idle;
      Timeline.finishSync();
      if (!kReleaseMode) {
        _profileFrameStopwatch.stop();
        _profileFramePostEvent();
      }
      assert(() {
        if (debugPrintEndFrameBanner) debugPrint('▀' * _debugBanner.length);
        _debugBanner = null;
        return true;
      }());
      _currentFrameTimeStamp = null;
    }
  }

  void _profileFramePostEvent() {
    postEvent('Flutter.Frame', <String, dynamic>{
      'number': _profileFrameNumber,
      'startTime': _currentFrameTimeStamp.inMicroseconds,
      'elapsed': _profileFrameStopwatch.elapsedMicroseconds,
    });
  }

  static void _debugDescribeTimeStamp(Duration timeStamp, StringBuffer buffer) {
    if (timeStamp.inDays > 0) buffer.write('${timeStamp.inDays}d ');
    if (timeStamp.inHours > 0)
      buffer.write(
          '${timeStamp.inHours - timeStamp.inDays * Duration.hoursPerDay}h ');
    if (timeStamp.inMinutes > 0)
      buffer.write(
          '${timeStamp.inMinutes - timeStamp.inHours * Duration.minutesPerHour}m ');
    if (timeStamp.inSeconds > 0)
      buffer.write(
          '${timeStamp.inSeconds - timeStamp.inMinutes * Duration.secondsPerMinute}s ');
    buffer.write(
        '${timeStamp.inMilliseconds - timeStamp.inSeconds * Duration.millisecondsPerSecond}');
    final int microseconds = timeStamp.inMicroseconds -
        timeStamp.inMilliseconds * Duration.microsecondsPerMillisecond;
    if (microseconds > 0)
      buffer.write('.${microseconds.toString().padLeft(3, "0")}');
    buffer.write('ms');
  }

  void _invokeFrameCallback(FrameCallback callback, Duration timeStamp,
      [StackTrace callbackStack]) {
    assert(callback != null);
    assert(_FrameCallbackEntry.debugCurrentCallbackStack == null);
    assert(() {
      _FrameCallbackEntry.debugCurrentCallbackStack = callbackStack;
      return true;
    }());
    try {
      callback(timeStamp);
    } catch (exception, exceptionStack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: exceptionStack,
        library: 'scheduler library',
        context: ErrorDescription('during a scheduler callback'),
        informationCollector: (callbackStack == null)
            ? null
            : () sync* {
                yield DiagnosticsStackTrace(
                  '\nThis exception was thrown in the context of a scheduler callback. '
                  'When the scheduler callback was _registered_ (as opposed to when the '
                  'exception was thrown), this was the stack',
                  callbackStack,
                );
              },
      ));
    }
    assert(() {
      _FrameCallbackEntry.debugCurrentCallbackStack = null;
      return true;
    }());
  }
}

bool defaultSchedulingStrategy({int priority, SchedulerBinding scheduler}) {
  if (scheduler.transientCallbackCount > 0)
    return priority >= Priority.animation.value;
  return true;
}

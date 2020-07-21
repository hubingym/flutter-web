import 'dart:async';

import 'package:meta/meta.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/scheduler.dart';

typedef void TickerCallback(Duration elapsed);

abstract class TickerProvider {
  const TickerProvider();

  Ticker createTicker(TickerCallback onTick);
}

class Ticker {
  Ticker(this._onTick, {this.debugLabel}) {
    assert(() {
      _debugCreationStack = StackTrace.current;
      return true;
    }());
  }

  TickerFuture _future;

  bool get muted => _muted;
  bool _muted = false;

  set muted(bool value) {
    if (value == muted) return;
    _muted = value;
    if (value) {
      unscheduleTick();
    } else if (shouldScheduleTick) {
      scheduleTick();
    }
  }

  bool get isTicking {
    if (_future == null) return false;
    if (muted) return false;
    if (SchedulerBinding.instance.framesEnabled) return true;
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle)
      return true;
    return false;
  }

  bool get isActive => _future != null;

  Duration _startTime;

  TickerFuture start() {
    assert(() {
      if (isActive) {
        throw FlutterError('A ticker was started twice.\n'
            'A ticker that is already active cannot be started again without first stopping it.\n'
            'The affected ticker was: ${toString(debugIncludeStack: true)}');
      }
      return true;
    }());
    assert(_startTime == null);
    _future = TickerFuture._();
    if (shouldScheduleTick) {
      scheduleTick();
    }
    if (SchedulerBinding.instance.schedulerPhase.index >
            SchedulerPhase.idle.index &&
        SchedulerBinding.instance.schedulerPhase.index <
            SchedulerPhase.postFrameCallbacks.index)
      _startTime = SchedulerBinding.instance.currentFrameTimeStamp;
    return _future;
  }

  void stop({bool canceled = false}) {
    if (!isActive) return;

    final TickerFuture localFuture = _future;
    _future = null;
    _startTime = null;
    assert(!isActive);

    unscheduleTick();
    if (canceled) {
      localFuture._cancel(this);
    } else {
      localFuture._complete();
    }
  }

  final TickerCallback _onTick;

  int _animationId;

  @protected
  bool get scheduled => _animationId != null;

  @protected
  bool get shouldScheduleTick => !muted && isActive && !scheduled;

  void _tick(Duration timeStamp) {
    assert(isTicking);
    assert(scheduled);
    _animationId = null;

    _startTime ??= timeStamp;
    _onTick(timeStamp - _startTime);

    if (shouldScheduleTick) scheduleTick(rescheduling: true);
  }

  @protected
  void scheduleTick({bool rescheduling = false}) {
    assert(!scheduled);
    assert(shouldScheduleTick);
    _animationId = SchedulerBinding.instance
        .scheduleFrameCallback(_tick, rescheduling: rescheduling);
  }

  @protected
  void unscheduleTick() {
    if (scheduled) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(_animationId);
      _animationId = null;
    }
    assert(!shouldScheduleTick);
  }

  void absorbTicker(Ticker originalTicker) {
    assert(!isActive);
    assert(_future == null);
    assert(_startTime == null);
    assert(_animationId == null);
    assert(
        (originalTicker._future == null) == (originalTicker._startTime == null),
        'Cannot absorb Ticker after it has been disposed.');
    if (originalTicker._future != null) {
      _future = originalTicker._future;
      _startTime = originalTicker._startTime;
      if (shouldScheduleTick) scheduleTick();
      originalTicker._future = null;
      originalTicker.unscheduleTick();
    }
    originalTicker.dispose();
  }

  @mustCallSuper
  void dispose() {
    if (_future != null) {
      final TickerFuture localFuture = _future;
      _future = null;
      assert(!isActive);
      unscheduleTick();
      localFuture._cancel(this);
    }
    assert(() {
      _startTime = Duration.zero;
      return true;
    }());
  }

  final String debugLabel;
  StackTrace _debugCreationStack;

  @override
  String toString({bool debugIncludeStack = false}) {
    final StringBuffer buffer = StringBuffer();
    buffer.write('$runtimeType(');
    assert(() {
      buffer.write(debugLabel ?? '');
      return true;
    }());
    buffer.write(')');
    assert(() {
      if (debugIncludeStack) {
        buffer.writeln();
        buffer.writeln(
            'The stack trace when the $runtimeType was actually created was:');
        FlutterError.defaultStackFilter(
                _debugCreationStack.toString().trimRight().split('\n'))
            .forEach(buffer.writeln);
      }
      return true;
    }());
    return buffer.toString();
  }
}

class TickerFuture implements Future<void> {
  TickerFuture._();

  TickerFuture.complete() {
    _complete();
  }

  final Completer<Null> _primaryCompleter = new Completer<Null>();
  Completer<Null> _secondaryCompleter;

  bool _completed;

  void _complete() {
    assert(_completed == null);
    _completed = true;
    _primaryCompleter.complete(null);
    _secondaryCompleter?.complete(null);
  }

  void _cancel(Ticker ticker) {
    assert(_completed == null);
    _completed = false;
    _secondaryCompleter?.completeError(new TickerCanceled(ticker));
  }

  void whenCompleteOrCancel(VoidCallback callback) {
    Null thunk(dynamic value) {
      callback();
      return null;
    }

    orCancel.then(thunk, onError: thunk);
  }

  Future<void> get orCancel {
    if (_secondaryCompleter == null) {
      _secondaryCompleter = new Completer<Null>();
      if (_completed != null) {
        if (_completed) {
          _secondaryCompleter.complete(null);
        } else {
          _secondaryCompleter.completeError(const TickerCanceled());
        }
      }
    }
    return _secondaryCompleter.future;
  }

  @override
  Stream<Null> asStream() {
    return _primaryCompleter.future.asStream();
  }

  @override
  Future<void> catchError(Function onError, {bool test(dynamic error)}) {
    return _primaryCompleter.future.catchError(onError, test: test);
  }

  @override
  Future<E> then<E>(dynamic f(Null value), {Function onError}) {
    return _primaryCompleter.future.then<E>(f, onError: onError);
  }

  @override
  Future<void> timeout(Duration timeLimit, {dynamic onTimeout()}) {
    return _primaryCompleter.future.timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<void> whenComplete(dynamic action()) {
    return _primaryCompleter.future.whenComplete(action);
  }
}

class TickerCanceled implements Exception {
  const TickerCanceled([this.ticker]);

  final Ticker ticker;

  @override
  String toString() {
    if (ticker != null) return 'This ticker was canceled: $ticker';
    return 'The ticker was canceled before the "orCancel" property was first '
        'used.';
  }
}

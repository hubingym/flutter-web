import 'dart:async' show Future, Stream, StreamSubscription;

import 'framework.dart';

abstract class StreamBuilderBase<T, S> extends StatefulWidget {
  const StreamBuilderBase({Key key, this.stream}) : super(key: key);

  final Stream<T> stream;

  S initial();

  S afterConnected(S current) => current;

  S afterData(S current, T data);

  S afterError(S current, Object error) => current;

  S afterDone(S current) => current;

  S afterDisconnected(S current) => current;

  Widget build(BuildContext context, S currentSummary);

  @override
  State<StreamBuilderBase<T, S>> createState() =>
      _StreamBuilderBaseState<T, S>();
}

class _StreamBuilderBaseState<T, S> extends State<StreamBuilderBase<T, S>> {
  StreamSubscription<T> _subscription;
  S _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.initial();
    _subscribe();
  }

  @override
  void didUpdateWidget(StreamBuilderBase<T, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stream != widget.stream) {
      if (_subscription != null) {
        _unsubscribe();
        _summary = widget.afterDisconnected(_summary);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context, _summary);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (widget.stream != null) {
      _subscription = widget.stream.listen((T data) {
        setState(() {
          _summary = widget.afterData(_summary, data);
        });
      }, onError: (Object error) {
        setState(() {
          _summary = widget.afterError(_summary, error);
        });
      }, onDone: () {
        setState(() {
          _summary = widget.afterDone(_summary);
        });
      });
      _summary = widget.afterConnected(_summary);
    }
  }

  void _unsubscribe() {
    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }
  }
}

enum ConnectionState {
  none,

  waiting,

  active,

  done,
}

@immutable
class AsyncSnapshot<T> {
  const AsyncSnapshot._(this.connectionState, this.data, this.error)
      : assert(connectionState != null),
        assert(!(data != null && error != null));

  const AsyncSnapshot.nothing() : this._(ConnectionState.none, null, null);

  const AsyncSnapshot.withData(ConnectionState state, T data)
      : this._(state, data, null);

  const AsyncSnapshot.withError(ConnectionState state, Object error)
      : this._(state, null, error);

  final ConnectionState connectionState;

  final T data;

  T get requireData {
    if (hasData) return data;
    if (hasError) throw error;
    throw StateError('Snapshot has neither data nor error');
  }

  final Object error;

  AsyncSnapshot<T> inState(ConnectionState state) =>
      AsyncSnapshot<T>._(state, data, error);

  bool get hasData => data != null;

  bool get hasError => error != null;

  @override
  String toString() => '$runtimeType($connectionState, $data, $error)';

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! AsyncSnapshot<T>) return false;
    final AsyncSnapshot<T> typedOther = other;
    return connectionState == typedOther.connectionState &&
        data == typedOther.data &&
        error == typedOther.error;
  }

  @override
  int get hashCode => hashValues(connectionState, data, error);
}

typedef AsyncWidgetBuilder<T> = Widget Function(
    BuildContext context, AsyncSnapshot<T> snapshot);

class StreamBuilder<T> extends StreamBuilderBase<T, AsyncSnapshot<T>> {
  const StreamBuilder(
      {Key key, this.initialData, Stream<T> stream, @required this.builder})
      : assert(builder != null),
        super(key: key, stream: stream);

  final AsyncWidgetBuilder<T> builder;

  final T initialData;

  @override
  AsyncSnapshot<T> initial() =>
      AsyncSnapshot<T>.withData(ConnectionState.none, initialData);

  @override
  AsyncSnapshot<T> afterConnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.waiting);

  @override
  AsyncSnapshot<T> afterData(AsyncSnapshot<T> current, T data) {
    return AsyncSnapshot<T>.withData(ConnectionState.active, data);
  }

  @override
  AsyncSnapshot<T> afterError(AsyncSnapshot<T> current, Object error) {
    return AsyncSnapshot<T>.withError(ConnectionState.active, error);
  }

  @override
  AsyncSnapshot<T> afterDone(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.done);

  @override
  AsyncSnapshot<T> afterDisconnected(AsyncSnapshot<T> current) =>
      current.inState(ConnectionState.none);

  @override
  Widget build(BuildContext context, AsyncSnapshot<T> currentSummary) =>
      builder(context, currentSummary);
}

class FutureBuilder<T> extends StatefulWidget {
  const FutureBuilder(
      {Key key, this.future, this.initialData, @required this.builder})
      : assert(builder != null),
        super(key: key);

  final Future<T> future;

  final AsyncWidgetBuilder<T> builder;

  final T initialData;

  @override
  State<FutureBuilder<T>> createState() => _FutureBuilderState<T>();
}

class _FutureBuilderState<T> extends State<FutureBuilder<T>> {
  Object _activeCallbackIdentity;
  AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot =
        AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData);
    _subscribe();
  }

  @override
  void didUpdateWidget(FutureBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        _snapshot = _snapshot.inState(ConnectionState.none);
      }
      _subscribe();
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _snapshot);

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    if (widget.future != null) {
      final Object callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      widget.future.then<void>((T data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      }, onError: (Object error) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error);
          });
        }
      });
      _snapshot = _snapshot.inState(ConnectionState.waiting);
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }
}

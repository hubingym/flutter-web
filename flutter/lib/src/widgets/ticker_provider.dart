import 'package:meta/meta.dart';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/scheduler.dart';

import 'framework.dart';

class TickerMode extends InheritedWidget {
  const TickerMode({Key key, @required this.enabled, Widget child})
      : assert(enabled != null),
        super(key: key, child: child);

  final bool enabled;

  static bool of(BuildContext context) {
    final TickerMode widget = context.inheritFromWidgetOfExactType(TickerMode);
    return widget?.enabled ?? true;
  }

  @override
  bool updateShouldNotify(TickerMode oldWidget) => enabled != oldWidget.enabled;
}

@optionalTypeArgs
mixin SingleTickerProviderStateMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  Ticker _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) return true;
      throw FlutterError(
          '$runtimeType is a SingleTickerProviderStateMixin but multiple tickers were created.\n'
          'A SingleTickerProviderStateMixin can only be used as a TickerProvider once. If a '
          'State is used for multiple AnimationController objects, or if it is passed to other '
          'objects and those objects might use it more than one time in total, then instead of '
          'mixing in a SingleTickerProviderStateMixin, use a regular TickerProviderStateMixin.');
    }());
    _ticker = Ticker(onTick,
        debugLabel: kDebugMode ? '${widget.toStringShort()}' : null);

    return _ticker;
  }

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker.isActive) return true;
      throw FlutterError('$this was disposed with an active Ticker.\n'
          '$runtimeType created a Ticker via its SingleTickerProviderStateMixin, but at the time '
          'dispose() was called on the mixin, that Ticker was still active. The Ticker must '
          'be disposed before calling super.dispose(). Tickers used by AnimationControllers '
          'should be disposed by calling dispose() on the AnimationController itself. '
          'Otherwise, the ticker will leak.\n'
          'The offending ticker was: ${_ticker.toString(debugIncludeStack: true)}');
    }());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (_ticker != null) _ticker.muted = !TickerMode.of(context);
    super.didChangeDependencies();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    String tickerDescription;
    if (_ticker != null) {
      if (_ticker.isActive && _ticker.muted)
        tickerDescription = 'active but muted';
      else if (_ticker.isActive)
        tickerDescription = 'active';
      else if (_ticker.muted)
        tickerDescription = 'inactive and muted';
      else
        tickerDescription = 'inactive';
    }
    properties.add(DiagnosticsProperty<Ticker>('ticker', _ticker,
        description: tickerDescription,
        showSeparator: false,
        defaultValue: null));
  }
}

@optionalTypeArgs
mixin TickerProviderStateMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  Set<Ticker> _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= new Set<_WidgetTicker>();
    final _WidgetTicker result = new _WidgetTicker(onTick, this);
    _tickers.add(result);
    return result;
  }

  void _removeTicker(_WidgetTicker ticker) {
    assert(_tickers != null);
    assert(_tickers.contains(ticker));
    _tickers.remove(ticker);
  }

  @override
  void dispose() {
    assert(() {
      if (_tickers != null) {
        for (Ticker ticker in _tickers) {
          if (ticker.isActive) {
            throw new FlutterError('$this was disposed with an active Ticker.\n'
                '$runtimeType created a Ticker via its '
                'TickerProviderStateMixin, but at the time dispose() was '
                'called on the mixin, that Ticker was still active. All '
                'Tickers must be disposed before calling super.dispose(). '
                'Tickers used by AnimationControllers should be disposed by '
                'calling dispose() on the AnimationController itself. '
                'Otherwise, the ticker will leak.\n'
                'The offending ticker was: ${ticker}');
          }
        }
      }
      return true;
    }());
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    final bool muted = !TickerMode.of(context);
    if (_tickers != null) {
      for (Ticker ticker in _tickers) ticker.muted = muted;
    }
    super.didChangeDependencies();
  }
}

class _WidgetTicker extends Ticker {
  _WidgetTicker(TickerCallback onTick, this._creator) : super(onTick);

  final TickerProviderStateMixin _creator;

  @override
  void dispose() {
    _creator._removeTicker(this);
    super.dispose();
  }
}

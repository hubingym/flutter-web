import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/scheduler.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'sliver.dart';

class AutomaticKeepAlive extends StatefulWidget {
  const AutomaticKeepAlive({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _AutomaticKeepAliveState createState() => _AutomaticKeepAliveState();
}

class _AutomaticKeepAliveState extends State<AutomaticKeepAlive> {
  Map<Listenable, VoidCallback> _handles;
  Widget _child;
  bool _keepingAlive = false;

  @override
  void initState() {
    super.initState();
    _updateChild();
  }

  @override
  void didUpdateWidget(AutomaticKeepAlive oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateChild();
  }

  void _updateChild() {
    _child = NotificationListener<KeepAliveNotification>(
      onNotification: _addClient,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    if (_handles != null) {
      for (Listenable handle in _handles.keys)
        handle.removeListener(_handles[handle]);
    }
    super.dispose();
  }

  bool _addClient(KeepAliveNotification notification) {
    final Listenable handle = notification.handle;
    _handles ??= <Listenable, VoidCallback>{};
    assert(!_handles.containsKey(handle));
    _handles[handle] = _createCallback(handle);
    handle.addListener(_handles[handle]);
    if (!_keepingAlive) {
      _keepingAlive = true;
      final ParentDataElement<SliverWithKeepAliveWidget> childElement =
          _getChildElement();
      if (childElement != null) {
        _updateParentDataOfChild(childElement);
      } else {
        SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
          if (!mounted) {
            return;
          }
          final ParentDataElement<SliverWithKeepAliveWidget> childElement =
              _getChildElement();
          assert(childElement != null);
          _updateParentDataOfChild(childElement);
        });
      }
    }
    return false;
  }

  ParentDataElement<SliverWithKeepAliveWidget> _getChildElement() {
    assert(mounted);
    final Element element = context;
    Element childElement;

    element.visitChildren((Element child) {
      childElement = child;
    });
    assert(childElement == null ||
        childElement is ParentDataElement<SliverWithKeepAliveWidget>);
    return childElement;
  }

  void _updateParentDataOfChild(
      ParentDataElement<SliverWithKeepAliveWidget> childElement) {
    childElement.applyWidgetOutOfTurn(build(context));
  }

  VoidCallback _createCallback(Listenable handle) {
    return () {
      assert(() {
        if (!mounted) {
          throw FlutterError(
              'AutomaticKeepAlive handle triggered after AutomaticKeepAlive was disposed.'
              'Widgets should always trigger their KeepAliveNotification handle when they are '
              'deactivated, so that they (or their handle) do not send spurious events later '
              'when they are no longer in the tree.');
        }
        return true;
      }());
      _handles.remove(handle);
      if (_handles.isEmpty) {
        if (SchedulerBinding.instance.schedulerPhase.index <
            SchedulerPhase.persistentCallbacks.index) {
          setState(() {
            _keepingAlive = false;
          });
        } else {
          _keepingAlive = false;
          scheduleMicrotask(() {
            if (mounted && _handles.isEmpty) {
              setState(() {
                assert(!_keepingAlive);
              });
            }
          });
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    assert(_child != null);
    return KeepAlive(
      keepAlive: _keepingAlive,
      child: _child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(FlagProperty('_keepingAlive',
        value: _keepingAlive, ifTrue: 'keeping subtree alive'));
    description.add(DiagnosticsProperty<Map<Listenable, VoidCallback>>(
      'handles',
      _handles,
      description: _handles != null
          ? '${_handles.length} active client${_handles.length == 1 ? "" : "s"}'
          : null,
      ifNull: 'no notifications ever received',
    ));
  }
}

class KeepAliveNotification extends Notification {
  const KeepAliveNotification(this.handle) : assert(handle != null);

  final Listenable handle;
}

class KeepAliveHandle extends ChangeNotifier {
  void release() {
    notifyListeners();
  }
}

@optionalTypeArgs
mixin AutomaticKeepAliveClientMixin<T extends StatefulWidget> on State<T> {
  KeepAliveHandle _keepAliveHandle;

  void _ensureKeepAlive() {
    assert(_keepAliveHandle == null);
    _keepAliveHandle = KeepAliveHandle();
    KeepAliveNotification(_keepAliveHandle).dispatch(context);
  }

  void _releaseKeepAlive() {
    _keepAliveHandle.release();
    _keepAliveHandle = null;
  }

  @protected
  bool get wantKeepAlive;

  @protected
  void updateKeepAlive() {
    if (wantKeepAlive) {
      if (_keepAliveHandle == null) _ensureKeepAlive();
    } else {
      if (_keepAliveHandle != null) _releaseKeepAlive();
    }
  }

  @override
  void initState() {
    super.initState();
    if (wantKeepAlive) _ensureKeepAlive();
  }

  @override
  void deactivate() {
    if (_keepAliveHandle != null) _releaseKeepAlive();
    super.deactivate();
  }

  @mustCallSuper
  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive && _keepAliveHandle == null) _ensureKeepAlive();
    return null;
  }
}

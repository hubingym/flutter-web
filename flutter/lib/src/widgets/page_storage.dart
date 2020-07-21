import 'framework.dart';

class PageStorageKey<T> extends ValueKey<T> {
  const PageStorageKey(T value) : super(value);
}

class _StorageEntryIdentifier {
  _StorageEntryIdentifier(this.keys) : assert(keys != null);

  final List<PageStorageKey<dynamic>> keys;

  bool get isNotEmpty => keys.isNotEmpty;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final _StorageEntryIdentifier typedOther = other;
    for (int index = 0; index < keys.length; index += 1) {
      if (keys[index] != typedOther.keys[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => hashList(keys);

  @override
  String toString() {
    return 'StorageEntryIdentifier(${keys?.join(":")})';
  }
}

class PageStorageBucket {
  static bool _maybeAddKey(
      BuildContext context, List<PageStorageKey<dynamic>> keys) {
    final Widget widget = context.widget;
    final Key key = widget.key;
    if (key is PageStorageKey) keys.add(key);
    return widget is! PageStorage;
  }

  List<PageStorageKey<dynamic>> _allKeys(BuildContext context) {
    final List<PageStorageKey<dynamic>> keys = <PageStorageKey<dynamic>>[];
    if (_maybeAddKey(context, keys)) {
      context.visitAncestorElements((Element element) {
        return _maybeAddKey(element, keys);
      });
    }
    return keys;
  }

  _StorageEntryIdentifier _computeIdentifier(BuildContext context) {
    return _StorageEntryIdentifier(_allKeys(context));
  }

  Map<Object, dynamic> _storage;

  void writeState(BuildContext context, dynamic data, {Object identifier}) {
    _storage ??= <Object, dynamic>{};
    if (identifier != null) {
      _storage[identifier] = data;
    } else {
      final _StorageEntryIdentifier contextIdentifier =
          _computeIdentifier(context);
      if (contextIdentifier.isNotEmpty) _storage[contextIdentifier] = data;
    }
  }

  dynamic readState(BuildContext context, {Object identifier}) {
    if (_storage == null) return null;
    if (identifier != null) return _storage[identifier];
    final _StorageEntryIdentifier contextIdentifier =
        _computeIdentifier(context);
    return contextIdentifier.isNotEmpty ? _storage[contextIdentifier] : null;
  }
}

class PageStorage extends StatelessWidget {
  const PageStorage({
    Key key,
    @required this.bucket,
    @required this.child,
  })  : assert(bucket != null),
        super(key: key);

  final Widget child;

  final PageStorageBucket bucket;

  static PageStorageBucket of(BuildContext context) {
    final PageStorage widget = context.ancestorWidgetOfExactType(PageStorage);
    return widget?.bucket;
  }

  @override
  Widget build(BuildContext context) => child;
}

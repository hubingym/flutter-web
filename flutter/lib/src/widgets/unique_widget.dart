import 'framework.dart';

abstract class UniqueWidget<T extends State<StatefulWidget>>
    extends StatefulWidget {
  const UniqueWidget({
    @required GlobalKey<T> key,
  })  : assert(key != null),
        super(key: key);

  @override
  T createState();

  T get currentState {
    final GlobalKey<T> globalKey = key;
    return globalKey.currentState;
  }
}

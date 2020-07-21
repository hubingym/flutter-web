import 'package:flutter_web/ui.dart' as ui;
import 'package:my_flutter_web/main.dart' as app;

void main() async {
  await ui.webOnlyInitializePlatform();
  app.main();
}

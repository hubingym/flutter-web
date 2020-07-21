import 'package:flutter_web/widgets.dart';

import 'icon_button.dart';
import 'icons.dart';
import 'material_localizations.dart';
import 'theme.dart';

class BackButtonIcon extends StatelessWidget {
  const BackButtonIcon({Key key}) : super(key: key);

  static IconData _getIconData(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return Icons.arrow_back;
      case TargetPlatform.iOS:
        return Icons.arrow_back_ios;
    }
    assert(false);
    return null;
  }

  @override
  Widget build(BuildContext context) =>
      Icon(_getIconData(Theme.of(context).platform));
}

class BackButton extends StatelessWidget {
  const BackButton({Key key, this.color}) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: const BackButtonIcon(),
        color: color,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () {
          Navigator.maybePop(context);
        });
  }
}

class CloseButton extends StatelessWidget {
  const CloseButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close),
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: () {
        Navigator.maybePop(context);
      },
    );
  }
}

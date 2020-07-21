import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'tabs.dart';
import 'theme.dart';

class TabBarTheme extends Diagnosticable {
  const TabBarTheme({
    this.indicator,
    this.indicatorSize,
    this.labelColor,
    this.labelStyle,
    this.unselectedLabelColor,
    this.unselectedLabelStyle,
  });

  final Decoration indicator;

  final TabBarIndicatorSize indicatorSize;

  final Color labelColor;

  final TextStyle labelStyle;

  final Color unselectedLabelColor;

  final TextStyle unselectedLabelStyle;

  TabBarTheme copyWith({
    Decoration indicator,
    TabBarIndicatorSize indicatorSize,
    Color labelColor,
    TextStyle labelStyle,
    Color unselectedLabelColor,
    TextStyle unselectedLabelStyle,
  }) {
    return TabBarTheme(
      indicator: indicator ?? this.indicator,
      indicatorSize: indicatorSize ?? this.indicatorSize,
      labelColor: labelColor ?? this.labelColor,
      labelStyle: labelStyle ?? this.labelStyle,
      unselectedLabelColor: unselectedLabelColor ?? this.unselectedLabelColor,
      unselectedLabelStyle: unselectedLabelStyle ?? this.unselectedLabelStyle,
    );
  }

  static TabBarTheme of(BuildContext context) {
    return Theme.of(context).tabBarTheme;
  }

  static TabBarTheme lerp(TabBarTheme a, TabBarTheme b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    return TabBarTheme(
      indicator: Decoration.lerp(a.indicator, b.indicator, t),
      indicatorSize: t < 0.5 ? a.indicatorSize : b.indicatorSize,
      labelColor: Color.lerp(a.labelColor, b.labelColor, t),
      labelStyle: TextStyle.lerp(a.labelStyle, b.labelStyle, t),
      unselectedLabelColor:
          Color.lerp(a.unselectedLabelColor, b.unselectedLabelColor, t),
      unselectedLabelStyle:
          TextStyle.lerp(a.unselectedLabelStyle, b.unselectedLabelStyle, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      indicator,
      indicatorSize,
      labelColor,
      labelStyle,
      unselectedLabelColor,
      unselectedLabelStyle,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final TabBarTheme typedOther = other;
    return typedOther.indicator == indicator &&
        typedOther.indicatorSize == indicatorSize &&
        typedOther.labelColor == labelColor &&
        typedOther.labelStyle == labelStyle &&
        typedOther.unselectedLabelColor == unselectedLabelColor &&
        typedOther.unselectedLabelStyle == unselectedLabelStyle;
  }
}

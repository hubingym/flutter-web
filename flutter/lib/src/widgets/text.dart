import 'package:flutter_web/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';

class DefaultTextStyle extends InheritedWidget {
  const DefaultTextStyle({
    Key key,
    @required this.style,
    this.textAlign,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    @required Widget child,
  })  : assert(style != null),
        assert(softWrap != null),
        assert(overflow != null),
        assert(maxLines == null || maxLines > 0),
        assert(child != null),
        super(key: key, child: child);

  const DefaultTextStyle.fallback()
      : style = const TextStyle(),
        textAlign = null,
        softWrap = true,
        maxLines = null,
        overflow = TextOverflow.clip;

  static Widget merge({
    Key key,
    TextStyle style,
    TextAlign textAlign,
    bool softWrap,
    TextOverflow overflow,
    int maxLines,
    @required Widget child,
  }) {
    assert(child != null);
    return Builder(
      builder: (BuildContext context) {
        final DefaultTextStyle parent = DefaultTextStyle.of(context);
        return DefaultTextStyle(
          key: key,
          style: parent.style.merge(style),
          textAlign: textAlign ?? parent.textAlign,
          softWrap: softWrap ?? parent.softWrap,
          overflow: overflow ?? parent.overflow,
          maxLines: maxLines ?? parent.maxLines,
          child: child,
        );
      },
    );
  }

  final TextStyle style;

  final TextAlign textAlign;

  final bool softWrap;

  final TextOverflow overflow;

  final int maxLines;

  static DefaultTextStyle of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(DefaultTextStyle) ??
        const DefaultTextStyle.fallback();
  }

  @override
  bool updateShouldNotify(DefaultTextStyle oldWidget) {
    return style != oldWidget.style ||
        textAlign != oldWidget.textAlign ||
        softWrap != oldWidget.softWrap ||
        overflow != oldWidget.overflow ||
        maxLines != oldWidget.maxLines;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    style?.debugFillProperties(properties);
    properties.add(
        EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(FlagProperty('softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
        ifFalse: 'no wrapping except at line break characters',
        showName: true));
    properties.add(
        EnumProperty<TextOverflow>('overflow', overflow, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: null));
  }
}

class Text extends StatelessWidget {
  const Text(
    this.data, {
    Key key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
  })  : assert(data != null),
        textSpan = null,
        super(key: key);

  const Text.rich(
    this.textSpan, {
    Key key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
  })  : assert(textSpan != null),
        data = null,
        super(key: key);

  final String data;

  final TextSpan textSpan;

  final TextStyle style;

  final TextAlign textAlign;

  final TextDirection textDirection;

  final Locale locale;

  final bool softWrap;

  final TextOverflow overflow;

  final double textScaleFactor;

  final int maxLines;

  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);
    TextStyle effectiveTextStyle = style;
    if (style == null || style.inherit)
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    if (MediaQuery.boldTextOverride(context))
      effectiveTextStyle = effectiveTextStyle
          .merge(const TextStyle(fontWeight: FontWeight.bold));
    Widget result = RichText(
      textAlign: textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap ?? defaultTextStyle.softWrap,
      overflow: overflow ?? defaultTextStyle.overflow,
      textScaleFactor: textScaleFactor ?? MediaQuery.textScaleFactorOf(context),
      maxLines: maxLines ?? defaultTextStyle.maxLines,
      text: TextSpan(
        style: effectiveTextStyle,
        text: data,
        children: textSpan != null ? <TextSpan>[textSpan] : null,
      ),
    );
    if (semanticsLabel != null) {
      result = Semantics(
          textDirection: textDirection,
          label: semanticsLabel,
          child: ExcludeSemantics(
            child: result,
          ));
    }
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('data', data, showName: false));
    if (textSpan != null) {
      properties.add(textSpan.toDiagnosticsNode(
          name: 'textSpan', style: DiagnosticsTreeStyle.transition));
    }
    style?.debugFillProperties(properties);
    properties.add(
        EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<Locale>('locale', locale, defaultValue: null));
    properties.add(FlagProperty('softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
        ifFalse: 'no wrapping except at line break characters',
        showName: true));
    properties.add(
        EnumProperty<TextOverflow>('overflow', overflow, defaultValue: null));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: null));
    if (semanticsLabel != null) {
      properties.add(StringProperty('semanticsLabel', semanticsLabel));
    }
  }
}

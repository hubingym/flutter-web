import 'dart:collection';
import 'dart:developer' show Timeline;

import 'basic.dart';
import 'framework.dart';
import 'media_query.dart';
import 'table.dart';

bool debugPrintRebuildDirtyWidgets = false;

typedef RebuildDirtyWidgetCallback = void Function(Element e, bool builtOnce);

RebuildDirtyWidgetCallback debugOnRebuildDirtyWidget;

bool debugPrintBuildScope = false;

bool debugPrintScheduleBuildForStacks = false;

bool debugPrintGlobalKeyedWidgetLifecycle = false;

bool debugProfileBuildsEnabled = false;

bool debugHighlightDeprecatedWidgets = false;

Key _firstNonUniqueKey(Iterable<Widget> widgets) {
  final Set<Key> keySet = HashSet<Key>();
  for (Widget widget in widgets) {
    assert(widget != null);
    if (widget.key == null) continue;
    if (!keySet.add(widget.key)) return widget.key;
  }
  return null;
}

bool debugChildrenHaveDuplicateKeys(Widget parent, Iterable<Widget> children) {
  assert(() {
    final Key nonUniqueKey = _firstNonUniqueKey(children);
    if (nonUniqueKey != null) {
      throw FlutterError('Duplicate keys found.\n'
          'If multiple keyed nodes exist as children of another node, they must have unique keys.\n'
          '$parent has multiple children with key $nonUniqueKey.');
    }
    return true;
  }());
  return false;
}

bool debugItemsHaveDuplicateKeys(Iterable<Widget> items) {
  assert(() {
    final Key nonUniqueKey = _firstNonUniqueKey(items);
    if (nonUniqueKey != null)
      throw FlutterError('Duplicate key found: $nonUniqueKey.');
    return true;
  }());
  return false;
}

bool debugCheckHasTable(BuildContext context) {
  assert(() {
    if (context.widget is! Table &&
        context.ancestorWidgetOfExactType(Table) == null) {
      final Element element = context;
      throw FlutterError('No Table widget found.\n'
          '${context.widget.runtimeType} widgets require a Table widget ancestor.\n'
          'The specific widget that could not find a Table ancestor was:\n'
          '  ${context.widget}\n'
          'The ownership chain for the affected widget is:\n'
          '  ${element.debugGetCreatorChain(10)}');
    }
    return true;
  }());
  return true;
}

bool debugCheckHasMediaQuery(BuildContext context) {
  assert(() {
    if (context.widget is! MediaQuery &&
        context.ancestorWidgetOfExactType(MediaQuery) == null) {
      final Element element = context;
      throw FlutterError('No MediaQuery widget found.\n'
          '${context.widget.runtimeType} widgets require a MediaQuery widget ancestor.\n'
          'The specific widget that could not find a MediaQuery ancestor was:\n'
          '  ${context.widget}\n'
          'The ownership chain for the affected widget is:\n'
          '  ${element.debugGetCreatorChain(10)}\n'
          'Typically, the MediaQuery widget is introduced by the MaterialApp or '
          'WidgetsApp widget at the top of your application widget tree.');
    }
    return true;
  }());
  return true;
}

bool debugCheckHasDirectionality(BuildContext context) {
  assert(() {
    if (context.widget is! Directionality &&
        context.ancestorWidgetOfExactType(Directionality) == null) {
      final Element element = context;
      throw FlutterError('No Directionality widget found.\n'
          '${context.widget.runtimeType} widgets require a Directionality widget ancestor.\n'
          'The specific widget that could not find a Directionality ancestor was:\n'
          '  ${context.widget}\n'
          'The ownership chain for the affected widget is:\n'
          '  ${element.debugGetCreatorChain(10)}\n'
          'Typically, the Directionality widget is introduced by the MaterialApp '
          'or WidgetsApp widget at the top of your application widget tree. It '
          'determines the ambient reading direction and is used, for example, to '
          'determine how to lay out text, how to interpret "start" and "end" '
          'values, and to resolve EdgeInsetsDirectional, '
          'AlignmentDirectional, and other *Directional objects.');
    }
    return true;
  }());
  return true;
}

void debugWidgetBuilderValue(Widget widget, Widget built) {
  assert(() {
    if (built == null) {
      throw FlutterError('A build function returned null.\n'
          'The offending widget is: $widget\n'
          'Build functions must never return null. '
          'To return an empty space that causes the building widget to fill available room, return "new Container()". '
          'To return an empty space that takes as little room as possible, return "new Container(width: 0.0, height: 0.0)".');
    }
    if (widget == built) {
      throw FlutterError('A build function returned context.widget.\n'
          'The offending widget is: $widget\n'
          'Build functions must never return their BuildContext parameter\'s widget or a child that contains "context.widget". '
          'Doing so introduces a loop in the widget tree that can cause the app to crash.');
    }
    return true;
  }());
}

bool debugAssertAllWidgetVarsUnset(String reason) {
  assert(() {
    if (debugPrintRebuildDirtyWidgets ||
        debugPrintBuildScope ||
        debugPrintScheduleBuildForStacks ||
        debugPrintGlobalKeyedWidgetLifecycle ||
        debugProfileBuildsEnabled ||
        debugHighlightDeprecatedWidgets) {
      throw FlutterError(reason);
    }
    return true;
  }());
  return true;
}

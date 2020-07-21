import 'dart:collection';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/semantics.dart';

import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';
import 'proxy_box.dart';

typedef SemanticsBuilderCallback = List<CustomPainterSemantics> Function(
    Size size);

abstract class CustomPainter extends Listenable {
  const CustomPainter({Listenable repaint}) : _repaint = repaint;

  final Listenable _repaint;

  @override
  void addListener(VoidCallback listener) => _repaint?.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _repaint?.removeListener(listener);

  void paint(Canvas canvas, Size size);

  SemanticsBuilderCallback get semanticsBuilder => null;

  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) =>
      shouldRepaint(oldDelegate);

  bool shouldRepaint(covariant CustomPainter oldDelegate);

  bool hitTest(Offset position) => null;

  @override
  String toString() =>
      '${describeIdentity(this)}(${_repaint?.toString() ?? ""})';
}

@immutable
class CustomPainterSemantics {
  const CustomPainterSemantics({
    this.key,
    @required this.rect,
    @required this.properties,
    this.transform,
    this.tags,
  })  : assert(rect != null),
        assert(properties != null);

  final Key key;

  final Rect rect;

  final Matrix4 transform;

  final SemanticsProperties properties;

  final Set<SemanticsTag> tags;
}

class RenderCustomPaint extends RenderProxyBox {
  RenderCustomPaint({
    CustomPainter painter,
    CustomPainter foregroundPainter,
    Size preferredSize = Size.zero,
    this.isComplex = false,
    this.willChange = false,
    RenderBox child,
  })  : assert(preferredSize != null),
        _painter = painter,
        _foregroundPainter = foregroundPainter,
        _preferredSize = preferredSize,
        super(child);

  CustomPainter get painter => _painter;
  CustomPainter _painter;

  set painter(CustomPainter value) {
    if (_painter == value) return;
    final CustomPainter oldPainter = _painter;
    _painter = value;
    _didUpdatePainter(_painter, oldPainter);
  }

  CustomPainter get foregroundPainter => _foregroundPainter;
  CustomPainter _foregroundPainter;

  set foregroundPainter(CustomPainter value) {
    if (_foregroundPainter == value) return;
    final CustomPainter oldPainter = _foregroundPainter;
    _foregroundPainter = value;
    _didUpdatePainter(_foregroundPainter, oldPainter);
  }

  void _didUpdatePainter(CustomPainter newPainter, CustomPainter oldPainter) {
    if (newPainter == null) {
      assert(oldPainter != null);
      markNeedsPaint();
    } else if (oldPainter == null ||
        newPainter.runtimeType != oldPainter.runtimeType ||
        newPainter.shouldRepaint(oldPainter)) {
      markNeedsPaint();
    }
    if (attached) {
      oldPainter?.removeListener(markNeedsPaint);
      newPainter?.addListener(markNeedsPaint);
    }

    if (newPainter == null) {
      assert(oldPainter != null);
      if (attached) markNeedsSemanticsUpdate();
    } else if (oldPainter == null ||
        newPainter.runtimeType != oldPainter.runtimeType ||
        newPainter.shouldRebuildSemantics(oldPainter)) {
      markNeedsSemanticsUpdate();
    }
  }

  Size get preferredSize => _preferredSize;
  Size _preferredSize;
  set preferredSize(Size value) {
    assert(value != null);
    if (preferredSize == value) return;
    _preferredSize = value;
    markNeedsLayout();
  }

  bool isComplex;

  bool willChange;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _painter?.addListener(markNeedsPaint);
    _foregroundPainter?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _painter?.removeListener(markNeedsPaint);
    _foregroundPainter?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    if (_foregroundPainter != null &&
        (_foregroundPainter.hitTest(position) ?? false)) return true;
    return super.hitTestChildren(result, position: position);
  }

  @override
  bool hitTestSelf(Offset position) {
    return _painter != null && (_painter.hitTest(position) ?? true);
  }

  @override
  void performResize() {
    size = constraints.constrain(preferredSize);
    markNeedsSemanticsUpdate();
  }

  void _paintWithPainter(Canvas canvas, Offset offset, CustomPainter painter) {
    int debugPreviousCanvasSaveCount;
    canvas.save();
    assert(() {
      debugPreviousCanvasSaveCount = canvas.getSaveCount();
      return true;
    }());
    if (offset != Offset.zero) canvas.translate(offset.dx, offset.dy);
    painter.paint(canvas, size);
    assert(() {
      final int debugNewCanvasSaveCount = canvas.getSaveCount();
      if (debugNewCanvasSaveCount > debugPreviousCanvasSaveCount) {
        throw FlutterError(
            'The $painter custom painter called canvas.save() or canvas.saveLayer() at least '
            '${debugNewCanvasSaveCount - debugPreviousCanvasSaveCount} more '
            'time${debugNewCanvasSaveCount - debugPreviousCanvasSaveCount == 1 ? '' : 's'} '
            'than it called canvas.restore().\n'
            'This leaves the canvas in an inconsistent state and will probably result in a broken display.\n'
            'You must pair each call to save()/saveLayer() with a later matching call to restore().');
      }
      if (debugNewCanvasSaveCount < debugPreviousCanvasSaveCount) {
        throw FlutterError(
            'The $painter custom painter called canvas.restore() '
            '${debugPreviousCanvasSaveCount - debugNewCanvasSaveCount} more '
            'time${debugPreviousCanvasSaveCount - debugNewCanvasSaveCount == 1 ? '' : 's'} '
            'than it called canvas.save() or canvas.saveLayer().\n'
            'This leaves the canvas in an inconsistent state and will result in a broken display.\n'
            'You should only call restore() if you first called save() or saveLayer().');
      }
      return debugNewCanvasSaveCount == debugPreviousCanvasSaveCount;
    }());
    canvas.restore();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_painter != null) {
      _paintWithPainter(context.canvas, offset, _painter);
      _setRasterCacheHints(context);
    }
    super.paint(context, offset);
    if (_foregroundPainter != null) {
      _paintWithPainter(context.canvas, offset, _foregroundPainter);
      _setRasterCacheHints(context);
    }
  }

  void _setRasterCacheHints(PaintingContext context) {
    if (isComplex) context.setIsComplexHint();
    if (willChange) context.setWillChangeHint();
  }

  SemanticsBuilderCallback _backgroundSemanticsBuilder;

  SemanticsBuilderCallback _foregroundSemanticsBuilder;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    _backgroundSemanticsBuilder = painter?.semanticsBuilder;
    _foregroundSemanticsBuilder = foregroundPainter?.semanticsBuilder;
    config.isSemanticBoundary = _backgroundSemanticsBuilder != null ||
        _foregroundSemanticsBuilder != null;
  }

  List<SemanticsNode> _backgroundSemanticsNodes;

  List<SemanticsNode> _foregroundSemanticsNodes;

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    assert(() {
      if (child == null && children.isNotEmpty) {
        throw FlutterError(
            '$runtimeType does not have a child widget but received a non-empty list of child SemanticsNode:\n'
            '${children.join('\n')}');
      }
      return true;
    }());

    final List<CustomPainterSemantics> backgroundSemantics =
        _backgroundSemanticsBuilder != null
            ? _backgroundSemanticsBuilder(size)
            : const <CustomPainterSemantics>[];
    _backgroundSemanticsNodes = _updateSemanticsChildren(
        _backgroundSemanticsNodes, backgroundSemantics);

    final List<CustomPainterSemantics> foregroundSemantics =
        _foregroundSemanticsBuilder != null
            ? _foregroundSemanticsBuilder(size)
            : const <CustomPainterSemantics>[];
    _foregroundSemanticsNodes = _updateSemanticsChildren(
        _foregroundSemanticsNodes, foregroundSemantics);

    final bool hasBackgroundSemantics = _backgroundSemanticsNodes != null &&
        _backgroundSemanticsNodes.isNotEmpty;
    final bool hasForegroundSemantics = _foregroundSemanticsNodes != null &&
        _foregroundSemanticsNodes.isNotEmpty;
    final List<SemanticsNode> finalChildren = <SemanticsNode>[];
    if (hasBackgroundSemantics) finalChildren.addAll(_backgroundSemanticsNodes);
    finalChildren.addAll(children);
    if (hasForegroundSemantics) finalChildren.addAll(_foregroundSemanticsNodes);
    super.assembleSemanticsNode(node, config, finalChildren);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _backgroundSemanticsNodes = null;
    _foregroundSemanticsNodes = null;
  }

  static List<SemanticsNode> _updateSemanticsChildren(
    List<SemanticsNode> oldSemantics,
    List<CustomPainterSemantics> newChildSemantics,
  ) {
    oldSemantics = oldSemantics ?? const <SemanticsNode>[];
    newChildSemantics = newChildSemantics ?? const <CustomPainterSemantics>[];

    assert(() {
      final Map<Key, int> keys = HashMap<Key, int>();
      final StringBuffer errors = StringBuffer();
      for (int i = 0; i < newChildSemantics.length; i += 1) {
        final CustomPainterSemantics child = newChildSemantics[i];
        if (child.key != null) {
          if (keys.containsKey(child.key)) {
            errors.writeln(
              '- duplicate key ${child.key} found at position $i',
            );
          }
          keys[child.key] = i;
        }
      }

      if (errors.isNotEmpty) {
        throw FlutterError(
            'Failed to update the list of CustomPainterSemantics:\n'
            '$errors');
      }

      return true;
    }());

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newChildSemantics.length - 1;
    int oldChildrenBottom = oldSemantics.length - 1;

    final List<SemanticsNode> newChildren =
        List<SemanticsNode>(newChildSemantics.length);

    while ((oldChildrenTop <= oldChildrenBottom) &&
        (newChildrenTop <= newChildrenBottom)) {
      final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
      final CustomPainterSemantics newSemantics =
          newChildSemantics[newChildrenTop];
      if (!_canUpdateSemanticsChild(oldChild, newSemantics)) break;
      final SemanticsNode newChild =
          _updateSemanticsChild(oldChild, newSemantics);
      newChildren[newChildrenTop] = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    while ((oldChildrenTop <= oldChildrenBottom) &&
        (newChildrenTop <= newChildrenBottom)) {
      final SemanticsNode oldChild = oldSemantics[oldChildrenBottom];
      final CustomPainterSemantics newChild =
          newChildSemantics[newChildrenBottom];
      if (!_canUpdateSemanticsChild(oldChild, newChild)) break;
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    final bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    Map<Key, SemanticsNode> oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = <Key, SemanticsNode>{};
      while (oldChildrenTop <= oldChildrenBottom) {
        final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
        if (oldChild.key != null) oldKeyedChildren[oldChild.key] = oldChild;
        oldChildrenTop += 1;
      }
    }

    while (newChildrenTop <= newChildrenBottom) {
      SemanticsNode oldChild;
      final CustomPainterSemantics newSemantics =
          newChildSemantics[newChildrenTop];
      if (haveOldChildren) {
        final Key key = newSemantics.key;
        if (key != null) {
          oldChild = oldKeyedChildren[key];
          if (oldChild != null) {
            if (_canUpdateSemanticsChild(oldChild, newSemantics)) {
              oldKeyedChildren.remove(key);
            } else {
              oldChild = null;
            }
          }
        }
      }
      assert(
          oldChild == null || _canUpdateSemanticsChild(oldChild, newSemantics));
      final SemanticsNode newChild =
          _updateSemanticsChild(oldChild, newSemantics);
      assert(oldChild == newChild || oldChild == null);
      newChildren[newChildrenTop] = newChild;
      newChildrenTop += 1;
    }

    assert(oldChildrenTop == oldChildrenBottom + 1);
    assert(newChildrenTop == newChildrenBottom + 1);
    assert(newChildSemantics.length - newChildrenTop ==
        oldSemantics.length - oldChildrenTop);
    newChildrenBottom = newChildSemantics.length - 1;
    oldChildrenBottom = oldSemantics.length - 1;

    while ((oldChildrenTop <= oldChildrenBottom) &&
        (newChildrenTop <= newChildrenBottom)) {
      final SemanticsNode oldChild = oldSemantics[oldChildrenTop];
      final CustomPainterSemantics newSemantics =
          newChildSemantics[newChildrenTop];
      assert(_canUpdateSemanticsChild(oldChild, newSemantics));
      final SemanticsNode newChild =
          _updateSemanticsChild(oldChild, newSemantics);
      assert(oldChild == newChild);
      newChildren[newChildrenTop] = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    assert(() {
      for (SemanticsNode node in newChildren) {
        assert(node != null);
      }
      return true;
    }());

    return newChildren;
  }

  static bool _canUpdateSemanticsChild(
      SemanticsNode oldChild, CustomPainterSemantics newSemantics) {
    return oldChild.key == newSemantics.key;
  }

  static SemanticsNode _updateSemanticsChild(
      SemanticsNode oldChild, CustomPainterSemantics newSemantics) {
    assert(
        oldChild == null || _canUpdateSemanticsChild(oldChild, newSemantics));

    final SemanticsNode newChild = oldChild ??
        SemanticsNode(
          key: newSemantics.key,
        );

    final SemanticsProperties properties = newSemantics.properties;
    final SemanticsConfiguration config = SemanticsConfiguration();
    if (properties.sortKey != null) {
      config.sortKey = properties.sortKey;
    }
    if (properties.checked != null) {
      config.isChecked = properties.checked;
    }
    if (properties.selected != null) {
      config.isSelected = properties.selected;
    }
    if (properties.button != null) {
      config.isButton = properties.button;
    }
    if (properties.textField != null) {
      config.isTextField = properties.textField;
    }
    if (properties.focused != null) {
      config.isFocused = properties.focused;
    }
    if (properties.enabled != null) {
      config.isEnabled = properties.enabled;
    }
    if (properties.inMutuallyExclusiveGroup != null) {
      config.isInMutuallyExclusiveGroup = properties.inMutuallyExclusiveGroup;
    }
    if (properties.obscured != null) {
      config.isObscured = properties.obscured;
    }
    if (properties.hidden != null) {
      config.isHidden = properties.hidden;
    }
    if (properties.header != null) {
      config.isHeader = properties.header;
    }
    if (properties.scopesRoute != null) {
      config.scopesRoute = properties.scopesRoute;
    }
    if (properties.namesRoute != null) {
      config.namesRoute = properties.namesRoute;
    }
    if (properties.liveRegion != null) {
      config.liveRegion = properties.liveRegion;
    }
    if (properties.toggled != null) {
      config.isToggled = properties.toggled;
    }
    if (properties.image != null) {
      config.isImage = properties.image;
    }
    if (properties.label != null) {
      config.label = properties.label;
    }
    if (properties.value != null) {
      config.value = properties.value;
    }
    if (properties.increasedValue != null) {
      config.increasedValue = properties.increasedValue;
    }
    if (properties.decreasedValue != null) {
      config.decreasedValue = properties.decreasedValue;
    }
    if (properties.hint != null) {
      config.hint = properties.hint;
    }
    if (properties.textDirection != null) {
      config.textDirection = properties.textDirection;
    }
    if (properties.onTap != null) {
      config.onTap = properties.onTap;
    }
    if (properties.onLongPress != null) {
      config.onLongPress = properties.onLongPress;
    }
    if (properties.onScrollLeft != null) {
      config.onScrollLeft = properties.onScrollLeft;
    }
    if (properties.onScrollRight != null) {
      config.onScrollRight = properties.onScrollRight;
    }
    if (properties.onScrollUp != null) {
      config.onScrollUp = properties.onScrollUp;
    }
    if (properties.onScrollDown != null) {
      config.onScrollDown = properties.onScrollDown;
    }
    if (properties.onIncrease != null) {
      config.onIncrease = properties.onIncrease;
    }
    if (properties.onDecrease != null) {
      config.onDecrease = properties.onDecrease;
    }
    if (properties.onCopy != null) {
      config.onCopy = properties.onCopy;
    }
    if (properties.onCut != null) {
      config.onCut = properties.onCut;
    }
    if (properties.onPaste != null) {
      config.onPaste = properties.onPaste;
    }
    if (properties.onMoveCursorForwardByCharacter != null) {
      config.onMoveCursorForwardByCharacter =
          properties.onMoveCursorForwardByCharacter;
    }
    if (properties.onMoveCursorBackwardByCharacter != null) {
      config.onMoveCursorBackwardByCharacter =
          properties.onMoveCursorBackwardByCharacter;
    }
    if (properties.onSetSelection != null) {
      config.onSetSelection = properties.onSetSelection;
    }
    if (properties.onDidGainAccessibilityFocus != null) {
      config.onDidGainAccessibilityFocus =
          properties.onDidGainAccessibilityFocus;
    }
    if (properties.onDidLoseAccessibilityFocus != null) {
      config.onDidLoseAccessibilityFocus =
          properties.onDidLoseAccessibilityFocus;
    }
    if (properties.onDismiss != null) {
      config.onDismiss = properties.onDismiss;
    }

    newChild.updateWith(
      config: config,
      childrenInInversePaintOrder: const <SemanticsNode>[],
    );

    newChild
      ..rect = newSemantics.rect
      ..transform = newSemantics.transform
      ..tags = newSemantics.tags;

    return newChild;
  }
}

import 'dart:math' as math;
import 'package:flutter_web/ui.dart' show SemanticsFlag;
import 'package:flutter_web/ui.dart' as ui show window;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/rendering.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'gesture_detector.dart';

class SemanticsDebugger extends StatefulWidget {
  const SemanticsDebugger({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  _SemanticsDebuggerState createState() => _SemanticsDebuggerState();
}

class _SemanticsDebuggerState extends State<SemanticsDebugger>
    with WidgetsBindingObserver {
  _SemanticsClient _client;

  @override
  void initState() {
    super.initState();

    _client = _SemanticsClient(WidgetsBinding.instance.pipelineOwner)
      ..addListener(_update);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _client
      ..removeListener(_update)
      ..dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  void _update() {
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      if (mounted) {
        setState(() {});
        SchedulerBinding.instance.scheduleFrame();
      }
    });
  }

  Offset _lastPointerDownLocation;
  void _handlePointerDown(PointerDownEvent event) {
    setState(() {
      _lastPointerDownLocation = event.position * ui.window.devicePixelRatio;
    });
  }

  void _handleTap() {
    assert(_lastPointerDownLocation != null);
    _performAction(_lastPointerDownLocation, SemanticsAction.tap);
    setState(() {
      _lastPointerDownLocation = null;
    });
  }

  void _handleLongPress() {
    assert(_lastPointerDownLocation != null);
    _performAction(_lastPointerDownLocation, SemanticsAction.longPress);
    setState(() {
      _lastPointerDownLocation = null;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final double vx = details.velocity.pixelsPerSecond.dx;
    final double vy = details.velocity.pixelsPerSecond.dy;
    if (vx.abs() == vy.abs()) return;
    if (vx.abs() > vy.abs()) {
      if (vx.sign < 0) {
        _performAction(_lastPointerDownLocation, SemanticsAction.decrease);
        _performAction(_lastPointerDownLocation, SemanticsAction.scrollLeft);
      } else {
        _performAction(_lastPointerDownLocation, SemanticsAction.increase);
        _performAction(_lastPointerDownLocation, SemanticsAction.scrollRight);
      }
    } else {
      if (vy.sign < 0)
        _performAction(_lastPointerDownLocation, SemanticsAction.scrollUp);
      else
        _performAction(_lastPointerDownLocation, SemanticsAction.scrollDown);
    }
    setState(() {
      _lastPointerDownLocation = null;
    });
  }

  void _performAction(Offset position, SemanticsAction action) {
    _pipelineOwner.semanticsOwner?.performActionAt(position, action);
  }

  PipelineOwner get _pipelineOwner => WidgetsBinding.instance.pipelineOwner;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _SemanticsDebuggerPainter(
        _pipelineOwner,
        _client.generation,
        _lastPointerDownLocation,
        ui.window.devicePixelRatio,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        onPanEnd: _handlePanEnd,
        excludeFromSemantics: true,
        child: Listener(
          onPointerDown: _handlePointerDown,
          behavior: HitTestBehavior.opaque,
          child: IgnorePointer(
            ignoringSemantics: false,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _SemanticsClient extends ChangeNotifier {
  _SemanticsClient(PipelineOwner pipelineOwner) {
    _semanticsHandle =
        pipelineOwner.ensureSemantics(listener: _didUpdateSemantics);
  }

  SemanticsHandle _semanticsHandle;

  @override
  void dispose() {
    _semanticsHandle.dispose();
    _semanticsHandle = null;
    super.dispose();
  }

  int generation = 0;

  void _didUpdateSemantics() {
    generation += 1;
    notifyListeners();
  }
}

String _getMessage(SemanticsNode node) {
  final SemanticsData data = node.getSemanticsData();
  final List<String> annotations = <String>[];

  bool wantsTap = false;
  if (data.hasFlag(SemanticsFlag.hasCheckedState)) {
    annotations
        .add(data.hasFlag(SemanticsFlag.isChecked) ? 'checked' : 'unchecked');
    wantsTap = true;
  }

  if (data.hasAction(SemanticsAction.tap)) {
    if (!wantsTap) annotations.add('button');
  } else {
    if (wantsTap) annotations.add('disabled');
  }

  if (data.hasAction(SemanticsAction.longPress))
    annotations.add('long-pressable');

  final bool isScrollable = data.hasAction(SemanticsAction.scrollLeft) ||
      data.hasAction(SemanticsAction.scrollRight) ||
      data.hasAction(SemanticsAction.scrollUp) ||
      data.hasAction(SemanticsAction.scrollDown);

  final bool isAdjustable = data.hasAction(SemanticsAction.increase) ||
      data.hasAction(SemanticsAction.decrease);

  if (isScrollable) annotations.add('scrollable');

  if (isAdjustable) annotations.add('adjustable');

  assert(data.label != null);
  String message;
  if (data.label.isEmpty) {
    message = annotations.join('; ');
  } else {
    String label;
    if (data.textDirection == null) {
      label = '${Unicode.FSI}${data.label}${Unicode.PDI}';
      annotations.insert(0, 'MISSING TEXT DIRECTION');
    } else {
      switch (data.textDirection) {
        case TextDirection.rtl:
          label = '${Unicode.RLI}${data.label}${Unicode.PDF}';
          break;
        case TextDirection.ltr:
          label = data.label;
          break;
      }
    }
    if (annotations.isEmpty) {
      message = label;
    } else {
      message = '$label (${annotations.join('; ')})';
    }
  }

  return message.trim();
}

const TextStyle _messageStyle =
    TextStyle(color: Color(0xFF000000), fontSize: 10.0, height: 0.8);

void _paintMessage(Canvas canvas, SemanticsNode node) {
  final String message = _getMessage(node);
  if (message.isEmpty) return;
  final Rect rect = node.rect;
  canvas.save();
  canvas.clipRect(rect);
  final TextPainter textPainter = TextPainter()
    ..text = TextSpan(
      style: _messageStyle,
      text: message,
    )
    ..textDirection = TextDirection.ltr
    ..textAlign = TextAlign.center
    ..layout(maxWidth: rect.width);

  textPainter.paint(
      canvas, Alignment.center.inscribe(textPainter.size, rect).topLeft);
  canvas.restore();
}

int _findDepth(SemanticsNode node) {
  if (!node.hasChildren || node.mergeAllDescendantsIntoThisNode) return 1;
  int childrenDepth = 0;
  node.visitChildren((SemanticsNode child) {
    childrenDepth = math.max(childrenDepth, _findDepth(child));
    return true;
  });
  return childrenDepth + 1;
}

void _paint(Canvas canvas, SemanticsNode node, int rank) {
  canvas.save();
  if (node.transform != null) canvas.transform(node.transform.storage);
  final Rect rect = node.rect;
  if (!rect.isEmpty) {
    final Color lineColor =
        Color(0xFF000000 + math.Random(node.id).nextInt(0xFFFFFF));
    final Rect innerRect = rect.deflate(rank * 1.0);
    if (innerRect.isEmpty) {
      final Paint fill = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fill);
    } else {
      final Paint fill = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fill);
      final Paint line = Paint()
        ..strokeWidth = rank * 2.0
        ..color = lineColor
        ..style = PaintingStyle.stroke;
      canvas.drawRect(innerRect, line);
    }
    _paintMessage(canvas, node);
  }
  if (!node.mergeAllDescendantsIntoThisNode) {
    final int childRank = rank - 1;
    node.visitChildren((SemanticsNode child) {
      _paint(canvas, child, childRank);
      return true;
    });
  }
  canvas.restore();
}

class _SemanticsDebuggerPainter extends CustomPainter {
  const _SemanticsDebuggerPainter(
      this.owner, this.generation, this.pointerPosition, this.devicePixelRatio);

  final PipelineOwner owner;
  final int generation;
  final Offset pointerPosition;
  final double devicePixelRatio;

  SemanticsNode get _rootSemanticsNode {
    return owner.semanticsOwner?.rootSemanticsNode;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final SemanticsNode rootNode = _rootSemanticsNode;
    canvas.save();
    canvas.scale(1.0 / devicePixelRatio, 1.0 / devicePixelRatio);
    if (rootNode != null) _paint(canvas, rootNode, _findDepth(rootNode));
    if (pointerPosition != null) {
      final Paint paint = Paint();
      paint.color = const Color(0x7F0090FF);
      canvas.drawCircle(pointerPosition, 10.0 * devicePixelRatio, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SemanticsDebuggerPainter oldDelegate) {
    return owner != oldDelegate.owner ||
        generation != oldDelegate.generation ||
        pointerPosition != oldDelegate.pointerPosition;
  }
}

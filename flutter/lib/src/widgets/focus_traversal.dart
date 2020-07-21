import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart';

import 'basic.dart';
import 'binding.dart';
import 'focus_manager.dart';
import 'framework.dart';

enum TraversalDirection {
  up,

  right,

  down,

  left,
}

abstract class FocusTraversalPolicy {
  FocusNode findFirstFocus(FocusNode currentNode);

  FocusNode findFirstFocusInDirection(
      FocusNode currentNode, TraversalDirection direction);

  @mustCallSuper
  @protected
  void invalidateScopeData(FocusScopeNode node) {}

  @mustCallSuper
  void changedScope({FocusNode node, FocusScopeNode oldScope}) {}

  bool next(FocusNode currentNode);

  bool previous(FocusNode currentNode);

  bool inDirection(FocusNode currentNode, TraversalDirection direction);
}

class _DirectionalPolicyDataEntry {
  const _DirectionalPolicyDataEntry(
      {@required this.direction, @required this.node})
      : assert(direction != null),
        assert(node != null);

  final TraversalDirection direction;
  final FocusNode node;
}

class _DirectionalPolicyData {
  const _DirectionalPolicyData({@required this.history})
      : assert(history != null);

  final List<_DirectionalPolicyDataEntry> history;
}

mixin DirectionalFocusTraversalPolicyMixin on FocusTraversalPolicy {
  final Map<FocusScopeNode, _DirectionalPolicyData> _policyData =
      <FocusScopeNode, _DirectionalPolicyData>{};

  @override
  void invalidateScopeData(FocusScopeNode node) {
    super.invalidateScopeData(node);
    _policyData.remove(node);
  }

  @override
  void changedScope({FocusNode node, FocusScopeNode oldScope}) {
    super.changedScope(node: node, oldScope: oldScope);
    if (oldScope != null) {
      _policyData[oldScope]
          ?.history
          ?.removeWhere((_DirectionalPolicyDataEntry entry) {
        return entry.node == node;
      });
    }
  }

  @override
  FocusNode findFirstFocusInDirection(
      FocusNode currentNode, TraversalDirection direction) {
    assert(direction != null);
    assert(currentNode != null);
    switch (direction) {
      case TraversalDirection.up:
        return _sortAndFindInitial(currentNode, vertical: true, first: false);
      case TraversalDirection.down:
        return _sortAndFindInitial(currentNode, vertical: true, first: true);
      case TraversalDirection.left:
        return _sortAndFindInitial(currentNode, vertical: false, first: false);
      case TraversalDirection.right:
        return _sortAndFindInitial(currentNode, vertical: false, first: true);
    }
    return null;
  }

  FocusNode _sortAndFindInitial(FocusNode currentNode,
      {bool vertical, bool first}) {
    final Iterable<FocusNode> nodes =
        currentNode.nearestScope.traversalDescendants;
    final List<FocusNode> sorted = nodes.toList();
    sorted.sort((FocusNode a, FocusNode b) {
      if (vertical) {
        if (first) {
          return a.rect.top.compareTo(b.rect.top);
        } else {
          return b.rect.bottom.compareTo(a.rect.bottom);
        }
      } else {
        if (first) {
          return a.rect.left.compareTo(b.rect.left);
        } else {
          return b.rect.right.compareTo(a.rect.right);
        }
      }
    });
    return sorted.first;
  }

  Iterable<FocusNode> _sortAndFilterHorizontally(
    TraversalDirection direction,
    Rect target,
    FocusNode nearestScope,
  ) {
    assert(direction == TraversalDirection.left ||
        direction == TraversalDirection.right);
    final Iterable<FocusNode> nodes = nearestScope.traversalDescendants;
    assert(!nodes.contains(nearestScope));
    final List<FocusNode> sorted = nodes.toList();
    sorted.sort((FocusNode a, FocusNode b) =>
        a.rect.center.dx.compareTo(b.rect.center.dx));
    Iterable<FocusNode> result;
    switch (direction) {
      case TraversalDirection.left:
        result = sorted.where((FocusNode node) =>
            node.rect != target && node.rect.center.dx <= target.left);
        break;
      case TraversalDirection.right:
        result = sorted.where((FocusNode node) =>
            node.rect != target && node.rect.center.dx >= target.right);
        break;
      case TraversalDirection.up:
      case TraversalDirection.down:
        break;
    }
    return result;
  }

  Iterable<FocusNode> _sortAndFilterVertically(
    TraversalDirection direction,
    Rect target,
    Iterable<FocusNode> nodes,
  ) {
    final List<FocusNode> sorted = nodes.toList();
    sorted.sort((FocusNode a, FocusNode b) =>
        a.rect.center.dy.compareTo(b.rect.center.dy));
    switch (direction) {
      case TraversalDirection.up:
        return sorted.where((FocusNode node) =>
            node.rect != target && node.rect.center.dy <= target.top);
      case TraversalDirection.down:
        return sorted.where((FocusNode node) =>
            node.rect != target && node.rect.center.dy >= target.bottom);
      case TraversalDirection.left:
      case TraversalDirection.right:
        break;
    }
    assert(direction == TraversalDirection.up ||
        direction == TraversalDirection.down);
    return null;
  }

  bool _popPolicyDataIfNeeded(TraversalDirection direction,
      FocusScopeNode nearestScope, FocusNode focusedChild) {
    final _DirectionalPolicyData policyData = _policyData[nearestScope];
    if (policyData != null &&
        policyData.history.isNotEmpty &&
        policyData.history.first.direction != direction) {
      switch (direction) {
        case TraversalDirection.down:
        case TraversalDirection.up:
          switch (policyData.history.first.direction) {
            case TraversalDirection.left:
            case TraversalDirection.right:
              invalidateScopeData(nearestScope);
              break;
            case TraversalDirection.up:
            case TraversalDirection.down:
              policyData.history.removeLast().node.requestFocus();
              return true;
          }
          break;
        case TraversalDirection.left:
        case TraversalDirection.right:
          switch (policyData.history.first.direction) {
            case TraversalDirection.left:
            case TraversalDirection.right:
              policyData.history.removeLast().node.requestFocus();
              return true;
            case TraversalDirection.up:
            case TraversalDirection.down:
              invalidateScopeData(nearestScope);
              break;
          }
      }
    }
    if (policyData != null && policyData.history.isEmpty) {
      invalidateScopeData(nearestScope);
    }
    return false;
  }

  void _pushPolicyData(TraversalDirection direction,
      FocusScopeNode nearestScope, FocusNode focusedChild) {
    final _DirectionalPolicyData policyData = _policyData[nearestScope];
    if (policyData != null && policyData is! _DirectionalPolicyData) {
      return;
    }
    final _DirectionalPolicyDataEntry newEntry =
        _DirectionalPolicyDataEntry(node: focusedChild, direction: direction);
    if (policyData != null) {
      policyData.history.add(newEntry);
    } else {
      _policyData[nearestScope] = _DirectionalPolicyData(
          history: <_DirectionalPolicyDataEntry>[newEntry]);
    }
  }

  @mustCallSuper
  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final FocusScopeNode nearestScope = currentNode.nearestScope;
    final FocusNode focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      final FocusNode firstFocus =
          findFirstFocusInDirection(currentNode, direction);
      (firstFocus ?? currentNode).requestFocus();
      return true;
    }
    if (_popPolicyDataIfNeeded(direction, nearestScope, focusedChild)) {
      return true;
    }
    FocusNode found;
    switch (direction) {
      case TraversalDirection.down:
      case TraversalDirection.up:
        final Iterable<FocusNode> eligibleNodes = _sortAndFilterVertically(
          direction,
          focusedChild.rect,
          nearestScope.traversalDescendants,
        );
        if (eligibleNodes.isEmpty) {
          break;
        }
        List<FocusNode> sorted = eligibleNodes.toList();
        if (direction == TraversalDirection.up) {
          sorted = sorted.reversed.toList();
        }

        final Rect band = Rect.fromLTRB(focusedChild.rect.left,
            -double.infinity, focusedChild.rect.right, double.infinity);
        final Iterable<FocusNode> inBand = sorted
            .where((FocusNode node) => !node.rect.intersect(band).isEmpty);
        if (inBand.isNotEmpty) {
          found = inBand.first;
          break;
        }

        sorted.sort((FocusNode a, FocusNode b) {
          return (a.rect.center.dx - focusedChild.rect.center.dx)
              .abs()
              .compareTo(
                  (b.rect.center.dx - focusedChild.rect.center.dx).abs());
        });
        found = sorted.first;
        break;
      case TraversalDirection.right:
      case TraversalDirection.left:
        final Iterable<FocusNode> eligibleNodes = _sortAndFilterHorizontally(
            direction, focusedChild.rect, nearestScope);
        if (eligibleNodes.isEmpty) {
          break;
        }
        List<FocusNode> sorted = eligibleNodes.toList();
        if (direction == TraversalDirection.left) {
          sorted = sorted.reversed.toList();
        }

        final Rect band = Rect.fromLTRB(-double.infinity, focusedChild.rect.top,
            double.infinity, focusedChild.rect.bottom);
        final Iterable<FocusNode> inBand = sorted
            .where((FocusNode node) => !node.rect.intersect(band).isEmpty);
        if (inBand.isNotEmpty) {
          found = inBand.first;
          break;
        }

        sorted.sort((FocusNode a, FocusNode b) {
          return (a.rect.center.dy - focusedChild.rect.center.dy)
              .abs()
              .compareTo(
                  (b.rect.center.dy - focusedChild.rect.center.dy).abs());
        });
        found = sorted.first;
        break;
    }
    if (found != null) {
      _pushPolicyData(direction, nearestScope, focusedChild);
      found.requestFocus();
      return true;
    }
    return false;
  }
}

class WidgetOrderFocusTraversalPolicy extends FocusTraversalPolicy
    with DirectionalFocusTraversalPolicyMixin {
  WidgetOrderFocusTraversalPolicy();

  @override
  FocusNode findFirstFocus(FocusNode currentNode) {
    assert(currentNode != null);
    final FocusScopeNode scope = currentNode.nearestScope;

    FocusNode candidate = scope.focusedChild;
    if (candidate == null) {
      if (scope.traversalChildren.isNotEmpty) {
        candidate = scope.traversalChildren.first;
      } else {
        candidate = currentNode;
      }
    }
    while (candidate is FocusScopeNode && candidate.focusedChild != null) {
      final FocusScopeNode candidateScope = candidate;
      candidate = candidateScope.focusedChild;
    }
    return candidate;
  }

  bool _move(FocusNode currentNode, {@required bool forward}) {
    if (currentNode == null) {
      return false;
    }
    final FocusScopeNode nearestScope = currentNode.nearestScope;
    invalidateScopeData(nearestScope);
    final FocusNode focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      final FocusNode firstFocus = findFirstFocus(currentNode);
      if (firstFocus != null) {
        firstFocus.requestFocus();
        return true;
      }
    }
    FocusNode previousNode;
    FocusNode firstNode;
    FocusNode lastNode;
    bool visit(FocusNode node) {
      for (FocusNode visited in node.traversalChildren) {
        firstNode ??= visited;
        if (!visit(visited)) {
          return false;
        }
        if (forward) {
          if (previousNode == focusedChild) {
            visited.requestFocus();
            return false;
          }
        } else {
          if (previousNode != null && visited == focusedChild) {
            previousNode.requestFocus();
            return false;
          }
        }
        previousNode = visited;
        lastNode = visited;
      }
      return true;
    }

    if (visit(nearestScope)) {
      if (forward) {
        if (firstNode != null) {
          firstNode.requestFocus();
          return true;
        }
      } else {
        if (lastNode != null) {
          lastNode.requestFocus();
          return true;
        }
      }
      return false;
    }
    return true;
  }

  @override
  bool next(FocusNode currentNode) => _move(currentNode, forward: true);

  @override
  bool previous(FocusNode currentNode) => _move(currentNode, forward: false);
}

class _SortData {
  _SortData(this.node) : rect = node.rect;

  final Rect rect;
  final FocusNode node;
}

class ReadingOrderTraversalPolicy extends FocusTraversalPolicy
    with DirectionalFocusTraversalPolicyMixin {
  @override
  FocusNode findFirstFocus(FocusNode currentNode) {
    assert(currentNode != null);
    final FocusScopeNode scope = currentNode.nearestScope;
    FocusNode candidate = scope.focusedChild;
    if (candidate == null && scope.traversalChildren.isNotEmpty) {
      candidate = _sortByGeometry(scope).first;
    }

    candidate ??= currentNode;
    candidate ??= WidgetsBinding.instance.focusManager.rootScope;
    return candidate;
  }

  Iterable<FocusNode> _sortByGeometry(FocusScopeNode scope) {
    final Iterable<FocusNode> nodes = scope.traversalDescendants;
    if (nodes.length <= 1) {
      return nodes;
    }

    Iterable<_SortData> inBand(
        _SortData current, Iterable<_SortData> candidates) {
      final Rect wide = Rect.fromLTRB(double.negativeInfinity, current.rect.top,
          double.infinity, current.rect.bottom);
      return candidates.where((_SortData item) {
        return !item.rect.intersect(wide).isEmpty;
      });
    }

    final TextDirection textDirection = scope.context == null
        ? TextDirection.ltr
        : Directionality.of(scope.context);
    _SortData pickFirst(List<_SortData> candidates) {
      int compareBeginningSide(_SortData a, _SortData b) {
        return textDirection == TextDirection.ltr
            ? a.rect.left.compareTo(b.rect.left)
            : -a.rect.right.compareTo(b.rect.right);
      }

      int compareTopSide(_SortData a, _SortData b) {
        return a.rect.top.compareTo(b.rect.top);
      }

      candidates.sort(compareTopSide);
      final _SortData topmost = candidates.first;

      final List<_SortData> inBandOfTop = inBand(topmost, candidates).toList();
      inBandOfTop.sort(compareBeginningSide);
      if (inBandOfTop.isNotEmpty) {
        return inBandOfTop.first;
      }
      return topmost;
    }

    final List<_SortData> data = <_SortData>[];
    for (FocusNode node in nodes) {
      data.add(_SortData(node));
    }

    final List<_SortData> sortedList = <_SortData>[];
    final List<_SortData> unplaced = data.toList();
    _SortData current = pickFirst(unplaced);
    sortedList.add(current);
    unplaced.remove(current);

    while (unplaced.isNotEmpty) {
      final _SortData next = pickFirst(unplaced);
      current = next;
      sortedList.add(current);
      unplaced.remove(current);
    }
    return sortedList.map((_SortData item) => item.node);
  }

  bool _move(FocusNode currentNode, {@required bool forward}) {
    final FocusScopeNode nearestScope = currentNode.nearestScope;
    invalidateScopeData(nearestScope);
    final FocusNode focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      final FocusNode firstFocus = findFirstFocus(currentNode);
      if (firstFocus != null) {
        firstFocus.requestFocus();
        return true;
      }
    }
    final List<FocusNode> sortedNodes = _sortByGeometry(nearestScope).toList();
    if (forward && focusedChild == sortedNodes.last) {
      sortedNodes.first.requestFocus();
      return true;
    }
    if (!forward && focusedChild == sortedNodes.first) {
      sortedNodes.last.requestFocus();
      return true;
    }

    final Iterable<FocusNode> maybeFlipped =
        forward ? sortedNodes : sortedNodes.reversed;
    FocusNode previousNode;
    for (FocusNode node in maybeFlipped) {
      if (previousNode == focusedChild) {
        node.requestFocus();
        return true;
      }
      previousNode = node;
    }
    return false;
  }

  @override
  bool next(FocusNode currentNode) => _move(currentNode, forward: true);

  @override
  bool previous(FocusNode currentNode) => _move(currentNode, forward: false);
}

class DefaultFocusTraversal extends InheritedWidget {
  const DefaultFocusTraversal({
    Key key,
    this.policy,
    @required Widget child,
  }) : super(key: key, child: child);

  final FocusTraversalPolicy policy;

  static FocusTraversalPolicy of(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    final DefaultFocusTraversal inherited =
        context.inheritFromWidgetOfExactType(DefaultFocusTraversal);
    assert(() {
      if (nullOk) {
        return true;
      }
      if (inherited == null) {
        throw FlutterError(
            'Unable to find a DefaultFocusTraversal widget in the context.\n'
            'DefaultFocusTraversal.of() was called with a context that does not contain a '
            'DefaultFocusTraversal.\n'
            'No DefaultFocusTraversal ancestor could be found starting from the context that was '
            'passed to DefaultFocusTraversal.of(). This can happen because there is not a '
            'WidgetsApp or MaterialApp widget (those widgets introduce a DefaultFocusTraversal), '
            'or it can happen if the context comes from a widget above those widgets.\n'
            'The context used was:\n'
            '  $context');
      }
      return true;
    }());
    return inherited?.policy ?? ReadingOrderTraversalPolicy();
  }

  @override
  bool updateShouldNotify(DefaultFocusTraversal oldWidget) =>
      policy != oldWidget.policy;
}

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart' show MatrixUtils, TransformProperty;
import 'package:flutter_web/services.dart';
import 'package:flutter_web/ui.dart' as ui;
import 'package:flutter_web/ui.dart'
    show Offset, Rect, SemanticsAction, SemanticsFlag, TextDirection;
import 'binding.dart' show SemanticsBinding;
import 'package:vector_math/vector_math_64.dart';

import 'semantics_event.dart';

export 'package:flutter_web/ui.dart' show SemanticsAction;
export 'semantics_event.dart';

typedef SemanticsNodeVisitor = bool Function(SemanticsNode node);

typedef MoveCursorHandler = void Function(bool extendSelection);

typedef SetSelectionHandler = void Function(TextSelection selection);

typedef _SemanticsActionHandler = void Function(dynamic args);

class SemanticsTag {
  const SemanticsTag(this.name);

  final String name;

  @override
  String toString() => '$runtimeType($name)';
}

@immutable
class CustomSemanticsAction {
  const CustomSemanticsAction({@required this.label})
      : assert(label != null),
        assert(label != ''),
        hint = null,
        action = null;

  const CustomSemanticsAction.overridingAction(
      {@required this.hint, @required this.action})
      : assert(hint != null),
        assert(hint != ''),
        assert(action != null),
        label = null;

  final String label;

  final String hint;

  final SemanticsAction action;

  @override
  int get hashCode => ui.hashValues(label, hint, action);

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final CustomSemanticsAction typedOther = other;
    return typedOther.label == label &&
        typedOther.hint == hint &&
        typedOther.action == action;
  }

  @override
  String toString() {
    return 'CustomSemanticsAction(${_ids[this]}, label:$label, hint:$hint, action:$action)';
  }

  static int _nextId = 0;
  static final Map<int, CustomSemanticsAction> _actions =
      <int, CustomSemanticsAction>{};
  static final Map<CustomSemanticsAction, int> _ids =
      <CustomSemanticsAction, int>{};

  static int getIdentifier(CustomSemanticsAction action) {
    int result = _ids[action];
    if (result == null) {
      result = _nextId++;
      _ids[action] = result;
      _actions[result] = action;
    }
    return result;
  }

  static CustomSemanticsAction getAction(int id) {
    return _actions[id];
  }
}

@immutable
class SemanticsData extends Diagnosticable {
  const SemanticsData({
    @required this.flags,
    @required this.actions,
    @required this.label,
    @required this.increasedValue,
    @required this.value,
    @required this.decreasedValue,
    @required this.hint,
    @required this.textDirection,
    @required this.rect,
    @required this.elevation,
    @required this.thickness,
    @required this.textSelection,
    @required this.scrollIndex,
    @required this.scrollChildCount,
    @required this.scrollPosition,
    @required this.scrollExtentMax,
    @required this.scrollExtentMin,
    @required this.platformViewId,
    this.tags,
    this.transform,
    this.customSemanticsActionIds,
  })  : assert(flags != null),
        assert(actions != null),
        assert(label != null),
        assert(value != null),
        assert(decreasedValue != null),
        assert(increasedValue != null),
        assert(hint != null),
        assert(label == '' || textDirection != null,
            'A SemanticsData object with label "$label" had a null textDirection.'),
        assert(value == '' || textDirection != null,
            'A SemanticsData object with value "$value" had a null textDirection.'),
        assert(hint == '' || textDirection != null,
            'A SemanticsData object with hint "$hint" had a null textDirection.'),
        assert(decreasedValue == '' || textDirection != null,
            'A SemanticsData object with decreasedValue "$decreasedValue" had a null textDirection.'),
        assert(increasedValue == '' || textDirection != null,
            'A SemanticsData object with increasedValue "$increasedValue" had a null textDirection.'),
        assert(rect != null);

  final int flags;

  final int actions;

  final String label;

  final String value;

  final String increasedValue;

  final String decreasedValue;

  final String hint;

  final TextDirection textDirection;

  final TextSelection textSelection;

  final int scrollChildCount;

  final int scrollIndex;

  final double scrollPosition;

  final double scrollExtentMax;

  final double scrollExtentMin;

  final int platformViewId;

  final Rect rect;

  final Set<SemanticsTag> tags;

  final Matrix4 transform;

  final double elevation;

  final double thickness;

  final List<int> customSemanticsActionIds;

  bool hasFlag(SemanticsFlag flag) => (flags & flag.index) != 0;

  bool hasAction(SemanticsAction action) => (actions & action.index) != 0;

  @override
  String toStringShort() => '$runtimeType';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Rect>('rect', rect, showName: false));
    properties.add(TransformProperty('transform', transform,
        showName: false, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: 0.0));
    properties.add(DoubleProperty('thickness', thickness, defaultValue: 0.0));
    final List<String> actionSummary = <String>[];
    for (SemanticsAction action in SemanticsAction.values.values) {
      if ((actions & action.index) != 0)
        actionSummary.add(describeEnum(action));
    }
    final List<String> customSemanticsActionSummary = customSemanticsActionIds
        .map<String>(
            (int actionId) => CustomSemanticsAction.getAction(actionId).label)
        .toList();
    properties
        .add(IterableProperty<String>('actions', actionSummary, ifEmpty: null));
    properties.add(IterableProperty<String>(
        'customActions', customSemanticsActionSummary,
        ifEmpty: null));

    final List<String> flagSummary = <String>[];
    for (SemanticsFlag flag in SemanticsFlag.values.values) {
      if ((flags & flag.index) != 0) flagSummary.add(describeEnum(flag));
    }
    properties
        .add(IterableProperty<String>('flags', flagSummary, ifEmpty: null));
    properties.add(StringProperty('label', label, defaultValue: ''));
    properties.add(StringProperty('value', value, defaultValue: ''));
    properties.add(
        StringProperty('increasedValue', increasedValue, defaultValue: ''));
    properties.add(
        StringProperty('decreasedValue', decreasedValue, defaultValue: ''));
    properties.add(StringProperty('hint', hint, defaultValue: ''));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    if (textSelection?.isValid == true)
      properties.add(MessageProperty(
          'textSelection', '[${textSelection.start}, ${textSelection.end}]'));
    properties
        .add(IntProperty('platformViewId', platformViewId, defaultValue: null));
    properties.add(
        IntProperty('scrollChildren', scrollChildCount, defaultValue: null));
    properties.add(IntProperty('scrollIndex', scrollIndex, defaultValue: null));
    properties.add(
        DoubleProperty('scrollExtentMin', scrollExtentMin, defaultValue: null));
    properties.add(
        DoubleProperty('scrollPosition', scrollPosition, defaultValue: null));
    properties.add(
        DoubleProperty('scrollExtentMax', scrollExtentMax, defaultValue: null));
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! SemanticsData) return false;
    final SemanticsData typedOther = other;
    return typedOther.flags == flags &&
        typedOther.actions == actions &&
        typedOther.label == label &&
        typedOther.value == value &&
        typedOther.increasedValue == increasedValue &&
        typedOther.decreasedValue == decreasedValue &&
        typedOther.hint == hint &&
        typedOther.textDirection == textDirection &&
        typedOther.rect == rect &&
        setEquals(typedOther.tags, tags) &&
        typedOther.scrollChildCount == scrollChildCount &&
        typedOther.scrollIndex == scrollIndex &&
        typedOther.textSelection == textSelection &&
        typedOther.scrollPosition == scrollPosition &&
        typedOther.scrollExtentMax == scrollExtentMax &&
        typedOther.scrollExtentMin == scrollExtentMin &&
        typedOther.platformViewId == platformViewId &&
        typedOther.transform == transform &&
        typedOther.elevation == elevation &&
        typedOther.thickness == thickness &&
        _sortedListsEqual(
            typedOther.customSemanticsActionIds, customSemanticsActionIds);
  }

  @override
  int get hashCode {
    return ui.hashValues(
      ui.hashValues(
        flags,
        actions,
        label,
        value,
        increasedValue,
        decreasedValue,
        hint,
        textDirection,
        rect,
        tags,
        textSelection,
        scrollChildCount,
        scrollIndex,
        scrollPosition,
        scrollExtentMax,
        scrollExtentMin,
        platformViewId,
        transform,
        elevation,
        thickness,
      ),
      ui.hashList(customSemanticsActionIds),
    );
  }

  static bool _sortedListsEqual(List<int> left, List<int> right) {
    if (left == null && right == null) return true;
    if (left != null && right != null) {
      if (left.length != right.length) return false;
      for (int i = 0; i < left.length; i++)
        if (left[i] != right[i]) return false;
      return true;
    }
    return false;
  }
}

class _SemanticsDiagnosticableNode extends DiagnosticableNode<SemanticsNode> {
  _SemanticsDiagnosticableNode({
    String name,
    @required SemanticsNode value,
    @required DiagnosticsTreeStyle style,
    @required this.childOrder,
  }) : super(
          name: name,
          value: value,
          style: style,
        );

  final DebugSemanticsDumpOrder childOrder;

  @override
  List<DiagnosticsNode> getChildren() {
    if (value != null)
      return value.debugDescribeChildren(childOrder: childOrder);

    return const <DiagnosticsNode>[];
  }
}

@immutable
class SemanticsHintOverrides extends DiagnosticableTree {
  const SemanticsHintOverrides({
    this.onTapHint,
    this.onLongPressHint,
  })  : assert(onTapHint != ''),
        assert(onLongPressHint != '');

  final String onTapHint;

  final String onLongPressHint;

  bool get isNotEmpty => onTapHint != null || onLongPressHint != null;

  @override
  int get hashCode => ui.hashValues(onTapHint, onLongPressHint);

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final SemanticsHintOverrides typedOther = other;
    return typedOther.onTapHint == onTapHint &&
        typedOther.onLongPressHint == onLongPressHint;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('onTapHint', onTapHint, defaultValue: null));
    properties.add(
        StringProperty('onLongPressHint', onLongPressHint, defaultValue: null));
  }
}

@immutable
class SemanticsProperties extends DiagnosticableTree {
  const SemanticsProperties({
    this.enabled,
    this.checked,
    this.selected,
    this.toggled,
    this.button,
    this.header,
    this.textField,
    this.readOnly,
    this.focused,
    this.inMutuallyExclusiveGroup,
    this.hidden,
    this.obscured,
    this.multiline,
    this.scopesRoute,
    this.namesRoute,
    this.image,
    this.liveRegion,
    this.label,
    this.value,
    this.increasedValue,
    this.decreasedValue,
    this.hint,
    this.hintOverrides,
    this.textDirection,
    this.sortKey,
    this.onTap,
    this.onLongPress,
    this.onScrollLeft,
    this.onScrollRight,
    this.onScrollUp,
    this.onScrollDown,
    this.onIncrease,
    this.onDecrease,
    this.onCopy,
    this.onCut,
    this.onPaste,
    this.onMoveCursorForwardByCharacter,
    this.onMoveCursorBackwardByCharacter,
    this.onMoveCursorForwardByWord,
    this.onMoveCursorBackwardByWord,
    this.onSetSelection,
    this.onDidGainAccessibilityFocus,
    this.onDidLoseAccessibilityFocus,
    this.onDismiss,
    this.customSemanticsActions,
  });

  final bool enabled;

  final bool checked;

  final bool toggled;

  final bool selected;

  final bool button;

  final bool header;

  final bool textField;

  final bool readOnly;

  final bool focused;

  final bool inMutuallyExclusiveGroup;

  final bool hidden;

  final bool obscured;

  final bool multiline;

  final bool scopesRoute;

  final bool namesRoute;

  final bool image;

  final bool liveRegion;

  final String label;

  final String value;

  final String increasedValue;

  final String decreasedValue;

  final String hint;

  final SemanticsHintOverrides hintOverrides;

  final TextDirection textDirection;

  final SemanticsSortKey sortKey;

  final VoidCallback onTap;

  final VoidCallback onLongPress;

  final VoidCallback onScrollLeft;

  final VoidCallback onScrollRight;

  final VoidCallback onScrollUp;

  final VoidCallback onScrollDown;

  final VoidCallback onIncrease;

  final VoidCallback onDecrease;

  final VoidCallback onCopy;

  final VoidCallback onCut;

  final VoidCallback onPaste;

  final MoveCursorHandler onMoveCursorForwardByCharacter;

  final MoveCursorHandler onMoveCursorBackwardByCharacter;

  final MoveCursorHandler onMoveCursorForwardByWord;

  final MoveCursorHandler onMoveCursorBackwardByWord;

  final SetSelectionHandler onSetSelection;

  final VoidCallback onDidGainAccessibilityFocus;

  final VoidCallback onDidLoseAccessibilityFocus;

  final VoidCallback onDismiss;

  final Map<CustomSemanticsAction, VoidCallback> customSemanticsActions;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<bool>('checked', checked, defaultValue: null));
    properties.add(
        DiagnosticsProperty<bool>('selected', selected, defaultValue: null));
    properties.add(StringProperty('label', label, defaultValue: ''));
    properties.add(StringProperty('value', value));
    properties.add(StringProperty('hint', hint));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(DiagnosticsProperty<SemanticsSortKey>('sortKey', sortKey,
        defaultValue: null));
    properties.add(DiagnosticsProperty<SemanticsHintOverrides>(
        'hintOverrides', hintOverrides));
  }

  @override
  String toStringShort() => '$runtimeType';
}

void debugResetSemanticsIdCounter() {
  SemanticsNode._lastIdentifier = 0;
}

class SemanticsNode extends AbstractNode with DiagnosticableTreeMixin {
  SemanticsNode({
    this.key,
    VoidCallback showOnScreen,
  })  : id = _generateNewId(),
        _showOnScreen = showOnScreen;

  SemanticsNode.root({
    this.key,
    VoidCallback showOnScreen,
    SemanticsOwner owner,
  })  : id = 0,
        _showOnScreen = showOnScreen {
    attach(owner);
  }

  static const int _maxFrameworkAccessibilityIdentifier = (1 << 16) - 1;

  static int _lastIdentifier = 0;
  static int _generateNewId() {
    _lastIdentifier =
        (_lastIdentifier + 1) % _maxFrameworkAccessibilityIdentifier;
    return _lastIdentifier;
  }

  final Key key;

  final int id;

  final VoidCallback _showOnScreen;

  Matrix4 get transform => _transform;
  Matrix4 _transform;
  set transform(Matrix4 value) {
    if (!MatrixUtils.matrixEquals(_transform, value)) {
      _transform = MatrixUtils.isIdentity(value) ? null : value;
      _markDirty();
    }
  }

  Rect get rect => _rect;
  Rect _rect = Rect.zero;
  set rect(Rect value) {
    assert(value != null);
    assert(
        value.isFinite, '$this (with $owner) tried to set a non-finite rect.');
    if (_rect != value) {
      _rect = value;
      _markDirty();
    }
  }

  Rect parentSemanticsClipRect;

  Rect parentPaintClipRect;

  double elevationAdjustment;

  int indexInParent;

  bool get isInvisible => !isMergedIntoParent && rect.isEmpty;

  bool get isMergedIntoParent => _isMergedIntoParent;
  bool _isMergedIntoParent = false;
  set isMergedIntoParent(bool value) {
    assert(value != null);
    if (_isMergedIntoParent == value) return;
    _isMergedIntoParent = value;
    _markDirty();
  }

  bool get isPartOfNodeMerging =>
      mergeAllDescendantsIntoThisNode || isMergedIntoParent;

  bool get mergeAllDescendantsIntoThisNode => _mergeAllDescendantsIntoThisNode;
  bool _mergeAllDescendantsIntoThisNode =
      _kEmptyConfig.isMergingSemanticsOfDescendants;

  List<SemanticsNode> _children;

  List<SemanticsNode> _debugPreviousSnapshot;

  void _replaceChildren(List<SemanticsNode> newChildren) {
    assert(!newChildren.any((SemanticsNode child) => child == this));
    assert(() {
      if (identical(newChildren, _children)) {
        final List<DiagnosticsNode> mutationErrors = <DiagnosticsNode>[];
        if (newChildren.length != _debugPreviousSnapshot.length) {
          mutationErrors.add(ErrorDescription(
              'The list\'s length has changed from ${_debugPreviousSnapshot.length} '
              'to ${newChildren.length}.'));
        } else {
          for (int i = 0; i < newChildren.length; i++) {
            if (!identical(newChildren[i], _debugPreviousSnapshot[i])) {
              if (mutationErrors.isNotEmpty) {
                mutationErrors.add(ErrorSpacer());
              }
              mutationErrors.add(
                  ErrorDescription('Child node at position $i was replaced:'));
              mutationErrors.add(newChildren[i].toDiagnosticsNode(
                  name: 'Previous child',
                  style: DiagnosticsTreeStyle.singleLine));
              mutationErrors.add(_debugPreviousSnapshot[i].toDiagnosticsNode(
                  name: 'New child', style: DiagnosticsTreeStyle.singleLine));
            }
          }
        }
        if (mutationErrors.isNotEmpty) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                'Failed to replace child semantics nodes because the list of `SemanticsNode`s was mutated.'),
            ErrorHint(
                'Instead of mutating the existing list, create a new list containing the desired `SemanticsNode`s.'),
            ErrorDescription('Error details:'),
            ...mutationErrors
          ]);
        }
      }
      assert(
          !newChildren.any((SemanticsNode node) => node.isMergedIntoParent) ||
              isPartOfNodeMerging);

      _debugPreviousSnapshot = List<SemanticsNode>.from(newChildren);

      SemanticsNode ancestor = this;
      while (ancestor.parent is SemanticsNode) ancestor = ancestor.parent;
      assert(!newChildren.any((SemanticsNode child) => child == ancestor));
      return true;
    }());
    assert(() {
      final Set<SemanticsNode> seenChildren = <SemanticsNode>{};
      for (SemanticsNode child in newChildren) assert(seenChildren.add(child));
      return true;
    }());

    if (_children != null) {
      for (SemanticsNode child in _children) child._dead = true;
    }
    if (newChildren != null) {
      for (SemanticsNode child in newChildren) {
        assert(!child.isInvisible,
            'Child $child is invisible and should not be added as a child of $this.');
        child._dead = false;
      }
    }
    bool sawChange = false;
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (child._dead) {
          if (child.parent == this) {
            dropChild(child);
          }
          sawChange = true;
        }
      }
    }
    if (newChildren != null) {
      for (SemanticsNode child in newChildren) {
        if (child.parent != this) {
          if (child.parent != null) {
            child.parent?.dropChild(child);
          }
          assert(!child.attached);
          adoptChild(child);
          sawChange = true;
        }
      }
    }
    if (!sawChange && _children != null) {
      assert(newChildren != null);
      assert(newChildren.length == _children.length);

      for (int i = 0; i < _children.length; i++) {
        if (_children[i].id != newChildren[i].id) {
          sawChange = true;
          break;
        }
      }
    }
    _children = newChildren;
    if (sawChange) _markDirty();
  }

  bool get hasChildren => _children?.isNotEmpty ?? false;
  bool _dead = false;

  int get childrenCount => hasChildren ? _children.length : 0;

  void visitChildren(SemanticsNodeVisitor visitor) {
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (!visitor(child)) return;
      }
    }
  }

  bool _visitDescendants(SemanticsNodeVisitor visitor) {
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (!visitor(child) || !child._visitDescendants(visitor)) return false;
      }
    }
    return true;
  }

  @override
  SemanticsOwner get owner => super.owner;

  @override
  SemanticsNode get parent => super.parent;

  @override
  void redepthChildren() {
    _children?.forEach(redepthChild);
  }

  @override
  void attach(SemanticsOwner owner) {
    super.attach(owner);
    assert(!owner._nodes.containsKey(id));
    owner._nodes[id] = this;
    owner._detachedNodes.remove(this);
    if (_dirty) {
      _dirty = false;
      _markDirty();
    }
    if (_children != null) {
      for (SemanticsNode child in _children) child.attach(owner);
    }
  }

  @override
  void detach() {
    assert(owner._nodes.containsKey(id));
    assert(!owner._detachedNodes.contains(this));
    owner._nodes.remove(id);
    owner._detachedNodes.add(this);
    super.detach();
    assert(owner == null);
    if (_children != null) {
      for (SemanticsNode child in _children) {
        if (child.parent == this) child.detach();
      }
    }

    _markDirty();
  }

  bool _dirty = false;
  void _markDirty() {
    if (_dirty) return;
    _dirty = true;
    if (attached) {
      assert(!owner._detachedNodes.contains(this));
      owner._dirtyNodes.add(this);
    }
  }

  bool _isDifferentFromCurrentSemanticAnnotation(
      SemanticsConfiguration config) {
    return _label != config.label ||
        _hint != config.hint ||
        _elevation != config.elevation ||
        _thickness != config.thickness ||
        _decreasedValue != config.decreasedValue ||
        _value != config.value ||
        _increasedValue != config.increasedValue ||
        _flags != config._flags ||
        _textDirection != config.textDirection ||
        _sortKey != config._sortKey ||
        _textSelection != config._textSelection ||
        _scrollPosition != config._scrollPosition ||
        _scrollExtentMax != config._scrollExtentMax ||
        _scrollExtentMin != config._scrollExtentMin ||
        _actionsAsBits != config._actionsAsBits ||
        indexInParent != config.indexInParent ||
        platformViewId != config.platformViewId ||
        _mergeAllDescendantsIntoThisNode !=
            config.isMergingSemanticsOfDescendants;
  }

  Map<SemanticsAction, _SemanticsActionHandler> _actions =
      _kEmptyConfig._actions;
  Map<CustomSemanticsAction, VoidCallback> _customSemanticsActions =
      _kEmptyConfig._customSemanticsActions;

  int _actionsAsBits = _kEmptyConfig._actionsAsBits;

  Set<SemanticsTag> tags;

  bool isTagged(SemanticsTag tag) => tags != null && tags.contains(tag);

  int _flags = _kEmptyConfig._flags;

  bool hasFlag(SemanticsFlag flag) => _flags & flag.index != 0;

  String get label => _label;
  String _label = _kEmptyConfig.label;

  String get value => _value;
  String _value = _kEmptyConfig.value;

  String get decreasedValue => _decreasedValue;
  String _decreasedValue = _kEmptyConfig.decreasedValue;

  String get increasedValue => _increasedValue;
  String _increasedValue = _kEmptyConfig.increasedValue;

  String get hint => _hint;
  String _hint = _kEmptyConfig.hint;

  double get elevation => _elevation;
  double _elevation = _kEmptyConfig.elevation;

  double get thickness => _thickness;
  double _thickness = _kEmptyConfig.thickness;

  SemanticsHintOverrides get hintOverrides => _hintOverrides;
  SemanticsHintOverrides _hintOverrides;

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection = _kEmptyConfig.textDirection;

  SemanticsSortKey get sortKey => _sortKey;
  SemanticsSortKey _sortKey;

  TextSelection get textSelection => _textSelection;
  TextSelection _textSelection;

  bool get isMultiline => _isMultiline;
  bool _isMultiline;

  int get scrollChildCount => _scrollChildCount;
  int _scrollChildCount;

  int get scrollIndex => _scrollIndex;
  int _scrollIndex;

  double get scrollPosition => _scrollPosition;
  double _scrollPosition;

  double get scrollExtentMax => _scrollExtentMax;
  double _scrollExtentMax;

  double get scrollExtentMin => _scrollExtentMin;
  double _scrollExtentMin;

  int get platformViewId => _platformViewId;
  int _platformViewId;

  bool _canPerformAction(SemanticsAction action) =>
      _actions.containsKey(action);

  static final SemanticsConfiguration _kEmptyConfig = SemanticsConfiguration();

  void updateWith({
    @required SemanticsConfiguration config,
    List<SemanticsNode> childrenInInversePaintOrder,
  }) {
    config ??= _kEmptyConfig;
    if (_isDifferentFromCurrentSemanticAnnotation(config)) _markDirty();

    assert(config.platformViewId == null || childrenInInversePaintOrder.isEmpty,
        'SemanticsNodes with children must not specify a platformViewId.');

    _label = config.label;
    _decreasedValue = config.decreasedValue;
    _value = config.value;
    _increasedValue = config.increasedValue;
    _hint = config.hint;
    _hintOverrides = config.hintOverrides;
    _elevation = config.elevation;
    _thickness = config.thickness;
    _flags = config._flags;
    _textDirection = config.textDirection;
    _sortKey = config.sortKey;
    _actions =
        Map<SemanticsAction, _SemanticsActionHandler>.from(config._actions);
    _customSemanticsActions = Map<CustomSemanticsAction, VoidCallback>.from(
        config._customSemanticsActions);
    _actionsAsBits = config._actionsAsBits;
    _textSelection = config._textSelection;
    _isMultiline = config.isMultiline;
    _scrollPosition = config._scrollPosition;
    _scrollExtentMax = config._scrollExtentMax;
    _scrollExtentMin = config._scrollExtentMin;
    _mergeAllDescendantsIntoThisNode = config.isMergingSemanticsOfDescendants;
    _scrollChildCount = config.scrollChildCount;
    _scrollIndex = config.scrollIndex;
    indexInParent = config.indexInParent;
    _platformViewId = config._platformViewId;
    _replaceChildren(childrenInInversePaintOrder ?? const <SemanticsNode>[]);

    assert(
      !_canPerformAction(SemanticsAction.increase) ||
          (_value == '') == (_increasedValue == ''),
      'A SemanticsNode with action "increase" needs to be annotated with either both "value" and "increasedValue" or neither',
    );
    assert(
      !_canPerformAction(SemanticsAction.decrease) ||
          (_value == '') == (_decreasedValue == ''),
      'A SemanticsNode with action "increase" needs to be annotated with either both "value" and "decreasedValue" or neither',
    );
  }

  SemanticsData getSemanticsData() {
    int flags = _flags;
    int actions = _actionsAsBits;
    String label = _label;
    String hint = _hint;
    String value = _value;
    String increasedValue = _increasedValue;
    String decreasedValue = _decreasedValue;
    TextDirection textDirection = _textDirection;
    Set<SemanticsTag> mergedTags =
        tags == null ? null : Set<SemanticsTag>.from(tags);
    TextSelection textSelection = _textSelection;
    int scrollChildCount = _scrollChildCount;
    int scrollIndex = _scrollIndex;
    double scrollPosition = _scrollPosition;
    double scrollExtentMax = _scrollExtentMax;
    double scrollExtentMin = _scrollExtentMin;
    int platformViewId = _platformViewId;
    final double elevation = _elevation;
    double thickness = _thickness;
    final Set<int> customSemanticsActionIds = <int>{};
    for (CustomSemanticsAction action in _customSemanticsActions.keys)
      customSemanticsActionIds.add(CustomSemanticsAction.getIdentifier(action));
    if (hintOverrides != null) {
      if (hintOverrides.onTapHint != null) {
        final CustomSemanticsAction action =
            CustomSemanticsAction.overridingAction(
          hint: hintOverrides.onTapHint,
          action: SemanticsAction.tap,
        );
        customSemanticsActionIds
            .add(CustomSemanticsAction.getIdentifier(action));
      }
      if (hintOverrides.onLongPressHint != null) {
        final CustomSemanticsAction action =
            CustomSemanticsAction.overridingAction(
          hint: hintOverrides.onLongPressHint,
          action: SemanticsAction.longPress,
        );
        customSemanticsActionIds
            .add(CustomSemanticsAction.getIdentifier(action));
      }
    }

    if (mergeAllDescendantsIntoThisNode) {
      _visitDescendants((SemanticsNode node) {
        assert(node.isMergedIntoParent);
        flags |= node._flags;
        actions |= node._actionsAsBits;
        textDirection ??= node._textDirection;
        textSelection ??= node._textSelection;
        scrollChildCount ??= node._scrollChildCount;
        scrollIndex ??= node._scrollIndex;
        scrollPosition ??= node._scrollPosition;
        scrollExtentMax ??= node._scrollExtentMax;
        scrollExtentMin ??= node._scrollExtentMin;
        platformViewId ??= node._platformViewId;
        if (value == '' || value == null) value = node._value;
        if (increasedValue == '' || increasedValue == null)
          increasedValue = node._increasedValue;
        if (decreasedValue == '' || decreasedValue == null)
          decreasedValue = node._decreasedValue;
        if (node.tags != null) {
          mergedTags ??= <SemanticsTag>{};
          mergedTags.addAll(node.tags);
        }
        if (node._customSemanticsActions != null) {
          for (CustomSemanticsAction action in _customSemanticsActions.keys)
            customSemanticsActionIds
                .add(CustomSemanticsAction.getIdentifier(action));
        }
        if (node.hintOverrides != null) {
          if (node.hintOverrides.onTapHint != null) {
            final CustomSemanticsAction action =
                CustomSemanticsAction.overridingAction(
              hint: node.hintOverrides.onTapHint,
              action: SemanticsAction.tap,
            );
            customSemanticsActionIds
                .add(CustomSemanticsAction.getIdentifier(action));
          }
          if (node.hintOverrides.onLongPressHint != null) {
            final CustomSemanticsAction action =
                CustomSemanticsAction.overridingAction(
              hint: node.hintOverrides.onLongPressHint,
              action: SemanticsAction.longPress,
            );
            customSemanticsActionIds
                .add(CustomSemanticsAction.getIdentifier(action));
          }
        }
        label = _concatStrings(
          thisString: label,
          thisTextDirection: textDirection,
          otherString: node._label,
          otherTextDirection: node._textDirection,
        );
        hint = _concatStrings(
          thisString: hint,
          thisTextDirection: textDirection,
          otherString: node._hint,
          otherTextDirection: node._textDirection,
        );

        thickness = math.max(thickness, node._thickness + node._elevation);

        return true;
      });
    }

    return SemanticsData(
      flags: flags,
      actions: actions,
      label: label,
      value: value,
      increasedValue: increasedValue,
      decreasedValue: decreasedValue,
      hint: hint,
      textDirection: textDirection,
      rect: rect,
      transform: transform,
      elevation: elevation,
      thickness: thickness,
      tags: mergedTags,
      textSelection: textSelection,
      scrollChildCount: scrollChildCount,
      scrollIndex: scrollIndex,
      scrollPosition: scrollPosition,
      scrollExtentMax: scrollExtentMax,
      scrollExtentMin: scrollExtentMin,
      platformViewId: platformViewId,
      customSemanticsActionIds: customSemanticsActionIds.toList()..sort(),
    );
  }

  static Float64List _initIdentityTransform() {
    return Matrix4.identity().storage;
  }

  static final Int32List _kEmptyChildList = Int32List(0);
  static final Int32List _kEmptyCustomSemanticsActionsList = Int32List(0);
  static final Float64List _kIdentityTransform = _initIdentityTransform();

  void _addToUpdate(ui.SemanticsUpdateBuilder builder,
      Set<int> customSemanticsActionIdsUpdate) {
    assert(_dirty);
    final SemanticsData data = getSemanticsData();
    Int32List childrenInTraversalOrder;
    Int32List childrenInHitTestOrder;
    if (!hasChildren || mergeAllDescendantsIntoThisNode) {
      childrenInTraversalOrder = _kEmptyChildList;
      childrenInHitTestOrder = _kEmptyChildList;
    } else {
      final int childCount = _children.length;
      final List<SemanticsNode> sortedChildren = _childrenInTraversalOrder();
      childrenInTraversalOrder = Int32List(childCount);
      for (int i = 0; i < childCount; i += 1) {
        childrenInTraversalOrder[i] = sortedChildren[i].id;
      }

      childrenInHitTestOrder = Int32List(childCount);
      for (int i = childCount - 1; i >= 0; i -= 1) {
        childrenInHitTestOrder[i] = _children[childCount - i - 1].id;
      }
    }
    Int32List customSemanticsActionIds;
    if (data.customSemanticsActionIds?.isNotEmpty == true) {
      customSemanticsActionIds =
          Int32List(data.customSemanticsActionIds.length);
      for (int i = 0; i < data.customSemanticsActionIds.length; i++) {
        customSemanticsActionIds[i] = data.customSemanticsActionIds[i];
        customSemanticsActionIdsUpdate.add(data.customSemanticsActionIds[i]);
      }
    }
    builder.updateNode(
      id: id,
      flags: data.flags,
      actions: data.actions,
      rect: data.rect,
      label: data.label,
      value: data.value,
      decreasedValue: data.decreasedValue,
      increasedValue: data.increasedValue,
      hint: data.hint,
      textDirection: data.textDirection,
      textSelectionBase:
          data.textSelection != null ? data.textSelection.baseOffset : -1,
      textSelectionExtent:
          data.textSelection != null ? data.textSelection.extentOffset : -1,
      platformViewId: data.platformViewId ?? -1,
      scrollChildren: data.scrollChildCount ?? 0,
      scrollIndex: data.scrollIndex ?? 0,
      scrollPosition: data.scrollPosition ?? double.nan,
      scrollExtentMax: data.scrollExtentMax ?? double.nan,
      scrollExtentMin: data.scrollExtentMin ?? double.nan,
      transform: data.transform?.storage ?? _kIdentityTransform,
      elevation: data.elevation,
      thickness: data.thickness,
      childrenInTraversalOrder: childrenInTraversalOrder,
      childrenInHitTestOrder: childrenInHitTestOrder,
      additionalActions:
          customSemanticsActionIds ?? _kEmptyCustomSemanticsActionsList,
    );
    _dirty = false;
  }

  List<SemanticsNode> _childrenInTraversalOrder() {
    TextDirection inheritedTextDirection = textDirection;
    SemanticsNode ancestor = parent;
    while (inheritedTextDirection == null && ancestor != null) {
      inheritedTextDirection = ancestor.textDirection;
      ancestor = ancestor.parent;
    }

    List<SemanticsNode> childrenInDefaultOrder;
    if (inheritedTextDirection != null) {
      childrenInDefaultOrder =
          _childrenInDefaultOrder(_children, inheritedTextDirection);
    } else {
      childrenInDefaultOrder = _children;
    }

    final List<_TraversalSortNode> everythingSorted = <_TraversalSortNode>[];
    final List<_TraversalSortNode> sortNodes = <_TraversalSortNode>[];
    SemanticsSortKey lastSortKey;
    for (int position = 0;
        position < childrenInDefaultOrder.length;
        position += 1) {
      final SemanticsNode child = childrenInDefaultOrder[position];
      final SemanticsSortKey sortKey = child.sortKey;
      lastSortKey =
          position > 0 ? childrenInDefaultOrder[position - 1].sortKey : null;
      final bool isCompatibleWithPreviousSortKey = position == 0 ||
          sortKey.runtimeType == lastSortKey.runtimeType &&
              (sortKey == null || sortKey.name == lastSortKey.name);
      if (!isCompatibleWithPreviousSortKey && sortNodes.isNotEmpty) {
        if (lastSortKey != null) {
          sortNodes.sort();
        }
        everythingSorted.addAll(sortNodes);
        sortNodes.clear();
      }

      sortNodes.add(_TraversalSortNode(
        node: child,
        sortKey: sortKey,
        position: position,
      ));
    }

    if (lastSortKey != null) {
      sortNodes.sort();
    }
    everythingSorted.addAll(sortNodes);

    return everythingSorted
        .map<SemanticsNode>((_TraversalSortNode sortNode) => sortNode.node)
        .toList();
  }

  void sendEvent(SemanticsEvent event) {
    if (!attached) return;
    SystemChannels.accessibility.send(event.toMap(nodeId: id));
  }

  @override
  String toStringShort() => '$runtimeType#$id';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    bool hideOwner = true;
    if (_dirty) {
      final bool inDirtyNodes =
          owner != null && owner._dirtyNodes.contains(this);
      properties.add(FlagProperty('inDirtyNodes',
          value: inDirtyNodes, ifTrue: 'dirty', ifFalse: 'STALE'));
      hideOwner = inDirtyNodes;
    }
    properties.add(DiagnosticsProperty<SemanticsOwner>('owner', owner,
        level: hideOwner ? DiagnosticLevel.hidden : DiagnosticLevel.info));
    properties.add(FlagProperty('isMergedIntoParent',
        value: isMergedIntoParent, ifTrue: 'merged up ⬆️'));
    properties.add(FlagProperty('mergeAllDescendantsIntoThisNode',
        value: mergeAllDescendantsIntoThisNode, ifTrue: 'merge boundary ⛔️'));
    final Offset offset =
        transform != null ? MatrixUtils.getAsTranslation(transform) : null;
    if (offset != null) {
      properties.add(DiagnosticsProperty<Rect>('rect', rect.shift(offset),
          showName: false));
    } else {
      final double scale =
          transform != null ? MatrixUtils.getAsScale(transform) : null;
      String description;
      if (scale != null) {
        description = '$rect scaled by ${scale.toStringAsFixed(1)}x';
      } else if (transform != null && !MatrixUtils.isIdentity(transform)) {
        final String matrix = transform
            .toString()
            .split('\n')
            .take(4)
            .map<String>((String line) => line.substring(4))
            .join('; ');
        description = '$rect with transform [$matrix]';
      }
      properties.add(DiagnosticsProperty<Rect>('rect', rect,
          description: description, showName: false));
    }
    properties.add(IterableProperty<String>(
        'tags', tags?.map((SemanticsTag tag) => tag.name),
        defaultValue: null));
    final List<String> actions = _actions.keys
        .map<String>((SemanticsAction action) => describeEnum(action))
        .toList()
          ..sort();
    final List<String> customSemanticsActions = _customSemanticsActions.keys
        .map<String>((CustomSemanticsAction action) => action.label)
        .toList();
    properties.add(IterableProperty<String>('actions', actions, ifEmpty: null));
    properties.add(IterableProperty<String>(
        'customActions', customSemanticsActions,
        ifEmpty: null));
    final List<String> flags = SemanticsFlag.values.values
        .where((SemanticsFlag flag) => hasFlag(flag))
        .map((SemanticsFlag flag) =>
            flag.toString().substring('SemanticsFlag.'.length))
        .toList();
    properties.add(IterableProperty<String>('flags', flags, ifEmpty: null));
    properties.add(
        FlagProperty('isInvisible', value: isInvisible, ifTrue: 'invisible'));
    properties.add(FlagProperty('isHidden',
        value: hasFlag(SemanticsFlag.isHidden), ifTrue: 'HIDDEN'));
    properties.add(StringProperty('label', _label, defaultValue: ''));
    properties.add(StringProperty('value', _value, defaultValue: ''));
    properties.add(
        StringProperty('increasedValue', _increasedValue, defaultValue: ''));
    properties.add(
        StringProperty('decreasedValue', _decreasedValue, defaultValue: ''));
    properties.add(StringProperty('hint', _hint, defaultValue: ''));
    properties.add(EnumProperty<TextDirection>('textDirection', _textDirection,
        defaultValue: null));
    properties.add(DiagnosticsProperty<SemanticsSortKey>('sortKey', sortKey,
        defaultValue: null));
    if (_textSelection?.isValid == true)
      properties.add(MessageProperty('text selection',
          '[${_textSelection.start}, ${_textSelection.end}]'));
    properties
        .add(IntProperty('platformViewId', platformViewId, defaultValue: null));
    properties.add(
        IntProperty('scrollChildren', scrollChildCount, defaultValue: null));
    properties.add(IntProperty('scrollIndex', scrollIndex, defaultValue: null));
    properties.add(
        DoubleProperty('scrollExtentMin', scrollExtentMin, defaultValue: null));
    properties.add(
        DoubleProperty('scrollPosition', scrollPosition, defaultValue: null));
    properties.add(
        DoubleProperty('scrollExtentMax', scrollExtentMax, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: 0.0));
    properties.add(DoubleProperty('thickness', thickness, defaultValue: 0.0));
  }

  @override
  String toStringDeep({
    String prefixLineOne = '',
    String prefixOtherLines,
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
    DebugSemanticsDumpOrder childOrder = DebugSemanticsDumpOrder.traversalOrder,
  }) {
    assert(childOrder != null);
    return toDiagnosticsNode(childOrder: childOrder).toStringDeep(
        prefixLineOne: prefixLineOne,
        prefixOtherLines: prefixOtherLines,
        minLevel: minLevel);
  }

  @override
  DiagnosticsNode toDiagnosticsNode({
    String name,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.sparse,
    DebugSemanticsDumpOrder childOrder = DebugSemanticsDumpOrder.traversalOrder,
  }) {
    return _SemanticsDiagnosticableNode(
      name: name,
      value: this,
      style: style,
      childOrder: childOrder,
    );
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren(
      {DebugSemanticsDumpOrder childOrder =
          DebugSemanticsDumpOrder.inverseHitTest}) {
    return debugListChildrenInOrder(childOrder)
        .map<DiagnosticsNode>((SemanticsNode node) =>
            node.toDiagnosticsNode(childOrder: childOrder))
        .toList();
  }

  List<SemanticsNode> debugListChildrenInOrder(
      DebugSemanticsDumpOrder childOrder) {
    assert(childOrder != null);
    if (_children == null) return const <SemanticsNode>[];

    switch (childOrder) {
      case DebugSemanticsDumpOrder.inverseHitTest:
        return _children;
      case DebugSemanticsDumpOrder.traversalOrder:
        return _childrenInTraversalOrder();
    }
    assert(false);
    return null;
  }
}

class _BoxEdge implements Comparable<_BoxEdge> {
  _BoxEdge({
    @required this.isLeadingEdge,
    @required this.offset,
    @required this.node,
  })  : assert(isLeadingEdge != null),
        assert(offset != null),
        assert(offset.isFinite),
        assert(node != null);

  final bool isLeadingEdge;

  final double offset;

  final SemanticsNode node;

  @override
  int compareTo(_BoxEdge other) {
    return (offset - other.offset).sign.toInt();
  }
}

class _SemanticsSortGroup extends Comparable<_SemanticsSortGroup> {
  _SemanticsSortGroup({
    @required this.startOffset,
    @required this.textDirection,
  }) : assert(startOffset != null);

  final double startOffset;

  final TextDirection textDirection;

  final List<SemanticsNode> nodes = <SemanticsNode>[];

  @override
  int compareTo(_SemanticsSortGroup other) {
    return (startOffset - other.startOffset).sign.toInt();
  }

  List<SemanticsNode> sortedWithinVerticalGroup() {
    final List<_BoxEdge> edges = <_BoxEdge>[];
    for (SemanticsNode child in nodes) {
      final Rect childRect = child.rect.deflate(0.1);
      edges.add(_BoxEdge(
        isLeadingEdge: true,
        offset: _pointInParentCoordinates(child, childRect.topLeft).dx,
        node: child,
      ));
      edges.add(_BoxEdge(
        isLeadingEdge: false,
        offset: _pointInParentCoordinates(child, childRect.bottomRight).dx,
        node: child,
      ));
    }
    edges.sort();

    List<_SemanticsSortGroup> horizontalGroups = <_SemanticsSortGroup>[];
    _SemanticsSortGroup group;
    int depth = 0;
    for (_BoxEdge edge in edges) {
      if (edge.isLeadingEdge) {
        depth += 1;
        group ??= _SemanticsSortGroup(
          startOffset: edge.offset,
          textDirection: textDirection,
        );
        group.nodes.add(edge.node);
      } else {
        depth -= 1;
      }
      if (depth == 0) {
        horizontalGroups.add(group);
        group = null;
      }
    }
    horizontalGroups.sort();

    if (textDirection == TextDirection.rtl) {
      horizontalGroups = horizontalGroups.reversed.toList();
    }

    return horizontalGroups
        .expand((_SemanticsSortGroup group) => group.sortedWithinKnot())
        .toList();
  }

  List<SemanticsNode> sortedWithinKnot() {
    if (nodes.length <= 1) {
      return nodes;
    }
    final Map<int, SemanticsNode> nodeMap = <int, SemanticsNode>{};
    final Map<int, int> edges = <int, int>{};
    for (SemanticsNode node in nodes) {
      nodeMap[node.id] = node;
      final Offset center = _pointInParentCoordinates(node, node.rect.center);
      for (SemanticsNode nextNode in nodes) {
        if (identical(node, nextNode) || edges[nextNode.id] == node.id) {
          continue;
        }

        final Offset nextCenter =
            _pointInParentCoordinates(nextNode, nextNode.rect.center);
        final Offset centerDelta = nextCenter - center;

        final double direction = centerDelta.direction;
        final bool isLtrAndForward = textDirection == TextDirection.ltr &&
            -math.pi / 4 < direction &&
            direction < 3 * math.pi / 4;
        final bool isRtlAndForward = textDirection == TextDirection.rtl &&
            (direction < -3 * math.pi / 4 || direction > 3 * math.pi / 4);
        if (isLtrAndForward || isRtlAndForward) {
          edges[node.id] = nextNode.id;
        }
      }
    }

    final List<int> sortedIds = <int>[];
    final Set<int> visitedIds = <int>{};
    final List<SemanticsNode> startNodes = nodes.toList()
      ..sort((SemanticsNode a, SemanticsNode b) {
        final Offset aTopLeft = _pointInParentCoordinates(a, a.rect.topLeft);
        final Offset bTopLeft = _pointInParentCoordinates(b, b.rect.topLeft);
        final int verticalDiff = aTopLeft.dy.compareTo(bTopLeft.dy);
        if (verticalDiff != 0) {
          return -verticalDiff;
        }
        return -aTopLeft.dx.compareTo(bTopLeft.dx);
      });

    void search(int id) {
      if (visitedIds.contains(id)) {
        return;
      }
      visitedIds.add(id);
      if (edges.containsKey(id)) {
        search(edges[id]);
      }
      sortedIds.add(id);
    }

    startNodes.map<int>((SemanticsNode node) => node.id).forEach(search);
    return sortedIds
        .map<SemanticsNode>((int id) => nodeMap[id])
        .toList()
        .reversed
        .toList();
  }
}

Offset _pointInParentCoordinates(SemanticsNode node, Offset point) {
  if (node.transform == null) {
    return point;
  }
  final Vector3 vector = Vector3(point.dx, point.dy, 0.0);
  node.transform.transform3(vector);
  return Offset(vector.x, vector.y);
}

List<SemanticsNode> _childrenInDefaultOrder(
    List<SemanticsNode> children, TextDirection textDirection) {
  final List<_BoxEdge> edges = <_BoxEdge>[];
  for (SemanticsNode child in children) {
    assert(child.rect.isFinite);

    final Rect childRect = child.rect.deflate(0.1);
    edges.add(_BoxEdge(
      isLeadingEdge: true,
      offset: _pointInParentCoordinates(child, childRect.topLeft).dy,
      node: child,
    ));
    edges.add(_BoxEdge(
      isLeadingEdge: false,
      offset: _pointInParentCoordinates(child, childRect.bottomRight).dy,
      node: child,
    ));
  }
  edges.sort();

  final List<_SemanticsSortGroup> verticalGroups = <_SemanticsSortGroup>[];
  _SemanticsSortGroup group;
  int depth = 0;
  for (_BoxEdge edge in edges) {
    if (edge.isLeadingEdge) {
      depth += 1;
      group ??= _SemanticsSortGroup(
        startOffset: edge.offset,
        textDirection: textDirection,
      );
      group.nodes.add(edge.node);
    } else {
      depth -= 1;
    }
    if (depth == 0) {
      verticalGroups.add(group);
      group = null;
    }
  }
  verticalGroups.sort();

  return verticalGroups
      .expand((_SemanticsSortGroup group) => group.sortedWithinVerticalGroup())
      .toList();
}

class _TraversalSortNode implements Comparable<_TraversalSortNode> {
  _TraversalSortNode({
    @required this.node,
    this.sortKey,
    @required this.position,
  })  : assert(node != null),
        assert(position != null);

  final SemanticsNode node;

  final SemanticsSortKey sortKey;

  final int position;

  @override
  int compareTo(_TraversalSortNode other) {
    if (sortKey == null || other?.sortKey == null) {
      return position - other.position;
    }
    return sortKey.compareTo(other.sortKey);
  }
}

class SemanticsOwner extends ChangeNotifier {
  final Set<SemanticsNode> _dirtyNodes = <SemanticsNode>{};
  final Map<int, SemanticsNode> _nodes = <int, SemanticsNode>{};
  final Set<SemanticsNode> _detachedNodes = <SemanticsNode>{};
  final Map<int, CustomSemanticsAction> _actions =
      <int, CustomSemanticsAction>{};

  SemanticsNode get rootSemanticsNode => _nodes[0];

  @override
  void dispose() {
    _dirtyNodes.clear();
    _nodes.clear();
    _detachedNodes.clear();
    super.dispose();
  }

  void sendSemanticsUpdate() {
    if (_dirtyNodes.isEmpty) return;
    final Set<int> customSemanticsActionIds = <int>{};
    final List<SemanticsNode> visitedNodes = <SemanticsNode>[];
    while (_dirtyNodes.isNotEmpty) {
      final List<SemanticsNode> localDirtyNodes = _dirtyNodes
          .where((SemanticsNode node) => !_detachedNodes.contains(node))
          .toList();
      _dirtyNodes.clear();
      _detachedNodes.clear();
      localDirtyNodes
          .sort((SemanticsNode a, SemanticsNode b) => a.depth - b.depth);
      visitedNodes.addAll(localDirtyNodes);
      for (SemanticsNode node in localDirtyNodes) {
        assert(node._dirty);
        assert(node.parent == null ||
            !node.parent.isPartOfNodeMerging ||
            node.isMergedIntoParent);
        if (node.isPartOfNodeMerging) {
          assert(node.mergeAllDescendantsIntoThisNode || node.parent != null);

          if (node.parent != null && node.parent.isPartOfNodeMerging)
            node.parent._markDirty();
        }
      }
    }
    visitedNodes.sort((SemanticsNode a, SemanticsNode b) => a.depth - b.depth);
    final ui.SemanticsUpdateBuilder builder = ui.SemanticsUpdateBuilder();
    for (SemanticsNode node in visitedNodes) {
      assert(node.parent?._dirty != true);

      if (node._dirty && node.attached)
        node._addToUpdate(builder, customSemanticsActionIds);
    }
    _dirtyNodes.clear();
    for (int actionId in customSemanticsActionIds) {
      final CustomSemanticsAction action =
          CustomSemanticsAction.getAction(actionId);
      builder.updateCustomAction(
          id: actionId,
          label: action.label,
          hint: action.hint,
          overrideId: action.action?.index ?? -1);
    }
    SemanticsBinding.instance.window.updateSemantics(builder.build());
    notifyListeners();
  }

  _SemanticsActionHandler _getSemanticsActionHandlerForId(
      int id, SemanticsAction action) {
    SemanticsNode result = _nodes[id];
    if (result != null &&
        result.isPartOfNodeMerging &&
        !result._canPerformAction(action)) {
      result._visitDescendants((SemanticsNode node) {
        if (node._canPerformAction(action)) {
          result = node;
          return false;
        }
        return true;
      });
    }
    if (result == null || !result._canPerformAction(action)) return null;
    return result._actions[action];
  }

  void performAction(int id, SemanticsAction action, [dynamic args]) {
    assert(action != null);
    final _SemanticsActionHandler handler =
        _getSemanticsActionHandlerForId(id, action);
    if (handler != null) {
      handler(args);
      return;
    }

    if (action == SemanticsAction.showOnScreen &&
        _nodes[id]._showOnScreen != null) _nodes[id]._showOnScreen();
  }

  _SemanticsActionHandler _getSemanticsActionHandlerForPosition(
      SemanticsNode node, Offset position, SemanticsAction action) {
    if (node.transform != null) {
      final Matrix4 inverse = Matrix4.identity();
      if (inverse.copyInverse(node.transform) == 0.0) return null;
      position = MatrixUtils.transformPoint(inverse, position);
    }
    if (!node.rect.contains(position)) return null;
    if (node.mergeAllDescendantsIntoThisNode) {
      SemanticsNode result;
      node._visitDescendants((SemanticsNode child) {
        if (child._canPerformAction(action)) {
          result = child;
          return false;
        }
        return true;
      });
      return result?._actions[action];
    }
    if (node.hasChildren) {
      for (SemanticsNode child in node._children.reversed) {
        final _SemanticsActionHandler handler =
            _getSemanticsActionHandlerForPosition(child, position, action);
        if (handler != null) return handler;
      }
    }
    return node._actions[action];
  }

  void performActionAt(Offset position, SemanticsAction action,
      [dynamic args]) {
    assert(action != null);
    final SemanticsNode node = rootSemanticsNode;
    if (node == null) return;
    final _SemanticsActionHandler handler =
        _getSemanticsActionHandlerForPosition(node, position, action);
    if (handler != null) handler(args);
  }

  @override
  String toString() => describeIdentity(this);
}

class SemanticsConfiguration {
  bool get isSemanticBoundary => _isSemanticBoundary;
  bool _isSemanticBoundary = false;
  set isSemanticBoundary(bool value) {
    assert(!isMergingSemanticsOfDescendants || value);
    _isSemanticBoundary = value;
  }

  bool explicitChildNodes = false;

  bool isBlockingSemanticsOfPreviouslyPaintedNodes = false;

  bool get hasBeenAnnotated => _hasBeenAnnotated;
  bool _hasBeenAnnotated = false;

  final Map<SemanticsAction, _SemanticsActionHandler> _actions =
      <SemanticsAction, _SemanticsActionHandler>{};

  int _actionsAsBits = 0;

  void _addAction(SemanticsAction action, _SemanticsActionHandler handler) {
    assert(handler != null);
    _actions[action] = handler;
    _actionsAsBits |= action.index;
    _hasBeenAnnotated = true;
  }

  void _addArgumentlessAction(SemanticsAction action, VoidCallback handler) {
    assert(handler != null);
    _addAction(action, (dynamic args) {
      assert(args == null);
      handler();
    });
  }

  VoidCallback get onTap => _onTap;
  VoidCallback _onTap;
  set onTap(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.tap, value);
    _onTap = value;
  }

  VoidCallback get onLongPress => _onLongPress;
  VoidCallback _onLongPress;
  set onLongPress(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.longPress, value);
    _onLongPress = value;
  }

  VoidCallback get onScrollLeft => _onScrollLeft;
  VoidCallback _onScrollLeft;
  set onScrollLeft(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.scrollLeft, value);
    _onScrollLeft = value;
  }

  VoidCallback get onDismiss => _onDismiss;
  VoidCallback _onDismiss;
  set onDismiss(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.dismiss, value);
    _onDismiss = value;
  }

  VoidCallback get onScrollRight => _onScrollRight;
  VoidCallback _onScrollRight;
  set onScrollRight(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.scrollRight, value);
    _onScrollRight = value;
  }

  VoidCallback get onScrollUp => _onScrollUp;
  VoidCallback _onScrollUp;
  set onScrollUp(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.scrollUp, value);
    _onScrollUp = value;
  }

  VoidCallback get onScrollDown => _onScrollDown;
  VoidCallback _onScrollDown;
  set onScrollDown(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.scrollDown, value);
    _onScrollDown = value;
  }

  VoidCallback get onIncrease => _onIncrease;
  VoidCallback _onIncrease;
  set onIncrease(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.increase, value);
    _onIncrease = value;
  }

  VoidCallback get onDecrease => _onDecrease;
  VoidCallback _onDecrease;
  set onDecrease(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.decrease, value);
    _onDecrease = value;
  }

  VoidCallback get onCopy => _onCopy;
  VoidCallback _onCopy;
  set onCopy(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.copy, value);
    _onCopy = value;
  }

  VoidCallback get onCut => _onCut;
  VoidCallback _onCut;
  set onCut(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.cut, value);
    _onCut = value;
  }

  VoidCallback get onPaste => _onPaste;
  VoidCallback _onPaste;
  set onPaste(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.paste, value);
    _onPaste = value;
  }

  VoidCallback get onShowOnScreen => _onShowOnScreen;
  VoidCallback _onShowOnScreen;
  set onShowOnScreen(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.showOnScreen, value);
    _onShowOnScreen = value;
  }

  MoveCursorHandler get onMoveCursorForwardByCharacter =>
      _onMoveCursorForwardByCharacter;
  MoveCursorHandler _onMoveCursorForwardByCharacter;
  set onMoveCursorForwardByCharacter(MoveCursorHandler value) {
    assert(value != null);
    _addAction(SemanticsAction.moveCursorForwardByCharacter, (dynamic args) {
      final bool extentSelection = args;
      assert(extentSelection != null);
      value(extentSelection);
    });
    _onMoveCursorForwardByCharacter = value;
  }

  MoveCursorHandler get onMoveCursorBackwardByCharacter =>
      _onMoveCursorBackwardByCharacter;
  MoveCursorHandler _onMoveCursorBackwardByCharacter;
  set onMoveCursorBackwardByCharacter(MoveCursorHandler value) {
    assert(value != null);
    _addAction(SemanticsAction.moveCursorBackwardByCharacter, (dynamic args) {
      final bool extentSelection = args;
      assert(extentSelection != null);
      value(extentSelection);
    });
    _onMoveCursorBackwardByCharacter = value;
  }

  MoveCursorHandler get onMoveCursorForwardByWord => _onMoveCursorForwardByWord;
  MoveCursorHandler _onMoveCursorForwardByWord;
  set onMoveCursorForwardByWord(MoveCursorHandler value) {
    assert(value != null);
    _addAction(SemanticsAction.moveCursorForwardByWord, (dynamic args) {
      final bool extentSelection = args;
      assert(extentSelection != null);
      value(extentSelection);
    });
    _onMoveCursorForwardByCharacter = value;
  }

  MoveCursorHandler get onMoveCursorBackwardByWord =>
      _onMoveCursorBackwardByWord;
  MoveCursorHandler _onMoveCursorBackwardByWord;
  set onMoveCursorBackwardByWord(MoveCursorHandler value) {
    assert(value != null);
    _addAction(SemanticsAction.moveCursorBackwardByWord, (dynamic args) {
      final bool extentSelection = args;
      assert(extentSelection != null);
      value(extentSelection);
    });
    _onMoveCursorBackwardByCharacter = value;
  }

  SetSelectionHandler get onSetSelection => _onSetSelection;
  SetSelectionHandler _onSetSelection;
  set onSetSelection(SetSelectionHandler value) {
    assert(value != null);
    _addAction(SemanticsAction.setSelection, (dynamic args) {
      assert(args != null && args is Map);
      final Map<String, int> selection = args.cast<String, int>();
      assert(selection != null &&
          selection['base'] != null &&
          selection['extent'] != null);
      value(TextSelection(
        baseOffset: selection['base'],
        extentOffset: selection['extent'],
      ));
    });
    _onSetSelection = value;
  }

  VoidCallback get onDidGainAccessibilityFocus => _onDidGainAccessibilityFocus;
  VoidCallback _onDidGainAccessibilityFocus;
  set onDidGainAccessibilityFocus(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.didGainAccessibilityFocus, value);
    _onDidGainAccessibilityFocus = value;
  }

  VoidCallback get onDidLoseAccessibilityFocus => _onDidLoseAccessibilityFocus;
  VoidCallback _onDidLoseAccessibilityFocus;
  set onDidLoseAccessibilityFocus(VoidCallback value) {
    _addArgumentlessAction(SemanticsAction.didLoseAccessibilityFocus, value);
    _onDidLoseAccessibilityFocus = value;
  }

  _SemanticsActionHandler getActionHandler(SemanticsAction action) =>
      _actions[action];

  SemanticsSortKey get sortKey => _sortKey;
  SemanticsSortKey _sortKey;
  set sortKey(SemanticsSortKey value) {
    assert(value != null);
    _sortKey = value;
    _hasBeenAnnotated = true;
  }

  int get indexInParent => _indexInParent;
  int _indexInParent;
  set indexInParent(int value) {
    _indexInParent = value;
    _hasBeenAnnotated = true;
  }

  int get scrollChildCount => _scrollChildCount;
  int _scrollChildCount;
  set scrollChildCount(int value) {
    if (value == scrollChildCount) return;
    _scrollChildCount = value;
    _hasBeenAnnotated = true;
  }

  int get scrollIndex => _scrollIndex;
  int _scrollIndex;
  set scrollIndex(int value) {
    if (value == scrollIndex) return;
    _scrollIndex = value;
    _hasBeenAnnotated = true;
  }

  int get platformViewId => _platformViewId;
  int _platformViewId;
  set platformViewId(int value) {
    if (value == platformViewId) return;
    _platformViewId = value;
    _hasBeenAnnotated = true;
  }

  bool get isMergingSemanticsOfDescendants => _isMergingSemanticsOfDescendants;
  bool _isMergingSemanticsOfDescendants = false;
  set isMergingSemanticsOfDescendants(bool value) {
    assert(isSemanticBoundary);
    _isMergingSemanticsOfDescendants = value;
    _hasBeenAnnotated = true;
  }

  Map<CustomSemanticsAction, VoidCallback> get customSemanticsActions =>
      _customSemanticsActions;
  Map<CustomSemanticsAction, VoidCallback> _customSemanticsActions =
      <CustomSemanticsAction, VoidCallback>{};
  set customSemanticsActions(Map<CustomSemanticsAction, VoidCallback> value) {
    _hasBeenAnnotated = true;
    _actionsAsBits |= SemanticsAction.customAction.index;
    _customSemanticsActions = value;
    _actions[SemanticsAction.customAction] = _onCustomSemanticsAction;
  }

  void _onCustomSemanticsAction(dynamic args) {
    final CustomSemanticsAction action = CustomSemanticsAction.getAction(args);
    if (action == null) return;
    final VoidCallback callback = _customSemanticsActions[action];
    if (callback != null) callback();
  }

  String get label => _label;
  String _label = '';
  set label(String label) {
    assert(label != null);
    _label = label;
    _hasBeenAnnotated = true;
  }

  String get value => _value;
  String _value = '';
  set value(String value) {
    assert(value != null);
    _value = value;
    _hasBeenAnnotated = true;
  }

  String get decreasedValue => _decreasedValue;
  String _decreasedValue = '';
  set decreasedValue(String decreasedValue) {
    assert(decreasedValue != null);
    _decreasedValue = decreasedValue;
    _hasBeenAnnotated = true;
  }

  String get increasedValue => _increasedValue;
  String _increasedValue = '';
  set increasedValue(String increasedValue) {
    assert(increasedValue != null);
    _increasedValue = increasedValue;
    _hasBeenAnnotated = true;
  }

  String get hint => _hint;
  String _hint = '';
  set hint(String hint) {
    assert(hint != null);
    _hint = hint;
    _hasBeenAnnotated = true;
  }

  SemanticsHintOverrides get hintOverrides => _hintOverrides;
  SemanticsHintOverrides _hintOverrides;
  set hintOverrides(SemanticsHintOverrides value) {
    if (value == null) return;
    _hintOverrides = value;
    _hasBeenAnnotated = true;
  }

  double get elevation => _elevation;
  double _elevation = 0.0;
  set elevation(double value) {
    assert(value != null && value >= 0.0);
    if (value == _elevation) {
      return;
    }
    _elevation = value;
    _hasBeenAnnotated = true;
  }

  double get thickness => _thickness;
  double _thickness = 0.0;
  set thickness(double value) {
    assert(value != null && value >= 0.0);
    if (value == _thickness) {
      return;
    }
    _thickness = value;
    _hasBeenAnnotated = true;
  }

  bool get scopesRoute => _hasFlag(SemanticsFlag.scopesRoute);
  set scopesRoute(bool value) {
    _setFlag(SemanticsFlag.scopesRoute, value);
  }

  bool get namesRoute => _hasFlag(SemanticsFlag.namesRoute);
  set namesRoute(bool value) {
    _setFlag(SemanticsFlag.namesRoute, value);
  }

  bool get isImage => _hasFlag(SemanticsFlag.isImage);
  set isImage(bool value) {
    _setFlag(SemanticsFlag.isImage, value);
  }

  bool get liveRegion => _hasFlag(SemanticsFlag.isLiveRegion);
  set liveRegion(bool value) {
    _setFlag(SemanticsFlag.isLiveRegion, value);
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection textDirection) {
    _textDirection = textDirection;
    _hasBeenAnnotated = true;
  }

  bool get isSelected => _hasFlag(SemanticsFlag.isSelected);
  set isSelected(bool value) {
    _setFlag(SemanticsFlag.isSelected, value);
  }

  bool get isEnabled => _hasFlag(SemanticsFlag.hasEnabledState)
      ? _hasFlag(SemanticsFlag.isEnabled)
      : null;
  set isEnabled(bool value) {
    _setFlag(SemanticsFlag.hasEnabledState, true);
    _setFlag(SemanticsFlag.isEnabled, value);
  }

  bool get isChecked => _hasFlag(SemanticsFlag.hasCheckedState)
      ? _hasFlag(SemanticsFlag.isChecked)
      : null;
  set isChecked(bool value) {
    _setFlag(SemanticsFlag.hasCheckedState, true);
    _setFlag(SemanticsFlag.isChecked, value);
  }

  bool get isToggled => _hasFlag(SemanticsFlag.hasToggledState)
      ? _hasFlag(SemanticsFlag.isToggled)
      : null;
  set isToggled(bool value) {
    _setFlag(SemanticsFlag.hasToggledState, true);
    _setFlag(SemanticsFlag.isToggled, value);
  }

  bool get isInMutuallyExclusiveGroup =>
      _hasFlag(SemanticsFlag.isInMutuallyExclusiveGroup);
  set isInMutuallyExclusiveGroup(bool value) {
    _setFlag(SemanticsFlag.isInMutuallyExclusiveGroup, value);
  }

  bool get isFocused => _hasFlag(SemanticsFlag.isFocused);
  set isFocused(bool value) {
    _setFlag(SemanticsFlag.isFocused, value);
  }

  bool get isButton => _hasFlag(SemanticsFlag.isButton);
  set isButton(bool value) {
    _setFlag(SemanticsFlag.isButton, value);
  }

  bool get isHeader => _hasFlag(SemanticsFlag.isHeader);
  set isHeader(bool value) {
    _setFlag(SemanticsFlag.isHeader, value);
  }

  bool get isHidden => _hasFlag(SemanticsFlag.isHidden);
  set isHidden(bool value) {
    _setFlag(SemanticsFlag.isHidden, value);
  }

  bool get isTextField => _hasFlag(SemanticsFlag.isTextField);
  set isTextField(bool value) {
    _setFlag(SemanticsFlag.isTextField, value);
  }

  bool get isReadOnly => _hasFlag(SemanticsFlag.isReadOnly);
  set isReadOnly(bool value) {
    _setFlag(SemanticsFlag.isReadOnly, value);
  }

  bool get isObscured => _hasFlag(SemanticsFlag.isObscured);
  set isObscured(bool value) {
    _setFlag(SemanticsFlag.isObscured, value);
  }

  bool get isMultiline => _hasFlag(SemanticsFlag.isMultiline);
  set isMultiline(bool value) {
    _setFlag(SemanticsFlag.isMultiline, value);
  }

  bool get hasImplicitScrolling => _hasFlag(SemanticsFlag.hasImplicitScrolling);
  set hasImplicitScrolling(bool value) {
    _setFlag(SemanticsFlag.hasImplicitScrolling, value);
  }

  TextSelection get textSelection => _textSelection;
  TextSelection _textSelection;
  set textSelection(TextSelection value) {
    assert(value != null);
    _textSelection = value;
    _hasBeenAnnotated = true;
  }

  double get scrollPosition => _scrollPosition;
  double _scrollPosition;
  set scrollPosition(double value) {
    assert(value != null);
    _scrollPosition = value;
    _hasBeenAnnotated = true;
  }

  double get scrollExtentMax => _scrollExtentMax;
  double _scrollExtentMax;
  set scrollExtentMax(double value) {
    assert(value != null);
    _scrollExtentMax = value;
    _hasBeenAnnotated = true;
  }

  double get scrollExtentMin => _scrollExtentMin;
  double _scrollExtentMin;
  set scrollExtentMin(double value) {
    assert(value != null);
    _scrollExtentMin = value;
    _hasBeenAnnotated = true;
  }

  Iterable<SemanticsTag> get tagsForChildren => _tagsForChildren;
  Set<SemanticsTag> _tagsForChildren;

  void addTagForChildren(SemanticsTag tag) {
    _tagsForChildren ??= <SemanticsTag>{};
    _tagsForChildren.add(tag);
  }

  int _flags = 0;
  void _setFlag(SemanticsFlag flag, bool value) {
    if (value) {
      _flags |= flag.index;
    } else {
      _flags &= ~flag.index;
    }
    _hasBeenAnnotated = true;
  }

  bool _hasFlag(SemanticsFlag flag) => (_flags & flag.index) != 0;

  bool isCompatibleWith(SemanticsConfiguration other) {
    if (other == null || !other.hasBeenAnnotated || !hasBeenAnnotated)
      return true;
    if (_actionsAsBits & other._actionsAsBits != 0) return false;
    if ((_flags & other._flags) != 0) return false;
    if (_platformViewId != null && other._platformViewId != null) {
      return false;
    }
    if (_value != null &&
        _value.isNotEmpty &&
        other._value != null &&
        other._value.isNotEmpty) return false;
    return true;
  }

  void absorb(SemanticsConfiguration child) {
    assert(!explicitChildNodes);

    if (!child.hasBeenAnnotated) return;

    _actions.addAll(child._actions);
    _customSemanticsActions.addAll(child._customSemanticsActions);
    _actionsAsBits |= child._actionsAsBits;
    _flags |= child._flags;
    _textSelection ??= child._textSelection;
    _scrollPosition ??= child._scrollPosition;
    _scrollExtentMax ??= child._scrollExtentMax;
    _scrollExtentMin ??= child._scrollExtentMin;
    _hintOverrides ??= child._hintOverrides;
    _indexInParent ??= child.indexInParent;
    _scrollIndex ??= child._scrollIndex;
    _scrollChildCount ??= child._scrollChildCount;
    _platformViewId ??= child._platformViewId;

    textDirection ??= child.textDirection;
    _sortKey ??= child._sortKey;
    _label = _concatStrings(
      thisString: _label,
      thisTextDirection: textDirection,
      otherString: child._label,
      otherTextDirection: child.textDirection,
    );
    if (_decreasedValue == '' || _decreasedValue == null)
      _decreasedValue = child._decreasedValue;
    if (_value == '' || _value == null) _value = child._value;
    if (_increasedValue == '' || _increasedValue == null)
      _increasedValue = child._increasedValue;
    _hint = _concatStrings(
      thisString: _hint,
      thisTextDirection: textDirection,
      otherString: child._hint,
      otherTextDirection: child.textDirection,
    );

    _thickness = math.max(_thickness, child._thickness + child._elevation);

    _hasBeenAnnotated = _hasBeenAnnotated || child._hasBeenAnnotated;
  }

  SemanticsConfiguration copy() {
    return SemanticsConfiguration()
      .._isSemanticBoundary = _isSemanticBoundary
      ..explicitChildNodes = explicitChildNodes
      ..isBlockingSemanticsOfPreviouslyPaintedNodes =
          isBlockingSemanticsOfPreviouslyPaintedNodes
      .._hasBeenAnnotated = _hasBeenAnnotated
      .._isMergingSemanticsOfDescendants = _isMergingSemanticsOfDescendants
      .._textDirection = _textDirection
      .._sortKey = _sortKey
      .._label = _label
      .._increasedValue = _increasedValue
      .._value = _value
      .._decreasedValue = _decreasedValue
      .._hint = _hint
      .._hintOverrides = _hintOverrides
      .._elevation = _elevation
      .._thickness = _thickness
      .._flags = _flags
      .._tagsForChildren = _tagsForChildren
      .._textSelection = _textSelection
      .._scrollPosition = _scrollPosition
      .._scrollExtentMax = _scrollExtentMax
      .._scrollExtentMin = _scrollExtentMin
      .._actionsAsBits = _actionsAsBits
      .._indexInParent = indexInParent
      .._scrollIndex = _scrollIndex
      .._scrollChildCount = _scrollChildCount
      .._platformViewId = _platformViewId
      .._actions.addAll(_actions)
      .._customSemanticsActions.addAll(_customSemanticsActions);
  }
}

enum DebugSemanticsDumpOrder {
  inverseHitTest,

  traversalOrder,
}

String _concatStrings({
  @required String thisString,
  @required String otherString,
  @required TextDirection thisTextDirection,
  @required TextDirection otherTextDirection,
}) {
  if (otherString.isEmpty) return thisString;
  String nestedLabel = otherString;
  if (thisTextDirection != otherTextDirection && otherTextDirection != null) {
    switch (otherTextDirection) {
      case TextDirection.rtl:
        nestedLabel = '${Unicode.RLE}$nestedLabel${Unicode.PDF}';
        break;
      case TextDirection.ltr:
        nestedLabel = '${Unicode.LRE}$nestedLabel${Unicode.PDF}';
        break;
    }
  }
  if (thisString.isEmpty) return nestedLabel;
  return '$thisString\n$nestedLabel';
}

abstract class SemanticsSortKey extends Diagnosticable
    implements Comparable<SemanticsSortKey> {
  const SemanticsSortKey({this.name});

  final String name;

  @override
  int compareTo(SemanticsSortKey other) {
    assert(runtimeType == other.runtimeType);
    assert(name == other.name);
    return doCompare(other);
  }

  @protected
  int doCompare(covariant SemanticsSortKey other);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('name', name, defaultValue: null));
  }
}

class OrdinalSortKey extends SemanticsSortKey {
  const OrdinalSortKey(
    this.order, {
    String name,
  })  : assert(order != null),
        assert(order != double.nan),
        assert(order > double.negativeInfinity),
        assert(order < double.infinity),
        super(name: name);

  final double order;

  @override
  int doCompare(OrdinalSortKey other) {
    if (other.order == null || order == null || other.order == order) return 0;
    return order.compareTo(other.order);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('order', order, defaultValue: null));
  }
}

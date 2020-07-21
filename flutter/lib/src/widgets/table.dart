import 'dart:collection';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'image.dart';

export 'package:flutter_web/rendering.dart'
    show
        FixedColumnWidth,
        FlexColumnWidth,
        FractionColumnWidth,
        IntrinsicColumnWidth,
        MaxColumnWidth,
        MinColumnWidth,
        TableBorder,
        TableCellVerticalAlignment,
        TableColumnWidth;

@immutable
class TableRow {
  const TableRow({this.key, this.decoration, this.children});

  final LocalKey key;

  final Decoration decoration;

  final List<Widget> children;

  @override
  String toString() {
    final StringBuffer result = StringBuffer();
    result.write('TableRow(');
    if (key != null) result.write('$key, ');
    if (decoration != null) result.write('$decoration, ');
    if (children == null) {
      result.write('child list is null');
    } else if (children.isEmpty) {
      result.write('no children');
    } else {
      result.write('$children');
    }
    result.write(')');
    return result.toString();
  }
}

class _TableElementRow {
  const _TableElementRow({this.key, this.children});
  final LocalKey key;
  final List<Element> children;
}

class Table extends RenderObjectWidget {
  Table({
    Key key,
    this.children = const <TableRow>[],
    this.columnWidths,
    this.defaultColumnWidth = const FlexColumnWidth(1.0),
    this.textDirection,
    this.border,
    this.defaultVerticalAlignment = TableCellVerticalAlignment.top,
    this.textBaseline,
  })  : assert(children != null),
        assert(defaultColumnWidth != null),
        assert(defaultVerticalAlignment != null),
        assert(() {
          if (children.any((TableRow row) =>
              row.children.any((Widget cell) => cell == null))) {
            throw FlutterError(
                'One of the children of one of the rows of the table was null.\n'
                'The children of a TableRow must not be null.');
          }
          return true;
        }()),
        assert(() {
          if (children.any((TableRow row1) =>
              row1.key != null &&
              children.any(
                  (TableRow row2) => row1 != row2 && row1.key == row2.key))) {
            throw FlutterError(
                'Two or more TableRow children of this Table had the same key.\n'
                'All the keyed TableRow children of a Table must have different Keys.');
          }
          return true;
        }()),
        assert(() {
          if (children.isNotEmpty) {
            final int cellCount = children.first.children.length;
            if (children
                .any((TableRow row) => row.children.length != cellCount)) {
              throw FlutterError('Table contains irregular row lengths.\n'
                  'Every TableRow in a Table must have the same number of children, so that every cell is filled. '
                  'Otherwise, the table will contain holes.');
            }
          }
          return true;
        }()),
        _rowDecorations = children.any((TableRow row) => row.decoration != null)
            ? children
                .map<Decoration>((TableRow row) => row.decoration)
                .toList(growable: false)
            : null,
        super(key: key) {
    assert(() {
      final List<Widget> flatChildren = children
          .expand<Widget>((TableRow row) => row.children)
          .toList(growable: false);
      if (debugChildrenHaveDuplicateKeys(this, flatChildren)) {
        throw FlutterError(
            'Two or more cells in this Table contain widgets with the same key.\n'
            'Every widget child of every TableRow in a Table must have different keys. The cells of a Table are '
            'flattened out for processing, so separate cells cannot have duplicate keys even if they are in '
            'different rows.');
      }
      return true;
    }());
  }

  final List<TableRow> children;

  final Map<int, TableColumnWidth> columnWidths;

  final TableColumnWidth defaultColumnWidth;

  final TextDirection textDirection;

  final TableBorder border;

  final TableCellVerticalAlignment defaultVerticalAlignment;

  final TextBaseline textBaseline;

  final List<Decoration> _rowDecorations;

  @override
  _TableElement createElement() => _TableElement(this);

  @override
  RenderTable createRenderObject(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return RenderTable(
      columns: children.isNotEmpty ? children[0].children.length : 0,
      rows: children.length,
      columnWidths: columnWidths,
      defaultColumnWidth: defaultColumnWidth,
      textDirection: textDirection ?? Directionality.of(context),
      border: border,
      rowDecorations: _rowDecorations,
      configuration: createLocalImageConfiguration(context),
      defaultVerticalAlignment: defaultVerticalAlignment,
      textBaseline: textBaseline,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTable renderObject) {
    assert(debugCheckHasDirectionality(context));
    assert(renderObject.columns ==
        (children.isNotEmpty ? children[0].children.length : 0));
    assert(renderObject.rows == children.length);
    renderObject
      ..columnWidths = columnWidths
      ..defaultColumnWidth = defaultColumnWidth
      ..textDirection = textDirection ?? Directionality.of(context)
      ..border = border
      ..rowDecorations = _rowDecorations
      ..configuration = createLocalImageConfiguration(context)
      ..defaultVerticalAlignment = defaultVerticalAlignment
      ..textBaseline = textBaseline;
  }
}

class _TableElement extends RenderObjectElement {
  _TableElement(Table widget) : super(widget);

  @override
  Table get widget => super.widget;

  @override
  RenderTable get renderObject => super.renderObject;

  List<_TableElementRow> _children = const <_TableElementRow>[];

  bool _debugWillReattachChildren = false;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    assert(!_debugWillReattachChildren);
    assert(() {
      _debugWillReattachChildren = true;
      return true;
    }());
    _children = widget.children.map<_TableElementRow>((TableRow row) {
      return _TableElementRow(
          key: row.key,
          children: row.children.map<Element>((Widget child) {
            assert(child != null);
            return inflateWidget(child, null);
          }).toList(growable: false));
    }).toList(growable: false);
    assert(() {
      _debugWillReattachChildren = false;
      return true;
    }());
    _updateRenderObjectChildren();
  }

  @override
  void insertChildRenderObject(RenderObject child, Element slot) {
    assert(_debugWillReattachChildren);
    renderObject.setupParentData(child);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(_debugWillReattachChildren);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(() {
      if (_debugWillReattachChildren) return true;
      for (Element forgottenChild in _forgottenChildren) {
        if (forgottenChild.renderObject == child) return true;
      }
      return false;
    }());
    final TableCellParentData childParentData = child.parentData;
    renderObject.setChild(childParentData.x, childParentData.y, null);
  }

  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void update(Table newWidget) {
    assert(!_debugWillReattachChildren);
    assert(() {
      _debugWillReattachChildren = true;
      return true;
    }());
    final Map<LocalKey, List<Element>> oldKeyedRows =
        <LocalKey, List<Element>>{};
    for (_TableElementRow row in _children) {
      if (row.key != null) {
        oldKeyedRows[row.key] = row.children;
      }
    }
    final Iterator<_TableElementRow> oldUnkeyedRows =
        _children.where((_TableElementRow row) => row.key == null).iterator;
    final List<_TableElementRow> newChildren = <_TableElementRow>[];
    final Set<List<Element>> taken = Set<List<Element>>();
    for (TableRow row in newWidget.children) {
      List<Element> oldChildren;
      if (row.key != null && oldKeyedRows.containsKey(row.key)) {
        oldChildren = oldKeyedRows[row.key];
        taken.add(oldChildren);
      } else if (row.key == null && oldUnkeyedRows.moveNext()) {
        oldChildren = oldUnkeyedRows.current.children;
      } else {
        oldChildren = const <Element>[];
      }
      newChildren.add(_TableElementRow(
          key: row.key,
          children: updateChildren(oldChildren, row.children,
              forgottenChildren: _forgottenChildren)));
    }
    while (oldUnkeyedRows.moveNext())
      updateChildren(oldUnkeyedRows.current.children, const <Widget>[],
          forgottenChildren: _forgottenChildren);
    for (List<Element> oldChildren in oldKeyedRows.values
        .where((List<Element> list) => !taken.contains(list)))
      updateChildren(oldChildren, const <Widget>[],
          forgottenChildren: _forgottenChildren);
    assert(() {
      _debugWillReattachChildren = false;
      return true;
    }());
    _children = newChildren;
    _updateRenderObjectChildren();
    _forgottenChildren.clear();
    super.update(newWidget);
    assert(widget == newWidget);
  }

  void _updateRenderObjectChildren() {
    assert(renderObject != null);
    renderObject.setFlatChildren(
        _children.isNotEmpty ? _children[0].children.length : 0,
        _children.expand<RenderBox>((_TableElementRow row) {
          return row.children.map<RenderBox>((Element child) {
            final RenderBox box = child.renderObject;
            return box;
          });
        }).toList());
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element child
        in _children.expand<Element>((_TableElementRow row) => row.children)) {
      if (!_forgottenChildren.contains(child)) visitor(child);
    }
  }

  @override
  bool forgetChild(Element child) {
    _forgottenChildren.add(child);
    return true;
  }
}

class TableCell extends ParentDataWidget<Table> {
  const TableCell({Key key, this.verticalAlignment, @required Widget child})
      : super(key: key, child: child);

  final TableCellVerticalAlignment verticalAlignment;

  @override
  void applyParentData(RenderObject renderObject) {
    final TableCellParentData parentData = renderObject.parentData;
    if (parentData.verticalAlignment != verticalAlignment) {
      parentData.verticalAlignment = verticalAlignment;
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TableCellVerticalAlignment>(
        'verticalAlignment', verticalAlignment));
  }
}

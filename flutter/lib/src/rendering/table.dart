import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';

import 'box.dart';
import 'object.dart';
import 'table_border.dart';

class TableCellParentData extends BoxParentData {
  TableCellVerticalAlignment verticalAlignment;

  int x;

  int y;

  @override
  String toString() =>
      '${super.toString()}; ${verticalAlignment == null ? "default vertical alignment" : "$verticalAlignment"}';
}

@immutable
abstract class TableColumnWidth {
  const TableColumnWidth();

  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth);

  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth);

  double flex(Iterable<RenderBox> cells) => null;

  @override
  String toString() => '$runtimeType';
}

class IntrinsicColumnWidth extends TableColumnWidth {
  const IntrinsicColumnWidth({double flex}) : _flex = flex;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    double result = 0.0;
    for (RenderBox cell in cells)
      result = math.max(result, cell.getMinIntrinsicWidth(double.infinity));
    return result;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    double result = 0.0;
    for (RenderBox cell in cells)
      result = math.max(result, cell.getMaxIntrinsicWidth(double.infinity));
    return result;
  }

  final double _flex;

  @override
  double flex(Iterable<RenderBox> cells) => _flex;

  @override
  String toString() => '$runtimeType(flex: ${_flex?.toStringAsFixed(1)})';
}

class FixedColumnWidth extends TableColumnWidth {
  const FixedColumnWidth(this.value) : assert(value != null);

  final double value;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return value;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return value;
  }

  @override
  String toString() => '$runtimeType($value)';
}

class FractionColumnWidth extends TableColumnWidth {
  const FractionColumnWidth(this.value) : assert(value != null);

  final double value;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    if (!containerWidth.isFinite) return 0.0;
    return value * containerWidth;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    if (!containerWidth.isFinite) return 0.0;
    return value * containerWidth;
  }

  @override
  String toString() => '$runtimeType($value)';
}

class FlexColumnWidth extends TableColumnWidth {
  const FlexColumnWidth([this.value = 1.0]) : assert(value != null);

  final double value;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return 0.0;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return 0.0;
  }

  @override
  double flex(Iterable<RenderBox> cells) {
    return value;
  }

  @override
  String toString() => '$runtimeType(${debugFormatDouble(value)})';
}

class MaxColumnWidth extends TableColumnWidth {
  const MaxColumnWidth(this.a, this.b);

  final TableColumnWidth a;

  final TableColumnWidth b;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.max(
      a.minIntrinsicWidth(cells, containerWidth),
      b.minIntrinsicWidth(cells, containerWidth),
    );
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.max(
      a.maxIntrinsicWidth(cells, containerWidth),
      b.maxIntrinsicWidth(cells, containerWidth),
    );
  }

  @override
  double flex(Iterable<RenderBox> cells) {
    final double aFlex = a.flex(cells);
    if (aFlex == null) return b.flex(cells);
    final double bFlex = b.flex(cells);
    if (bFlex == null) return null;
    return math.max(aFlex, bFlex);
  }

  @override
  String toString() => '$runtimeType($a, $b)';
}

class MinColumnWidth extends TableColumnWidth {
  const MinColumnWidth(this.a, this.b);

  final TableColumnWidth a;

  final TableColumnWidth b;

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.min(
      a.minIntrinsicWidth(cells, containerWidth),
      b.minIntrinsicWidth(cells, containerWidth),
    );
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    return math.min(
      a.maxIntrinsicWidth(cells, containerWidth),
      b.maxIntrinsicWidth(cells, containerWidth),
    );
  }

  @override
  double flex(Iterable<RenderBox> cells) {
    final double aFlex = a.flex(cells);
    if (aFlex == null) return b.flex(cells);
    final double bFlex = b.flex(cells);
    if (bFlex == null) return null;
    return math.min(aFlex, bFlex);
  }

  @override
  String toString() => '$runtimeType($a, $b)';
}

enum TableCellVerticalAlignment {
  top,

  middle,

  bottom,

  baseline,

  fill
}

class RenderTable extends RenderBox {
  RenderTable({
    int columns,
    int rows,
    Map<int, TableColumnWidth> columnWidths,
    TableColumnWidth defaultColumnWidth = const FlexColumnWidth(1.0),
    @required TextDirection textDirection,
    TableBorder border,
    List<Decoration> rowDecorations,
    ImageConfiguration configuration = ImageConfiguration.empty,
    TableCellVerticalAlignment defaultVerticalAlignment =
        TableCellVerticalAlignment.top,
    TextBaseline textBaseline,
    List<List<RenderBox>> children,
  })  : assert(columns == null || columns >= 0),
        assert(rows == null || rows >= 0),
        assert(rows == null || children == null),
        assert(defaultColumnWidth != null),
        assert(textDirection != null),
        assert(configuration != null),
        _textDirection = textDirection {
    _columns = columns ??
        (children != null && children.isNotEmpty ? children.first.length : 0);
    _rows = rows ?? 0;
    _children = <RenderBox>[]..length = _columns * _rows;
    _columnWidths = columnWidths ?? HashMap<int, TableColumnWidth>();
    _defaultColumnWidth = defaultColumnWidth;
    _border = border;
    this.rowDecorations = rowDecorations;
    _configuration = configuration;
    _defaultVerticalAlignment = defaultVerticalAlignment;
    _textBaseline = textBaseline;
    children?.forEach(addRow);
  }

  List<RenderBox> _children = const <RenderBox>[];

  int get columns => _columns;
  int _columns;
  set columns(int value) {
    assert(value != null);
    assert(value >= 0);
    if (value == columns) return;
    final int oldColumns = columns;
    final List<RenderBox> oldChildren = _children;
    _columns = value;
    _children = <RenderBox>[]..length = columns * rows;
    final int columnsToCopy = math.min(columns, oldColumns);
    for (int y = 0; y < rows; y += 1) {
      for (int x = 0; x < columnsToCopy; x += 1)
        _children[x + y * columns] = oldChildren[x + y * oldColumns];
    }
    if (oldColumns > columns) {
      for (int y = 0; y < rows; y += 1) {
        for (int x = columns; x < oldColumns; x += 1) {
          final int xy = x + y * oldColumns;
          if (oldChildren[xy] != null) dropChild(oldChildren[xy]);
        }
      }
    }
    markNeedsLayout();
  }

  int get rows => _rows;
  int _rows;
  set rows(int value) {
    assert(value != null);
    assert(value >= 0);
    if (value == rows) return;
    if (_rows > value) {
      for (int xy = columns * value; xy < _children.length; xy += 1) {
        if (_children[xy] != null) dropChild(_children[xy]);
      }
    }
    _rows = value;
    _children.length = columns * rows;
    markNeedsLayout();
  }

  Map<int, TableColumnWidth> get columnWidths =>
      Map<int, TableColumnWidth>.unmodifiable(_columnWidths);
  Map<int, TableColumnWidth> _columnWidths;
  set columnWidths(Map<int, TableColumnWidth> value) {
    value ??= HashMap<int, TableColumnWidth>();
    if (_columnWidths == value) return;
    _columnWidths = value;
    markNeedsLayout();
  }

  void setColumnWidth(int column, TableColumnWidth value) {
    if (_columnWidths[column] == value) return;
    _columnWidths[column] = value;
    markNeedsLayout();
  }

  TableColumnWidth get defaultColumnWidth => _defaultColumnWidth;
  TableColumnWidth _defaultColumnWidth;
  set defaultColumnWidth(TableColumnWidth value) {
    assert(value != null);
    if (defaultColumnWidth == value) return;
    _defaultColumnWidth = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  TableBorder get border => _border;
  TableBorder _border;
  set border(TableBorder value) {
    if (border == value) return;
    _border = value;
    markNeedsPaint();
  }

  List<Decoration> get rowDecorations =>
      List<Decoration>.unmodifiable(_rowDecorations ?? const <Decoration>[]);
  List<Decoration> _rowDecorations;
  List<BoxPainter> _rowDecorationPainters;
  set rowDecorations(List<Decoration> value) {
    if (_rowDecorations == value) return;
    _rowDecorations = value;
    if (_rowDecorationPainters != null) {
      for (BoxPainter painter in _rowDecorationPainters) painter?.dispose();
    }
    _rowDecorationPainters = _rowDecorations != null
        ? List<BoxPainter>(_rowDecorations.length)
        : null;
  }

  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    assert(value != null);
    if (value == _configuration) return;
    _configuration = value;
    markNeedsPaint();
  }

  TableCellVerticalAlignment get defaultVerticalAlignment =>
      _defaultVerticalAlignment;
  TableCellVerticalAlignment _defaultVerticalAlignment;
  set defaultVerticalAlignment(TableCellVerticalAlignment value) {
    if (_defaultVerticalAlignment == value) return;
    _defaultVerticalAlignment = value;
    markNeedsLayout();
  }

  TextBaseline get textBaseline => _textBaseline;
  TextBaseline _textBaseline;
  set textBaseline(TextBaseline value) {
    if (_textBaseline == value) return;
    _textBaseline = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! TableCellParentData)
      child.parentData = TableCellParentData();
  }

  void setFlatChildren(int columns, List<RenderBox> cells) {
    if (cells == _children && columns == _columns) return;
    assert(columns >= 0);

    if (columns == 0 || cells.isEmpty) {
      assert(cells == null || cells.isEmpty);
      _columns = columns;
      if (_children.isEmpty) {
        assert(_rows == 0);
        return;
      }
      for (RenderBox oldChild in _children) {
        if (oldChild != null) dropChild(oldChild);
      }
      _rows = 0;
      _children.clear();
      markNeedsLayout();
      return;
    }
    assert(cells != null);
    assert(cells.length % columns == 0);

    final Set<RenderBox> lostChildren = HashSet<RenderBox>();
    for (int y = 0; y < _rows; y += 1) {
      for (int x = 0; x < _columns; x += 1) {
        final int xyOld = x + y * _columns;
        final int xyNew = x + y * columns;
        if (_children[xyOld] != null &&
            (x >= columns ||
                xyNew >= cells.length ||
                _children[xyOld] != cells[xyNew]))
          lostChildren.add(_children[xyOld]);
      }
    }

    int y = 0;
    while (y * columns < cells.length) {
      for (int x = 0; x < columns; x += 1) {
        final int xyNew = x + y * columns;
        final int xyOld = x + y * _columns;
        if (cells[xyNew] != null &&
            (x >= _columns || y >= _rows || _children[xyOld] != cells[xyNew])) {
          if (!lostChildren.remove(cells[xyNew])) adoptChild(cells[xyNew]);
        }
      }
      y += 1;
    }

    lostChildren.forEach(dropChild);

    _columns = columns;
    _rows = cells.length ~/ columns;
    _children = cells.toList();
    assert(_children.length == rows * columns);
    markNeedsLayout();
  }

  void setChildren(List<List<RenderBox>> cells) {
    if (cells == null) {
      setFlatChildren(0, null);
      return;
    }
    for (RenderBox oldChild in _children) {
      if (oldChild != null) dropChild(oldChild);
    }
    _children.clear();
    _columns = cells.isNotEmpty ? cells.first.length : 0;
    _rows = 0;
    cells.forEach(addRow);
    assert(_children.length == rows * columns);
  }

  void addRow(List<RenderBox> cells) {
    assert(cells.length == columns);
    assert(_children.length == rows * columns);
    _rows += 1;
    _children.addAll(cells);
    for (RenderBox cell in cells) {
      if (cell != null) adoptChild(cell);
    }
    markNeedsLayout();
  }

  void setChild(int x, int y, RenderBox value) {
    assert(x != null);
    assert(y != null);
    assert(x >= 0 && x < columns && y >= 0 && y < rows);
    assert(_children.length == rows * columns);
    final int xy = x + y * columns;
    final RenderBox oldChild = _children[xy];
    if (oldChild == value) return;
    if (oldChild != null) dropChild(oldChild);
    _children[xy] = value;
    if (value != null) adoptChild(value);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderBox child in _children) child?.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    if (_rowDecorationPainters != null) {
      for (BoxPainter painter in _rowDecorationPainters) painter?.dispose();
      _rowDecorationPainters = null;
    }
    for (RenderBox child in _children) child?.detach();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    assert(_children.length == rows * columns);
    for (RenderBox child in _children) {
      if (child != null) visitor(child);
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(_children.length == rows * columns);
    double totalMinWidth = 0.0;
    for (int x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth =
          _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      totalMinWidth +=
          columnWidth.minIntrinsicWidth(columnCells, double.infinity);
    }
    return totalMinWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(_children.length == rows * columns);
    double totalMaxWidth = 0.0;
    for (int x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth =
          _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);
      totalMaxWidth +=
          columnWidth.maxIntrinsicWidth(columnCells, double.infinity);
    }
    return totalMaxWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(_children.length == rows * columns);
    final List<double> widths =
        _computeColumnWidths(BoxConstraints.tightForFinite(width: width));
    double rowTop = 0.0;
    for (int y = 0; y < rows; y += 1) {
      double rowHeight = 0.0;
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox child = _children[xy];
        if (child != null)
          rowHeight =
              math.max(rowHeight, child.getMaxIntrinsicHeight(widths[x]));
      }
      rowTop += rowHeight;
    }
    return rowTop;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return computeMinIntrinsicHeight(width);
  }

  double _baselineDistance;
  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    assert(!debugNeedsLayout);
    return _baselineDistance;
  }

  Iterable<RenderBox> column(int x) sync* {
    for (int y = 0; y < rows; y += 1) {
      final int xy = x + y * columns;
      final RenderBox child = _children[xy];
      if (child != null) yield child;
    }
  }

  Iterable<RenderBox> row(int y) sync* {
    final int start = y * columns;
    final int end = (y + 1) * columns;
    for (int xy = start; xy < end; xy += 1) {
      final RenderBox child = _children[xy];
      if (child != null) yield child;
    }
  }

  List<double> _computeColumnWidths(BoxConstraints constraints) {
    assert(constraints != null);
    assert(_children.length == rows * columns);

    final List<double> widths = List<double>(columns);
    final List<double> minWidths = List<double>(columns);
    final List<double> flexes = List<double>(columns);
    double tableWidth = 0.0;
    double unflexedTableWidth = 0.0;
    double totalFlex = 0.0;
    for (int x = 0; x < columns; x += 1) {
      final TableColumnWidth columnWidth =
          _columnWidths[x] ?? defaultColumnWidth;
      final Iterable<RenderBox> columnCells = column(x);

      final double maxIntrinsicWidth =
          columnWidth.maxIntrinsicWidth(columnCells, constraints.maxWidth);
      assert(maxIntrinsicWidth.isFinite);
      assert(maxIntrinsicWidth >= 0.0);
      widths[x] = maxIntrinsicWidth;
      tableWidth += maxIntrinsicWidth;

      final double minIntrinsicWidth =
          columnWidth.minIntrinsicWidth(columnCells, constraints.maxWidth);
      assert(minIntrinsicWidth.isFinite);
      assert(minIntrinsicWidth >= 0.0);
      minWidths[x] = minIntrinsicWidth;
      assert(maxIntrinsicWidth >= minIntrinsicWidth);

      final double flex = columnWidth.flex(columnCells);
      if (flex != null) {
        assert(flex.isFinite);
        assert(flex > 0.0);
        flexes[x] = flex;
        totalFlex += flex;
      } else {
        unflexedTableWidth += maxIntrinsicWidth;
      }
    }
    assert(!widths.any((double value) => value == null));
    final double maxWidthConstraint = constraints.maxWidth;
    final double minWidthConstraint = constraints.minWidth;

    if (totalFlex > 0.0) {
      double targetWidth;
      if (maxWidthConstraint.isFinite) {
        targetWidth = maxWidthConstraint;
      } else {
        targetWidth = minWidthConstraint;
      }
      if (tableWidth < targetWidth) {
        final double remainingWidth = targetWidth - unflexedTableWidth;
        assert(remainingWidth.isFinite);
        assert(remainingWidth >= 0.0);
        for (int x = 0; x < columns; x += 1) {
          if (flexes[x] != null) {
            final double flexedWidth = remainingWidth * flexes[x] / totalFlex;
            assert(flexedWidth.isFinite);
            assert(flexedWidth >= 0.0);
            if (widths[x] < flexedWidth) {
              final double delta = flexedWidth - widths[x];
              tableWidth += delta;
              widths[x] = flexedWidth;
            }
          }
        }
        assert(tableWidth >= targetWidth);
      }
    } else if (tableWidth < minWidthConstraint) {
      final double delta = (minWidthConstraint - tableWidth) / columns;
      for (int x = 0; x < columns; x += 1) widths[x] += delta;
      tableWidth = minWidthConstraint;
    }

    assert(() {
      unflexedTableWidth = null;
      return true;
    }());

    if (tableWidth > maxWidthConstraint) {
      double deficit = tableWidth - maxWidthConstraint;

      int availableColumns = columns;

      const double minimumDeficit = precisionErrorTolerance;
      while (deficit > minimumDeficit && totalFlex > minimumDeficit) {
        double newTotalFlex = 0.0;
        for (int x = 0; x < columns; x += 1) {
          if (flexes[x] != null) {
            final double newWidth = widths[x] - deficit * flexes[x] / totalFlex;
            assert(newWidth.isFinite);
            if (newWidth <= minWidths[x]) {
              deficit -= widths[x] - minWidths[x];
              widths[x] = minWidths[x];
              flexes[x] = null;
              availableColumns -= 1;
            } else {
              deficit -= widths[x] - newWidth;
              widths[x] = newWidth;
              newTotalFlex += flexes[x];
            }
            assert(widths[x] >= 0.0);
          }
        }
        totalFlex = newTotalFlex;
      }
      if (deficit > 0.0) {
        do {
          final double delta = deficit / availableColumns;
          int newAvailableColumns = 0;
          for (int x = 0; x < columns; x += 1) {
            final double availableDelta = widths[x] - minWidths[x];
            if (availableDelta > 0.0) {
              if (availableDelta <= delta) {
                deficit -= widths[x] - minWidths[x];
                widths[x] = minWidths[x];
              } else {
                deficit -= delta;
                widths[x] -= delta;
                newAvailableColumns += 1;
              }
            }
          }
          availableColumns = newAvailableColumns;
        } while (deficit > 0.0 && availableColumns > 0);
      }
    }
    return widths;
  }

  final List<double> _rowTops = <double>[];
  Iterable<double> _columnLefts;

  Rect getRowBox(int row) {
    assert(row >= 0);
    assert(row < rows);
    assert(!debugNeedsLayout);
    return Rect.fromLTRB(0.0, _rowTops[row], size.width, _rowTops[row + 1]);
  }

  @override
  void performLayout() {
    final int rows = this.rows;
    final int columns = this.columns;
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      size = constraints.constrain(const Size(0.0, 0.0));
      return;
    }
    final List<double> widths = _computeColumnWidths(constraints);
    final List<double> positions = List<double>(columns);
    double tableWidth;
    switch (textDirection) {
      case TextDirection.rtl:
        positions[columns - 1] = 0.0;
        for (int x = columns - 2; x >= 0; x -= 1)
          positions[x] = positions[x + 1] + widths[x + 1];
        _columnLefts = positions.reversed;
        tableWidth = positions.first + widths.first;
        break;
      case TextDirection.ltr:
        positions[0] = 0.0;
        for (int x = 1; x < columns; x += 1)
          positions[x] = positions[x - 1] + widths[x - 1];
        _columnLefts = positions;
        tableWidth = positions.last + widths.last;
        break;
    }
    assert(!positions.any((double value) => value == null));
    _rowTops.clear();
    _baselineDistance = null;

    double rowTop = 0.0;
    for (int y = 0; y < rows; y += 1) {
      _rowTops.add(rowTop);
      double rowHeight = 0.0;
      bool haveBaseline = false;
      double beforeBaselineDistance = 0.0;
      double afterBaselineDistance = 0.0;
      final List<double> baselines = List<double>(columns);
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox child = _children[xy];
        if (child != null) {
          final TableCellParentData childParentData = child.parentData;
          assert(childParentData != null);
          childParentData.x = x;
          childParentData.y = y;
          switch (
              childParentData.verticalAlignment ?? defaultVerticalAlignment) {
            case TableCellVerticalAlignment.baseline:
              assert(textBaseline != null);
              child.layout(BoxConstraints.tightFor(width: widths[x]),
                  parentUsesSize: true);
              final double childBaseline =
                  child.getDistanceToBaseline(textBaseline, onlyReal: true);
              if (childBaseline != null) {
                beforeBaselineDistance =
                    math.max(beforeBaselineDistance, childBaseline);
                afterBaselineDistance = math.max(
                    afterBaselineDistance, child.size.height - childBaseline);
                baselines[x] = childBaseline;
                haveBaseline = true;
              } else {
                rowHeight = math.max(rowHeight, child.size.height);
                childParentData.offset = Offset(positions[x], rowTop);
              }
              break;
            case TableCellVerticalAlignment.top:
            case TableCellVerticalAlignment.middle:
            case TableCellVerticalAlignment.bottom:
              child.layout(BoxConstraints.tightFor(width: widths[x]),
                  parentUsesSize: true);
              rowHeight = math.max(rowHeight, child.size.height);
              break;
            case TableCellVerticalAlignment.fill:
              break;
          }
        }
      }
      if (haveBaseline) {
        if (y == 0) _baselineDistance = beforeBaselineDistance;
        rowHeight =
            math.max(rowHeight, beforeBaselineDistance + afterBaselineDistance);
      }
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox child = _children[xy];
        if (child != null) {
          final TableCellParentData childParentData = child.parentData;
          switch (
              childParentData.verticalAlignment ?? defaultVerticalAlignment) {
            case TableCellVerticalAlignment.baseline:
              if (baselines[x] != null)
                childParentData.offset = Offset(positions[x],
                    rowTop + beforeBaselineDistance - baselines[x]);
              break;
            case TableCellVerticalAlignment.top:
              childParentData.offset = Offset(positions[x], rowTop);
              break;
            case TableCellVerticalAlignment.middle:
              childParentData.offset = Offset(
                  positions[x], rowTop + (rowHeight - child.size.height) / 2.0);
              break;
            case TableCellVerticalAlignment.bottom:
              childParentData.offset =
                  Offset(positions[x], rowTop + rowHeight - child.size.height);
              break;
            case TableCellVerticalAlignment.fill:
              child.layout(
                  BoxConstraints.tightFor(width: widths[x], height: rowHeight));
              childParentData.offset = Offset(positions[x], rowTop);
              break;
          }
        }
      }
      rowTop += rowHeight;
    }
    _rowTops.add(rowTop);
    size = constraints.constrain(Size(tableWidth, rowTop));
    assert(_rowTops.length == rows + 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    assert(_children.length == rows * columns);
    for (int index = _children.length - 1; index >= 0; index -= 1) {
      final RenderBox child = _children[index];
      if (child != null) {
        final BoxParentData childParentData = child.parentData;
        final bool isHit = result.addWithPaintOffset(
          offset: childParentData.offset,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            assert(transformed == position - childParentData.offset);
            return child.hitTest(result, position: transformed);
          },
        );
        if (isHit) return true;
      }
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(_children.length == rows * columns);
    if (rows * columns == 0) {
      if (border != null) {
        final Rect borderRect =
            Rect.fromLTWH(offset.dx, offset.dy, size.width, 0.0);
        border.paint(context.canvas, borderRect,
            rows: const <double>[], columns: const <double>[]);
      }
      return;
    }
    assert(_rowTops.length == rows + 1);
    if (_rowDecorations != null) {
      final Canvas canvas = context.canvas;
      for (int y = 0; y < rows; y += 1) {
        if (_rowDecorations.length <= y) break;
        if (_rowDecorations[y] != null) {
          _rowDecorationPainters[y] ??=
              _rowDecorations[y].createBoxPainter(markNeedsPaint);
          _rowDecorationPainters[y].paint(
            canvas,
            Offset(offset.dx, offset.dy + _rowTops[y]),
            configuration.copyWith(
                size: Size(size.width, _rowTops[y + 1] - _rowTops[y])),
          );
        }
      }
    }
    for (int index = 0; index < _children.length; index += 1) {
      final RenderBox child = _children[index];
      if (child != null) {
        final BoxParentData childParentData = child.parentData;
        context.paintChild(child, childParentData.offset + offset);
      }
    }
    assert(_rows == _rowTops.length - 1);
    assert(_columns == _columnLefts.length);
    if (border != null) {
      final Rect borderRect =
          Rect.fromLTWH(offset.dx, offset.dy, size.width, _rowTops.last);
      final Iterable<double> rows = _rowTops.getRange(1, _rowTops.length - 1);
      final Iterable<double> columns = _columnLefts.skip(1);
      border.paint(context.canvas, borderRect, rows: rows, columns: columns);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<TableBorder>('border', border, defaultValue: null));
    properties.add(DiagnosticsProperty<Map<int, TableColumnWidth>>(
        'specified column widths', _columnWidths,
        level: _columnWidths.isEmpty
            ? DiagnosticLevel.hidden
            : DiagnosticLevel.info));
    properties.add(DiagnosticsProperty<TableColumnWidth>(
        'default column width', defaultColumnWidth));
    properties.add(MessageProperty('table size', '$columns\u00D7$rows'));
    properties.add(IterableProperty<double>('column offsets', _columnLefts,
        ifNull: 'unknown'));
    properties.add(
        IterableProperty<double>('row offsets', _rowTops, ifNull: 'unknown'));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    if (_children.isEmpty) {
      return <DiagnosticsNode>[DiagnosticsNode.message('table is empty')];
    }

    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    for (int y = 0; y < rows; y += 1) {
      for (int x = 0; x < columns; x += 1) {
        final int xy = x + y * columns;
        final RenderBox child = _children[xy];
        final String name = 'child ($x, $y)';
        if (child != null)
          children.add(child.toDiagnosticsNode(name: name));
        else
          children.add(DiagnosticsProperty<Object>(name, null,
              ifNull: 'is null', showSeparator: false));
      }
    }
    return children;
  }
}

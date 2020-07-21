import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'checkbox.dart';
import 'colors.dart';
import 'debug.dart';
import 'divider.dart';
import 'dropdown.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'tooltip.dart';

typedef DataColumnSortCallback = void Function(int columnIndex, bool ascending);

@immutable
class DataColumn {
  const DataColumn({
    @required this.label,
    this.tooltip,
    this.numeric = false,
    this.onSort,
  }) : assert(label != null);

  final Widget label;

  final String tooltip;

  final bool numeric;

  final DataColumnSortCallback onSort;

  bool get _debugInteractive => onSort != null;
}

@immutable
class DataRow {
  const DataRow({
    this.key,
    this.selected = false,
    this.onSelectChanged,
    @required this.cells,
  }) : assert(cells != null);

  DataRow.byIndex({
    int index,
    this.selected = false,
    this.onSelectChanged,
    @required this.cells,
  })  : assert(cells != null),
        key = ValueKey<int>(index);

  final LocalKey key;

  final ValueChanged<bool> onSelectChanged;

  final bool selected;

  final List<DataCell> cells;

  bool get _debugInteractive =>
      onSelectChanged != null ||
      cells.any((DataCell cell) => cell._debugInteractive);
}

@immutable
class DataCell {
  const DataCell(
    this.child, {
    this.placeholder = false,
    this.showEditIcon = false,
    this.onTap,
  }) : assert(child != null);

  static final DataCell empty = DataCell(Container(width: 0.0, height: 0.0));

  final Widget child;

  final bool placeholder;

  final bool showEditIcon;

  final VoidCallback onTap;

  bool get _debugInteractive => onTap != null;
}

class DataTable extends StatelessWidget {
  DataTable({
    Key key,
    @required this.columns,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSelectAll,
    @required this.rows,
  })  : assert(columns != null),
        assert(columns.isNotEmpty),
        assert(sortColumnIndex == null ||
            (sortColumnIndex >= 0 && sortColumnIndex < columns.length)),
        assert(sortAscending != null),
        assert(rows != null),
        assert(!rows.any((DataRow row) => row.cells.length != columns.length)),
        _onlyTextColumn = _initOnlyTextColumn(columns),
        super(key: key);

  final List<DataColumn> columns;

  final int sortColumnIndex;

  final bool sortAscending;

  final ValueSetter<bool> onSelectAll;

  final List<DataRow> rows;

  final int _onlyTextColumn;
  static int _initOnlyTextColumn(List<DataColumn> columns) {
    int result;
    for (int index = 0; index < columns.length; index += 1) {
      final DataColumn column = columns[index];
      if (!column.numeric) {
        if (result != null) return null;
        result = index;
      }
    }
    return result;
  }

  bool get _debugInteractive {
    return columns.any((DataColumn column) => column._debugInteractive) ||
        rows.any((DataRow row) => row._debugInteractive);
  }

  static final LocalKey _headingRowKey = UniqueKey();

  void _handleSelectAll(bool checked) {
    if (onSelectAll != null) {
      onSelectAll(checked);
    } else {
      for (DataRow row in rows) {
        if ((row.onSelectChanged != null) && (row.selected != checked))
          row.onSelectChanged(checked);
      }
    }
  }

  static const double _headingRowHeight = 56.0;
  static const double _dataRowHeight = 48.0;
  static const double _tablePadding = 24.0;
  static const double _columnSpacing = 56.0;
  static const double _sortArrowPadding = 2.0;
  static const double _headingFontSize = 12.0;
  static const Duration _sortArrowAnimationDuration =
      Duration(milliseconds: 150);
  static const Color _grey100Opacity = Color(0x0A000000);
  static const Color _grey300Opacity = Color(0x1E000000);

  Widget _buildCheckbox(
      {Color color,
      bool checked,
      VoidCallback onRowTap,
      ValueChanged<bool> onCheckboxChanged}) {
    Widget contents = Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
            start: _tablePadding, end: _tablePadding / 2.0),
        child: Center(
          child: Checkbox(
            activeColor: color,
            value: checked,
            onChanged: onCheckboxChanged,
          ),
        ),
      ),
    );
    if (onRowTap != null) {
      contents = TableRowInkWell(
        onTap: onRowTap,
        child: contents,
      );
    }
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.fill,
      child: contents,
    );
  }

  Widget _buildHeadingCell({
    BuildContext context,
    EdgeInsetsGeometry padding,
    Widget label,
    String tooltip,
    bool numeric,
    VoidCallback onSort,
    bool sorted,
    bool ascending,
  }) {
    if (onSort != null) {
      final Widget arrow = _SortArrow(
        visible: sorted,
        down: sorted ? ascending : null,
        duration: _sortArrowAnimationDuration,
      );
      const Widget arrowPadding = SizedBox(width: _sortArrowPadding);
      label = Row(
        textDirection: numeric ? TextDirection.rtl : null,
        children: <Widget>[label, arrowPadding, arrow],
      );
    }
    label = Container(
      padding: padding,
      height: _headingRowHeight,
      alignment:
          numeric ? Alignment.centerRight : AlignmentDirectional.centerStart,
      child: AnimatedDefaultTextStyle(
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: _headingFontSize,
          height: math.min(1.0, _headingRowHeight / _headingFontSize),
          color: (Theme.of(context).brightness == Brightness.light)
              ? ((onSort != null && sorted) ? Colors.black87 : Colors.black54)
              : ((onSort != null && sorted) ? Colors.white : Colors.white70),
        ),
        softWrap: false,
        duration: _sortArrowAnimationDuration,
        child: label,
      ),
    );
    if (tooltip != null) {
      label = Tooltip(
        message: tooltip,
        child: label,
      );
    }
    if (onSort != null) {
      label = InkWell(
        onTap: onSort,
        child: label,
      );
    }
    return label;
  }

  Widget _buildDataCell({
    BuildContext context,
    EdgeInsetsGeometry padding,
    Widget label,
    bool numeric,
    bool placeholder,
    bool showEditIcon,
    VoidCallback onTap,
    VoidCallback onSelectChanged,
  }) {
    final bool isLightTheme = Theme.of(context).brightness == Brightness.light;
    if (showEditIcon) {
      const Widget icon = Icon(Icons.edit, size: 18.0);
      label = Expanded(child: label);
      label = Row(
        textDirection: numeric ? TextDirection.rtl : null,
        children: <Widget>[label, icon],
      );
    }
    label = Container(
        padding: padding,
        height: _dataRowHeight,
        alignment:
            numeric ? Alignment.centerRight : AlignmentDirectional.centerStart,
        child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 13.0,
              color: isLightTheme
                  ? (placeholder ? Colors.black38 : Colors.black87)
                  : (placeholder ? Colors.white30 : Colors.white70),
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: isLightTheme ? Colors.black54 : Colors.white70,
              ),
              child: DropdownButtonHideUnderline(child: label),
            )));
    if (onTap != null) {
      label = InkWell(
        onTap: onTap,
        child: label,
      );
    } else if (onSelectChanged != null) {
      label = TableRowInkWell(
        onTap: onSelectChanged,
        child: label,
      );
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    assert(!_debugInteractive || debugCheckHasMaterial(context));

    final ThemeData theme = Theme.of(context);
    final BoxDecoration _kSelectedDecoration = BoxDecoration(
      border: Border(bottom: Divider.createBorderSide(context, width: 1.0)),
      color: (Theme.of(context).brightness == Brightness.light)
          ? _grey100Opacity
          : _grey300Opacity,
    );
    final BoxDecoration _kUnselectedDecoration = BoxDecoration(
      border: Border(bottom: Divider.createBorderSide(context, width: 1.0)),
    );

    final bool showCheckboxColumn =
        rows.any((DataRow row) => row.onSelectChanged != null);
    final bool allChecked = showCheckboxColumn &&
        !rows
            .any((DataRow row) => row.onSelectChanged != null && !row.selected);

    final List<TableColumnWidth> tableColumns =
        List<TableColumnWidth>(columns.length + (showCheckboxColumn ? 1 : 0));
    final List<TableRow> tableRows = List<TableRow>.generate(
      rows.length + 1,
      (int index) {
        return TableRow(
            key: index == 0 ? _headingRowKey : rows[index - 1].key,
            decoration: index > 0 && rows[index - 1].selected
                ? _kSelectedDecoration
                : _kUnselectedDecoration,
            children: List<Widget>(tableColumns.length));
      },
    );

    int rowIndex;

    int displayColumnIndex = 0;
    if (showCheckboxColumn) {
      tableColumns[0] = const FixedColumnWidth(
          _tablePadding + Checkbox.width + _tablePadding / 2.0);
      tableRows[0].children[0] = _buildCheckbox(
        color: theme.accentColor,
        checked: allChecked,
        onCheckboxChanged: _handleSelectAll,
      );
      rowIndex = 1;
      for (DataRow row in rows) {
        tableRows[rowIndex].children[0] = _buildCheckbox(
          color: theme.accentColor,
          checked: row.selected,
          onRowTap: () => row.onSelectChanged(!row.selected),
          onCheckboxChanged: row.onSelectChanged,
        );
        rowIndex += 1;
      }
      displayColumnIndex += 1;
    }

    for (int dataColumnIndex = 0;
        dataColumnIndex < columns.length;
        dataColumnIndex += 1) {
      final DataColumn column = columns[dataColumnIndex];
      final EdgeInsetsDirectional padding = EdgeInsetsDirectional.only(
        start: dataColumnIndex == 0
            ? showCheckboxColumn ? _tablePadding / 2.0 : _tablePadding
            : _columnSpacing / 2.0,
        end: dataColumnIndex == columns.length - 1
            ? _tablePadding
            : _columnSpacing / 2.0,
      );
      if (dataColumnIndex == _onlyTextColumn) {
        tableColumns[displayColumnIndex] =
            const IntrinsicColumnWidth(flex: 1.0);
      } else {
        tableColumns[displayColumnIndex] = const IntrinsicColumnWidth();
      }
      tableRows[0].children[displayColumnIndex] = _buildHeadingCell(
        context: context,
        padding: padding,
        label: column.label,
        tooltip: column.tooltip,
        numeric: column.numeric,
        onSort: () => column.onSort(dataColumnIndex,
            sortColumnIndex == dataColumnIndex ? !sortAscending : true),
        sorted: dataColumnIndex == sortColumnIndex,
        ascending: sortAscending,
      );
      rowIndex = 1;
      for (DataRow row in rows) {
        final DataCell cell = row.cells[dataColumnIndex];
        tableRows[rowIndex].children[displayColumnIndex] = _buildDataCell(
          context: context,
          padding: padding,
          label: cell.child,
          numeric: column.numeric,
          placeholder: cell.placeholder,
          showEditIcon: cell.showEditIcon,
          onTap: cell.onTap,
          onSelectChanged: () => row.onSelectChanged(!row.selected),
        );
        rowIndex += 1;
      }
      displayColumnIndex += 1;
    }

    return Table(
      columnWidths: tableColumns.asMap(),
      children: tableRows,
    );
  }
}

class TableRowInkWell extends InkResponse {
  const TableRowInkWell({
    Key key,
    Widget child,
    GestureTapCallback onTap,
    GestureTapCallback onDoubleTap,
    GestureLongPressCallback onLongPress,
    ValueChanged<bool> onHighlightChanged,
  }) : super(
          key: key,
          child: child,
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          onLongPress: onLongPress,
          onHighlightChanged: onHighlightChanged,
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
        );

  @override
  RectCallback getRectCallback(RenderBox referenceBox) {
    return () {
      RenderObject cell = referenceBox;
      AbstractNode table = cell.parent;
      final Matrix4 transform = Matrix4.identity();
      while (table is RenderObject && table is! RenderTable) {
        final RenderTable parentBox = table;
        parentBox.applyPaintTransform(cell, transform);
        assert(table == cell.parent);
        cell = table;
        table = table.parent;
      }
      if (table is RenderTable) {
        final TableCellParentData cellParentData = cell.parentData;
        assert(cellParentData.y != null);
        final Rect rect = table.getRowBox(cellParentData.y);

        table.applyPaintTransform(cell, transform);
        final Offset offset = MatrixUtils.getAsTranslation(transform);
        if (offset != null) return rect.shift(-offset);
      }
      return Rect.zero;
    };
  }

  @override
  bool debugCheckContext(BuildContext context) {
    assert(debugCheckHasTable(context));
    return super.debugCheckContext(context);
  }
}

class _SortArrow extends StatefulWidget {
  const _SortArrow({
    Key key,
    this.visible,
    this.down,
    this.duration,
  }) : super(key: key);

  final bool visible;

  final bool down;

  final Duration duration;

  @override
  _SortArrowState createState() => _SortArrowState();
}

class _SortArrowState extends State<_SortArrow> with TickerProviderStateMixin {
  AnimationController _opacityController;
  Animation<double> _opacityAnimation;

  AnimationController _orientationController;
  Animation<double> _orientationAnimation;
  double _orientationOffset = 0.0;

  bool _down;

  static final Animatable<double> _turnTween =
      Tween<double>(begin: 0.0, end: math.pi)
          .chain(CurveTween(curve: Curves.easeIn));

  @override
  void initState() {
    super.initState();
    _opacityAnimation = CurvedAnimation(
        parent: _opacityController = AnimationController(
          duration: widget.duration,
          vsync: this,
        ),
        curve: Curves.fastOutSlowIn)
      ..addListener(_rebuild);
    _opacityController.value = widget.visible ? 1.0 : 0.0;
    _orientationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _orientationAnimation = _orientationController.drive(_turnTween)
      ..addListener(_rebuild)
      ..addStatusListener(_resetOrientationAnimation);
    if (widget.visible) _orientationOffset = widget.down ? 0.0 : math.pi;
  }

  void _rebuild() {
    setState(() {});
  }

  void _resetOrientationAnimation(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      assert(_orientationAnimation.value == math.pi);
      _orientationOffset += math.pi;
      _orientationController.value = 0.0;
    }
  }

  @override
  void didUpdateWidget(_SortArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool skipArrow = false;
    final bool newDown = widget.down != null ? widget.down : _down;
    if (oldWidget.visible != widget.visible) {
      if (widget.visible &&
          (_opacityController.status == AnimationStatus.dismissed)) {
        _orientationController.stop();
        _orientationController.value = 0.0;
        _orientationOffset = newDown ? 0.0 : math.pi;
        skipArrow = true;
      }
      if (widget.visible) {
        _opacityController.forward();
      } else {
        _opacityController.reverse();
      }
    }
    if ((_down != newDown) && !skipArrow) {
      if (_orientationController.status == AnimationStatus.dismissed) {
        _orientationController.forward();
      } else {
        _orientationController.reverse();
      }
    }
    _down = newDown;
  }

  @override
  void dispose() {
    _opacityController.dispose();
    _orientationController.dispose();
    super.dispose();
  }

  static const double _arrowIconBaselineOffset = -1.5;
  static const double _arrowIconSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _opacityAnimation.value,
      child: Transform(
        transform:
            Matrix4.rotationZ(_orientationOffset + _orientationAnimation.value)
              ..setTranslationRaw(0.0, _arrowIconBaselineOffset, 0.0),
        alignment: Alignment.center,
        child: Icon(
          Icons.arrow_downward,
          size: _arrowIconSize,
          color: (Theme.of(context).brightness == Brightness.light)
              ? Colors.black87
              : Colors.white70,
        ),
      ),
    );
  }
}

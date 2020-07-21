import 'package:flutter_web/foundation.dart';
import 'data_table.dart';

abstract class DataTableSource extends ChangeNotifier {
  DataRow getRow(int index);

  int get rowCount;

  bool get isRowCountApproximate;

  int get selectedRowCount;
}

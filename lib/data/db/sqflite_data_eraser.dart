import 'package:fpdart/fpdart.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../../domain/backup/data_eraser.dart';
import '../models/expense_row.dart';
import '../models/odometer_reading_row.dart';
import '../models/refuel_row.dart';
import '../models/service_log_row.dart';
import '../models/vehicle_row.dart';

/// [DataEraser] over sqflite. Deletes every row from the five tables inside
/// one transaction, children before vehicles, and clears each table's entry
/// in `sqlite_sequence` so the next insert starts back at id 1, the same as a
/// fresh install.
class SqfliteDataEraser implements DataEraser {
  const SqfliteDataEraser(this._db);

  final Database _db;

  static const _tablesChildrenFirst = [
    ExpenseRow.table,
    ServiceLogRow.table,
    OdometerReadingRow.table,
    RefuelRow.table,
    VehicleRow.table,
  ];

  @override
  Future<Result<Unit>> eraseAll() async {
    try {
      await _db.transaction((txn) async {
        for (final table in _tablesChildrenFirst) {
          await txn.delete(table);
          await txn.delete(
            'sqlite_sequence',
            where: 'name = ?',
            whereArgs: [table],
          );
        }
      });
      return right(unit);
    } catch (error) {
      return left(DatabaseFailure(error.toString()));
    }
  }
}

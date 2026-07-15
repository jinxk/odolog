import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../backup/data_bundle.dart';
import '../backup/data_bundle_codec.dart';
import 'add_vehicle.dart';
import 'log_expense.dart';
import 'log_refuel.dart';
import 'log_service.dart';

/// Decodes a backup file through [DataBundleCodec] and replays it through the
/// same use cases the forms write with, so an imported item passes exactly the
/// validation a hand-entered one does. Returns the bundle it just imported so
/// the caller can report what came in without decoding the file a second time.
class ImportData {
  const ImportData(
    this._addVehicle,
    this._logRefuel,
    this._logService,
    this._logExpense,
    this._codec,
  );

  final AddVehicle _addVehicle;
  final LogRefuel _logRefuel;
  final LogService _logService;
  final LogExpense _logExpense;
  final DataBundleCodec _codec;

  Future<Result<DataBundle>> execute(String content) async {
    final decoded = _codec.decode(content);
    return decoded.match(
      (failure) => Future<Result<DataBundle>>.value(left(failure)),
      (bundle) async {
        for (var i = 0; i < bundle.vehicles.length; i++) {
          final result = await _addVehicle.execute(bundle.vehicles[i]);
          final failure = result.getLeft().toNullable();
          if (failure != null) return left(_locate(failure, 'vehicles[$i]'));
        }
        for (var i = 0; i < bundle.entries.length; i++) {
          final result = await _logRefuel.execute(bundle.entries[i]);
          final failure = result.getLeft().toNullable();
          if (failure != null) return left(_locate(failure, 'refuels[$i]'));
        }
        for (var i = 0; i < bundle.serviceLog.length; i++) {
          final result = await _logService.execute(bundle.serviceLog[i]);
          final failure = result.getLeft().toNullable();
          if (failure != null) return left(_locate(failure, 'serviceLog[$i]'));
        }
        for (var i = 0; i < bundle.expenses.length; i++) {
          final result = await _logExpense.execute(bundle.expenses[i]);
          final failure = result.getLeft().toNullable();
          if (failure != null) return left(_locate(failure, 'expenses[$i]'));
        }
        return right(bundle);
      },
    );
  }

  /// Points a validation complaint at the item that raised it, the same
  /// "refuels[3]" convention the codec uses for a structural problem.
  static Failure _locate(Failure failure, String where) {
    if (failure is! ValidationFailure) return failure;
    return ValidationFailure(
      field: failure.field,
      reason: '$where: ${failure.reason}',
    );
  }
}

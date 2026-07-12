import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../backup/data_bundle.dart';
import '../backup/data_bundle_codec.dart';
import '../repositories/expense_repository.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/service_log_repository.dart';
import '../repositories/vehicle_repository.dart';

/// Decodes a backup file through [DataBundleCodec] and writes it into the
/// repositories. Returns the bundle it just imported so the caller can report
/// what came in without decoding the file a second time.
class ImportData {
  const ImportData(
    this._vehicleRepository,
    this._refuelRepository,
    this._serviceLogRepository,
    this._expenseRepository,
    this._codec,
  );

  final VehicleRepository _vehicleRepository;
  final RefuelRepository _refuelRepository;
  final ServiceLogRepository _serviceLogRepository;
  final ExpenseRepository _expenseRepository;
  final DataBundleCodec _codec;

  Future<Result<DataBundle>> execute(String content) async {
    final decoded = _codec.decode(content);
    return decoded.match(
      (failure) => Future<Result<DataBundle>>.value(left(failure)),
      (bundle) async {
        for (final vehicle in bundle.vehicles) {
          final result = await _vehicleRepository.add(vehicle);
          final failure = result.getLeft().toNullable();
          if (failure != null) return left(failure);
        }
        for (final entry in bundle.entries) {
          final result = await _refuelRepository.add(entry);
          final failure = result.getLeft().toNullable();
          if (failure != null) return left(failure);
        }
        for (final entry in bundle.serviceLog) {
          final result = await _serviceLogRepository.add(entry);
          final failure = result.getLeft().toNullable();
          if (failure != null) return left(failure);
        }
        for (final expense in bundle.expenses) {
          final result = await _expenseRepository.add(expense);
          final failure = result.getLeft().toNullable();
          if (failure != null) return left(failure);
        }
        return right(bundle);
      },
    );
  }
}

import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../repositories/expense_repository.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/service_log_repository.dart';
import '../repositories/vehicle_repository.dart';
import 'export_data.dart';

/// Writes a validated [DataBundle] back into the repositories. Parsing and
/// validating the incoming CSV or JSON into a bundle happens in the data layer
/// before it reaches this use case.
class ImportData {
  const ImportData(
    this._vehicleRepository,
    this._refuelRepository,
    this._serviceLogRepository,
    this._expenseRepository,
  );

  final VehicleRepository _vehicleRepository;
  final RefuelRepository _refuelRepository;
  final ServiceLogRepository _serviceLogRepository;
  final ExpenseRepository _expenseRepository;

  Future<Result<Unit>> execute(DataBundle bundle) async {
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
    return right(unit);
  }
}

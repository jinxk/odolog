import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../calculators/aggregate_calculator.dart';
import '../repositories/expense_repository.dart';
import '../repositories/odometer_reading_repository.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/service_log_repository.dart';
import '../repositories/vehicle_repository.dart';
import '../value_objects/vehicle_stats.dart';

class GetVehicleStats {
  const GetVehicleStats(
    this._vehicleRepository,
    this._refuelRepository,
    this._expenseRepository,
    this._serviceLogRepository,
    this._readingRepository,
  );

  final VehicleRepository _vehicleRepository;
  final RefuelRepository _refuelRepository;
  final ExpenseRepository _expenseRepository;
  final ServiceLogRepository _serviceLogRepository;
  final OdometerReadingRepository _readingRepository;

  Future<Result<VehicleStats>> execute(int vehicleId) async {
    final vehicleResult = await _vehicleRepository.getById(vehicleId);
    final vehicleFailure = vehicleResult.getLeft().toNullable();
    if (vehicleFailure != null) return left(vehicleFailure);

    final entriesResult = await _refuelRepository.getForVehicle(vehicleId);
    final entriesFailure = entriesResult.getLeft().toNullable();
    if (entriesFailure != null) return left(entriesFailure);

    final expensesResult = await _expenseRepository.getForVehicle(vehicleId);
    final expensesFailure = expensesResult.getLeft().toNullable();
    if (expensesFailure != null) return left(expensesFailure);

    final logResult = await _serviceLogRepository.getForVehicle(vehicleId);
    final logFailure = logResult.getLeft().toNullable();
    if (logFailure != null) return left(logFailure);

    final readingsResult = await _readingRepository.getForVehicle(vehicleId);
    final readingsFailure = readingsResult.getLeft().toNullable();
    if (readingsFailure != null) return left(readingsFailure);

    return right(
      const AggregateCalculator().lifetime(
        entriesResult.getRight().toNullable()!,
        tankCapacity: vehicleResult.getRight().toNullable()!.tankCapacity,
        expenses: expensesResult.getRight().toNullable()!,
        serviceLog: logResult.getRight().toNullable()!,
        readings: readingsResult.getRight().toNullable()!,
      ),
    );
  }
}

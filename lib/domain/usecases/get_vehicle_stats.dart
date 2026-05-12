import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../calculators/aggregate_calculator.dart';
import '../repositories/expense_repository.dart';
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
  );

  final VehicleRepository _vehicleRepository;
  final RefuelRepository _refuelRepository;
  final ExpenseRepository _expenseRepository;
  final ServiceLogRepository _serviceLogRepository;

  Future<Result<VehicleStats>> execute(int vehicleId) async {
    final vehicleResult = await _vehicleRepository.getById(vehicleId);
    return vehicleResult.match(
      (failure) => Future<Result<VehicleStats>>.value(left(failure)),
      (vehicle) async {
        final entriesResult = await _refuelRepository.getForVehicle(vehicleId);
        return entriesResult.match(
          (failure) => Future<Result<VehicleStats>>.value(left(failure)),
          (entries) async {
            final expensesResult = await _expenseRepository.getForVehicle(
              vehicleId,
            );
            return expensesResult.match(
              (failure) => Future<Result<VehicleStats>>.value(left(failure)),
              (expenses) async {
                final logResult = await _serviceLogRepository.getForVehicle(
                  vehicleId,
                );
                return logResult.map(
                  (serviceLog) => const AggregateCalculator().lifetime(
                    entries,
                    tankCapacity: vehicle.tankCapacity,
                    expenses: expenses,
                    serviceLog: serviceLog,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

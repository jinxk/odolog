import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../entities/expense.dart';
import '../entities/refuel_entry.dart';
import '../entities/service_log_entry.dart';
import '../entities/vehicle.dart';
import '../repositories/expense_repository.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/service_log_repository.dart';
import '../repositories/vehicle_repository.dart';

/// The full set of vehicles and everything logged against them. Encoding this
/// bundle to CSV or a JSON backup file is the data layer's job; the use case
/// only assembles it.
typedef DataBundle = ({
  List<Vehicle> vehicles,
  List<RefuelEntry> entries,
  List<ServiceLogEntry> serviceLog,
  List<Expense> expenses,
});

class ExportData {
  const ExportData(
    this._vehicleRepository,
    this._refuelRepository,
    this._serviceLogRepository,
    this._expenseRepository,
  );

  final VehicleRepository _vehicleRepository;
  final RefuelRepository _refuelRepository;
  final ServiceLogRepository _serviceLogRepository;
  final ExpenseRepository _expenseRepository;

  Future<Result<DataBundle>> execute() async {
    final vehiclesResult = await _vehicleRepository.getAll();
    return vehiclesResult.match(
      (failure) => Future<Result<DataBundle>>.value(left(failure)),
      (vehicles) async {
        final entries = <RefuelEntry>[];
        final serviceLog = <ServiceLogEntry>[];
        final expenses = <Expense>[];
        for (final vehicle in vehicles) {
          final entriesResult = await _refuelRepository.getForVehicle(
            vehicle.id,
          );
          final entriesFailure = entriesResult.match<Failure?>((f) => f, (
            vehicleEntries,
          ) {
            entries.addAll(vehicleEntries);
            return null;
          });
          if (entriesFailure != null) return left(entriesFailure);

          final serviceLogResult = await _serviceLogRepository.getForVehicle(
            vehicle.id,
          );
          final serviceLogFailure = serviceLogResult.match<Failure?>((f) => f, (
            vehicleServiceLog,
          ) {
            serviceLog.addAll(vehicleServiceLog);
            return null;
          });
          if (serviceLogFailure != null) return left(serviceLogFailure);

          final expensesResult = await _expenseRepository.getForVehicle(
            vehicle.id,
          );
          final expensesFailure = expensesResult.match<Failure?>((f) => f, (
            vehicleExpenses,
          ) {
            expenses.addAll(vehicleExpenses);
            return null;
          });
          if (expensesFailure != null) return left(expensesFailure);
        }
        return right((
          vehicles: vehicles,
          entries: entries,
          serviceLog: serviceLog,
          expenses: expenses,
        ));
      },
    );
  }
}

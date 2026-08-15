import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../backup/data_bundle_codec.dart';
import '../entities/expense.dart';
import '../entities/odometer_reading.dart';
import '../entities/refuel_entry.dart';
import '../entities/service_log_entry.dart';
import '../repositories/expense_repository.dart';
import '../repositories/odometer_reading_repository.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/service_log_repository.dart';
import '../repositories/vehicle_repository.dart';

/// Assembles every vehicle and everything logged against it, then hands the
/// bundle to [DataBundleCodec] to produce the backup file content, ready to
/// write to disk or hand to a share sheet.
class ExportData {
  const ExportData(
    this._vehicleRepository,
    this._refuelRepository,
    this._serviceLogRepository,
    this._expenseRepository,
    this._readingRepository,
    this._codec,
  );

  final VehicleRepository _vehicleRepository;
  final RefuelRepository _refuelRepository;
  final ServiceLogRepository _serviceLogRepository;
  final ExpenseRepository _expenseRepository;
  final OdometerReadingRepository _readingRepository;
  final DataBundleCodec _codec;

  Future<Result<String>> execute() async {
    final vehiclesResult = await _vehicleRepository.getAll();
    return vehiclesResult.match(
      (failure) => Future<Result<String>>.value(left(failure)),
      (vehicles) async {
        final entries = <RefuelEntry>[];
        final serviceLog = <ServiceLogEntry>[];
        final expenses = <Expense>[];
        final odometerReadings = <OdometerReading>[];
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

          final readingsResult = await _readingRepository.getForVehicle(
            vehicle.id,
          );
          final readingsFailure = readingsResult.match<Failure?>((f) => f, (
            vehicleReadings,
          ) {
            odometerReadings.addAll(vehicleReadings);
            return null;
          });
          if (readingsFailure != null) return left(readingsFailure);
        }
        return right(
          _codec.encode((
            vehicles: vehicles,
            entries: entries,
            serviceLog: serviceLog,
            expenses: expenses,
            odometerReadings: odometerReadings,
          )),
        );
      },
    );
  }
}

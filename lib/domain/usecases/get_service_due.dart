import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../calculators/latest_odometer.dart';
import '../calculators/service_due_calculator.dart';
import '../entities/service_log_entry.dart';
import '../entities/vehicle.dart';
import '../repositories/odometer_reading_repository.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/service_log_repository.dart';
import '../value_objects/service_due_status.dart';

/// Where a vehicle's two maintenance templates currently stand, for the
/// dashboard glance and the service log screen's header.
class GetServiceDue {
  const GetServiceDue(
    this._refuelRepository,
    this._serviceLogRepository,
    this._readingRepository,
  );

  final RefuelRepository _refuelRepository;
  final ServiceLogRepository _serviceLogRepository;
  final OdometerReadingRepository _readingRepository;

  static const _calculator = ServiceDueCalculator();

  Future<Result<List<ServiceDueStatus>>> execute(Vehicle vehicle) async {
    final refuelsResult = await _refuelRepository.getForVehicle(vehicle.id);
    final refuelsFailure = refuelsResult.getLeft().toNullable();
    if (refuelsFailure != null) return left(refuelsFailure);
    final refuels = refuelsResult.getRight().toNullable()!;

    final logResult = await _serviceLogRepository.getForVehicle(vehicle.id);
    final logFailure = logResult.getLeft().toNullable();
    if (logFailure != null) return left(logFailure);
    final log = logResult.getRight().toNullable()!;

    final readingsResult = await _readingRepository.getForVehicle(vehicle.id);
    final readingsFailure = readingsResult.getLeft().toNullable();
    if (readingsFailure != null) return left(readingsFailure);
    final readings = readingsResult.getRight().toNullable()!;

    final now = DateTime.now();
    final latest = LatestOdometerCalculator.of(refuels, readings);
    final averageDailyDistance = ServiceDueCalculator.averageDailyDistance(
      refuels,
    );
    return right([
      for (final template in ServiceTemplate.values)
        _calculator.statusFor(
          template: template,
          kmInterval: template.kmIntervalFor(vehicle),
          dayInterval: template.dayIntervalFor(vehicle),
          baselineOdometer: ServiceDueCalculator.baselineOdometer(
            refuels,
            log,
            template,
          ),
          baselineDate: ServiceDueCalculator.baselineDate(
            refuels,
            log,
            template,
          ),
          latestOdometer: latest?.odometer,
          averageDailyDistance: averageDailyDistance,
          now: now,
        ),
    ]);
  }
}

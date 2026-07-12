import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../calculators/service_due_calculator.dart';
import '../entities/service_log_entry.dart';
import '../entities/vehicle.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/service_log_repository.dart';
import '../value_objects/service_due_status.dart';

/// Where a vehicle's two maintenance templates currently stand, for the
/// dashboard glance and the service log screen's header.
class GetServiceDue {
  const GetServiceDue(this._refuelRepository, this._serviceLogRepository);

  final RefuelRepository _refuelRepository;
  final ServiceLogRepository _serviceLogRepository;

  static const _calculator = ServiceDueCalculator();

  Future<Result<List<ServiceDueStatus>>> execute(Vehicle vehicle) async {
    final refuelsResult = await _refuelRepository.getForVehicle(vehicle.id);
    return refuelsResult.match(
      (failure) => Future<Result<List<ServiceDueStatus>>>.value(left(failure)),
      (refuels) async {
        final logResult = await _serviceLogRepository.getForVehicle(vehicle.id);
        return logResult.map((log) {
          final now = DateTime.now();
          final latestOdometer = refuels.isEmpty ? null : refuels.last.odometer;
          final averageDailyDistance =
              ServiceDueCalculator.averageDailyDistance(refuels);
          return [
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
                latestOdometer: latestOdometer,
                averageDailyDistance: averageDailyDistance,
                now: now,
              ),
          ];
        });
      },
    );
  }
}

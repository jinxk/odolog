/// Pure logic that turns vehicles and their service and refuel history into
/// the reminders that should be scheduled. Mirrors
/// [DocumentReminderPlanner]'s shape: no platform dependency, a plain
/// function of its inputs and the current time.
library;

import '../entities/refuel_entry.dart';
import '../entities/service_log_entry.dart';
import '../entities/vehicle.dart';
import '../value_objects/service_reminder.dart';
import 'service_due_calculator.dart';

class ServiceReminderPlanner {
  const ServiceReminderPlanner();

  static const _calculator = ServiceDueCalculator();

  /// The set of reminders to schedule across every vehicle in
  /// [refuelsByVehicle]'s keys, dropping any whose fire time is already in
  /// the past relative to [now]. A template with no projectable due date (no
  /// date dimension and not enough refuel history to project the distance
  /// dimension) contributes nothing, even though its distance countdown may
  /// still show in the UI.
  List<ServiceReminder> plan(
    Iterable<Vehicle> vehicles, {
    required Map<int, List<RefuelEntry>> refuelsByVehicle,
    required Map<int, List<ServiceLogEntry>> serviceLogByVehicle,
    required DateTime now,
  }) {
    final reminders = <ServiceReminder>[];
    for (final vehicle in vehicles) {
      final refuels = refuelsByVehicle[vehicle.id] ?? const [];
      final log = serviceLogByVehicle[vehicle.id] ?? const [];
      final latestOdometer = refuels.isEmpty ? null : refuels.last.odometer;
      final averageDailyDistance = ServiceDueCalculator.averageDailyDistance(
        refuels,
      );
      for (final template in ServiceTemplate.values) {
        final status = _calculator.statusFor(
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
        );
        final dueDate = status.projectedDueDate;
        if (dueDate == null) continue;
        final fireAt = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          ServiceDueCalculator.fireHour,
        );
        if (!fireAt.isAfter(now)) continue;
        reminders.add(
          ServiceReminder(
            vehicleId: vehicle.id,
            vehicleName: vehicle.name,
            template: template,
            fireAt: fireAt,
          ),
        );
      }
    }
    return reminders;
  }
}

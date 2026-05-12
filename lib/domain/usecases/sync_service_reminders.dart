import '../calculators/service_reminder_planner.dart';
import '../entities/refuel_entry.dart';
import '../entities/service_log_entry.dart';
import '../entities/vehicle.dart';
import '../reminders/reminder_scheduler.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/service_log_repository.dart';

/// Reschedules every service due reminder to match the current vehicles.
/// Called on app start and whenever the vehicle list changes (an interval
/// edit invalidates it, same as a document date edit), and explicitly after
/// logging a service, since that does not otherwise change the vehicle list.
class SyncServiceReminders {
  const SyncServiceReminders(
    this._scheduler,
    this._refuelRepository,
    this._serviceLogRepository,
  );

  final ReminderScheduler _scheduler;
  final RefuelRepository _refuelRepository;
  final ServiceLogRepository _serviceLogRepository;

  static const _planner = ServiceReminderPlanner();

  /// Recomputes the reminders for [vehicles] and syncs them. Best effort,
  /// like [SyncDocumentReminders]: a scheduler that cannot schedule leaves the
  /// app working normally.
  Future<void> execute(Iterable<Vehicle> vehicles) async {
    final refuelsByVehicle = <int, List<RefuelEntry>>{};
    final serviceLogByVehicle = <int, List<ServiceLogEntry>>{};
    for (final vehicle in vehicles) {
      final refuels = await _refuelRepository.getForVehicle(vehicle.id);
      refuels.match((_) {}, (list) => refuelsByVehicle[vehicle.id] = list);
      final log = await _serviceLogRepository.getForVehicle(vehicle.id);
      log.match((_) {}, (list) => serviceLogByVehicle[vehicle.id] = list);
    }
    final reminders = _planner.plan(
      vehicles,
      refuelsByVehicle: refuelsByVehicle,
      serviceLogByVehicle: serviceLogByVehicle,
      now: DateTime.now(),
    );
    await _scheduler.syncServiceReminders(reminders);
  }
}

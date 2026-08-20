import '../calculators/document_reminder_planner.dart';
import '../calculators/service_reminder_planner.dart';
import '../entities/odometer_reading.dart';
import '../entities/refuel_entry.dart';
import '../entities/service_log_entry.dart';
import '../entities/vehicle.dart';
import '../repositories/odometer_reading_repository.dart';
import '../repositories/refuel_repository.dart';
import '../repositories/service_log_repository.dart';
import '../value_objects/document_reminder.dart';
import '../value_objects/service_reminder.dart';

/// The one place the two planners are driven from. Both sync use cases and
/// the use case that lists what is scheduled call these methods, so the list
/// the user reads and the set handed to the scheduler come from the same
/// inputs and cannot drift apart.
class ReminderPlanning {
  const ReminderPlanning(
    this._refuelRepository,
    this._serviceLogRepository,
    this._readingRepository,
  );

  final RefuelRepository _refuelRepository;
  final ServiceLogRepository _serviceLogRepository;
  final OdometerReadingRepository _readingRepository;

  static const _documentPlanner = DocumentReminderPlanner();
  static const _servicePlanner = ServiceReminderPlanner();

  List<DocumentReminder> documentReminders(
    Iterable<Vehicle> vehicles, {
    required DateTime now,
  }) {
    return _documentPlanner.plan(vehicles, now: now);
  }

  /// Reads each vehicle's refuel, service, and reading history and plans the
  /// service due reminders from it. A history a repository cannot return is
  /// left empty rather than failing the plan: a reminder is a helper on top of
  /// the log, not the log itself.
  Future<List<ServiceReminder>> serviceReminders(
    Iterable<Vehicle> vehicles, {
    required DateTime now,
  }) async {
    final refuelsByVehicle = <int, List<RefuelEntry>>{};
    final serviceLogByVehicle = <int, List<ServiceLogEntry>>{};
    final readingsByVehicle = <int, List<OdometerReading>>{};
    for (final vehicle in vehicles) {
      final refuels = await _refuelRepository.getForVehicle(vehicle.id);
      refuels.match((_) {}, (list) => refuelsByVehicle[vehicle.id] = list);
      final log = await _serviceLogRepository.getForVehicle(vehicle.id);
      log.match((_) {}, (list) => serviceLogByVehicle[vehicle.id] = list);
      final readings = await _readingRepository.getForVehicle(vehicle.id);
      readings.match((_) {}, (list) => readingsByVehicle[vehicle.id] = list);
    }
    return _servicePlanner.plan(
      vehicles,
      refuelsByVehicle: refuelsByVehicle,
      serviceLogByVehicle: serviceLogByVehicle,
      readingsByVehicle: readingsByVehicle,
      now: now,
    );
  }
}

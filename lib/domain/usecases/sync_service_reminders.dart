import '../entities/vehicle.dart';
import '../reminders/reminder_planning.dart';
import '../reminders/reminder_scheduler.dart';

/// Reschedules every service due reminder to match the current vehicles.
/// Called on app start and whenever the vehicle list changes (an interval
/// edit invalidates it, same as a document date edit), and explicitly after
/// logging a service, since that does not otherwise change the vehicle list.
class SyncServiceReminders {
  const SyncServiceReminders(this._scheduler, this._planning);

  final ReminderScheduler _scheduler;
  final ReminderPlanning _planning;

  /// Recomputes the reminders for [vehicles] and syncs them. Best effort,
  /// like [SyncDocumentReminders]: a scheduler that cannot schedule leaves the
  /// app working normally.
  Future<void> execute(Iterable<Vehicle> vehicles) async {
    final reminders = await _planning.serviceReminders(
      vehicles,
      now: DateTime.now(),
    );
    await _scheduler.syncServiceReminders(reminders);
  }
}

import '../calculators/document_reminder_planner.dart';
import '../entities/vehicle.dart';
import '../reminders/reminder_scheduler.dart';

/// Reschedules every document expiry reminder to match the current vehicles.
/// Runs on app start and after any vehicle edit, so a newly entered or cleared
/// date takes effect immediately. It plans against the wall clock at call time
/// and hands the full set to the scheduler, which reconciles the device.
class SyncDocumentReminders {
  const SyncDocumentReminders(this._scheduler);

  final ReminderScheduler _scheduler;

  static const _planner = DocumentReminderPlanner();

  /// Recomputes the reminders for [vehicles] and syncs them. Best effort: a
  /// scheduler that cannot schedule leaves the app working normally, since the
  /// reminders are a helper on top of the log, not the log itself.
  Future<void> execute(Iterable<Vehicle> vehicles) {
    final reminders = _planner.plan(vehicles, now: DateTime.now());
    return _scheduler.sync(reminders);
  }
}

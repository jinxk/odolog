import '../entities/service_log_entry.dart';
import '../entities/vehicle.dart';
import '../reminders/reminder_planning.dart';
import '../value_objects/scheduled_reminder.dart';

/// Lists the reminders that are currently scheduled, for the settings screen.
/// It runs the same planning the sync use cases run, so the list matches what
/// the scheduler was last handed rather than reporting the device's pending
/// requests, which carry no fire time.
class GetScheduledReminders {
  const GetScheduledReminders(this._planning);

  final ReminderPlanning _planning;

  /// Every reminder for [vehicles] in the categories that are switched on,
  /// soonest first.
  Future<List<ScheduledReminder>> execute(
    Iterable<Vehicle> vehicles, {
    bool documents = true,
    bool services = true,
  }) async {
    final rows = <ScheduledReminder>[];
    if (documents) {
      for (final reminder in _planning.documentReminders(
        vehicles,
        now: DateTime.now(),
      )) {
        rows.add(
          ScheduledReminder(
            category: ReminderCategory.document,
            title: '${_documentTitle(reminder.document)} expiry',
            vehicleName: reminder.vehicleName,
            fireAt: reminder.fireAt,
          ),
        );
      }
    }
    if (services) {
      final planned = await _planning.serviceReminders(
        vehicles,
        now: DateTime.now(),
      );
      for (final reminder in planned) {
        rows.add(
          ScheduledReminder(
            category: ReminderCategory.service,
            title: _serviceTitle(reminder.template),
            vehicleName: reminder.vehicleName,
            fireAt: reminder.fireAt,
          ),
        );
      }
    }
    rows.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return rows;
  }

  String _documentTitle(VehicleDocument document) => switch (document) {
    VehicleDocument.insurance => 'Insurance',
    VehicleDocument.puc => 'PUC',
    VehicleDocument.rc => 'RC',
    VehicleDocument.fitness => 'Fitness',
  };

  String _serviceTitle(ServiceTemplate template) => switch (template) {
    ServiceTemplate.engineOil => 'Engine oil',
    ServiceTemplate.generalService => 'General service',
  };
}

import 'package:odolog/domain/reminders/reminder_scheduler.dart';
import 'package:odolog/domain/value_objects/document_reminder.dart';
import 'package:odolog/domain/value_objects/service_reminder.dart';

/// In-memory [ReminderScheduler] for tests. Records the reminders it was last
/// asked to sync and whether [cancelAll] ran, with no plugin behind it.
class FakeReminderScheduler implements ReminderScheduler {
  List<DocumentReminder> synced = [];
  List<ServiceReminder> syncedServiceReminders = [];
  bool cancelledAll = false;

  @override
  Future<void> sync(List<DocumentReminder> reminders) async {
    synced = reminders;
  }

  @override
  Future<void> syncServiceReminders(List<ServiceReminder> reminders) async {
    syncedServiceReminders = reminders;
  }

  @override
  Future<void> cancelAll() async {
    cancelledAll = true;
  }
}

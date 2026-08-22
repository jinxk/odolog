import 'package:odolog/domain/reminders/reminder_scheduler.dart';
import 'package:odolog/domain/value_objects/document_reminder.dart';
import 'package:odolog/domain/value_objects/service_reminder.dart';

/// In-memory [ReminderScheduler] for tests. Records the reminders it was last
/// asked to sync, whether [cancelAll], [showTest], and [requestPermission]
/// ran, and answers [notificationsEnabled] with whatever the test set, with
/// no plugin behind it.
class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({this.enabled});

  /// What [notificationsEnabled] returns. Null is the real scheduler's answer
  /// off Android.
  final bool? enabled;

  List<DocumentReminder> synced = [];
  List<ServiceReminder> syncedServiceReminders = [];
  bool cancelledAll = false;
  bool shownTest = false;
  bool permissionRequested = false;

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

  @override
  Future<void> showTest() async {
    shownTest = true;
  }

  @override
  Future<bool?> notificationsEnabled() async => enabled;

  @override
  Future<void> requestPermission() async {
    permissionRequested = true;
  }
}

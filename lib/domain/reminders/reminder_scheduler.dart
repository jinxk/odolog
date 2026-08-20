import '../value_objects/document_reminder.dart';
import '../value_objects/service_reminder.dart';

/// Port for the platform that actually schedules local notifications. The
/// domain decides which reminders should exist; an implementation in an outer
/// layer makes the device match. Kept as an interface here so the domain stays
/// free of any notification plugin.
abstract interface class ReminderScheduler {
  /// Makes the scheduled document expiry notifications on the device equal
  /// [reminders]: a full reconcile of that category, not an append. Callers
  /// pass the complete set of future reminders and the implementation cancels
  /// anything in this category no longer in it, so a document whose date was
  /// cleared or pushed out stops firing. Service due reminders, synced
  /// separately through [syncServiceReminders], are untouched. Best effort by
  /// contract: a platform that cannot schedule (permission denied, no
  /// notification support) does nothing rather than failing the caller.
  Future<void> sync(List<DocumentReminder> reminders);

  /// Makes the scheduled service due notifications on the device equal
  /// [reminders]: a full reconcile of that category, not an append, and not
  /// the document expiry category [sync] manages. Best effort, same contract
  /// as [sync].
  Future<void> syncServiceReminders(List<ServiceReminder> reminders);

  /// Cancels every scheduled notification in both categories. Used when
  /// there is nothing left on the device for either category to reconcile
  /// against, such as after the delete all data feature runs. Best effort,
  /// same contract as [sync].
  Future<void> cancelAll();

  /// Posts one notification immediately so the user can see for themselves
  /// that reminders arrive on this phone. Its id sits outside both category
  /// ranges, so it never displaces a scheduled reminder. Best effort, same
  /// contract as [sync].
  Future<void> showTest();

  /// Whether the platform will show the app's notifications: false once the
  /// user has turned them off for the app, null when that cannot be answered,
  /// which covers every platform but Android.
  Future<bool?> notificationsEnabled();
}

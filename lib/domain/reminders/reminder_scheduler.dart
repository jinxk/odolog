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
}

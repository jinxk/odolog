import '../value_objects/document_reminder.dart';

/// Port for the platform that actually schedules local notifications. The
/// domain decides which reminders should exist; an implementation in an outer
/// layer makes the device match. Kept as an interface here so the domain stays
/// free of any notification plugin.
abstract interface class ReminderScheduler {
  /// Makes the scheduled notifications on the device equal [reminders]: a full
  /// reconcile, not an append. Callers pass the complete set of future
  /// reminders and the implementation cancels anything no longer in it, so a
  /// document whose date was cleared or pushed out stops firing. Best effort by
  /// contract: a platform that cannot schedule (permission denied, no
  /// notification support) does nothing rather than failing the caller.
  Future<void> sync(List<DocumentReminder> reminders);
}

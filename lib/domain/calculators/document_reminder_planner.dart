/// Pure logic that turns the document expiry dates stored on vehicles into the
/// reminders that should be scheduled and the single alert worth glancing at.
/// It holds no platform dependency on purpose: scheduling and display live in
/// other layers, and everything here is a plain function of the vehicles and
/// the current time, so it is covered by ordinary unit tests.
library;

import '../entities/vehicle.dart';
import '../value_objects/document_alert.dart';
import '../value_objects/document_reminder.dart';

class DocumentReminderPlanner {
  const DocumentReminderPlanner();

  /// Lead times, in days before an expiry, at which a reminder fires. Ordered
  /// far to near so the earliest warning comes first.
  static const leadDays = [30, 15, 7, 1];

  /// The hour of the local day a reminder fires at. Mid morning, not midnight,
  /// so it lands when the owner can act on it rather than while asleep.
  static const fireHour = 9;

  /// The set of reminders to schedule across every [vehicle], dropping any
  /// whose fire time is already in the past relative to [now]. A vehicle with
  /// no dates set contributes nothing. The result is deterministic given the
  /// same inputs, which is what lets a full reschedule replace the previous
  /// set without leaving stale notifications behind.
  List<DocumentReminder> plan(
    Iterable<Vehicle> vehicles, {
    required DateTime now,
  }) {
    final reminders = <DocumentReminder>[];
    for (final vehicle in vehicles) {
      for (final document in VehicleDocument.values) {
        final expiry = vehicle.expiryFor(document);
        if (expiry == null) continue;
        for (final days in leadDays) {
          final fireDay = _dateOnly(expiry).subtract(Duration(days: days));
          final fireAt = DateTime(
            fireDay.year,
            fireDay.month,
            fireDay.day,
            fireHour,
          );
          if (!fireAt.isAfter(now)) continue;
          reminders.add(
            DocumentReminder(
              vehicleId: vehicle.id,
              vehicleName: vehicle.name,
              document: document,
              expiry: expiry,
              daysBefore: days,
              fireAt: fireAt,
            ),
          );
        }
      }
    }
    return reminders;
  }

  /// The most urgent document on [vehicle] that is within [withinDays] of
  /// expiring or already overdue, or null when nothing qualifies. An overdue
  /// document always outranks an upcoming one because its fine is already
  /// accruing. Ties break toward the sooner expiry.
  DocumentAlert? nearestAlert(
    Vehicle vehicle, {
    required DateTime now,
    int withinDays = 30,
  }) {
    final today = _dateOnly(now);
    DocumentAlert? best;
    for (final document in VehicleDocument.values) {
      final expiry = vehicle.expiryFor(document);
      if (expiry == null) continue;
      final daysRemaining = _dateOnly(expiry).difference(today).inDays;
      if (daysRemaining > withinDays) continue;
      if (best == null || daysRemaining < best.daysRemaining) {
        best = DocumentAlert(
          document: document,
          expiry: expiry,
          daysRemaining: daysRemaining,
        );
      }
    }
    return best;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

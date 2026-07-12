import '../entities/refuel_entry.dart';
import '../entities/service_log_entry.dart';
import '../entities/vehicle.dart';
import '../value_objects/service_due_status.dart';

/// Pure logic that turns a vehicle's service history and refuel history into
/// where each maintenance template stands. No platform dependency: scheduling
/// and display live in other layers, and everything here is a plain function
/// of the inputs, so it is covered by ordinary unit tests.
class ServiceDueCalculator {
  const ServiceDueCalculator();

  /// Default engine oil interval when a vehicle has not set its own, in km.
  static const defaultEngineOilIntervalKm = 3000.0;

  /// Default general service interval when a vehicle has not set its own, in
  /// days.
  static const defaultGeneralServiceIntervalDays = 180;

  /// The hour of the local day a service reminder fires at, matching the
  /// document reminder convention.
  static const fireHour = 9;

  /// Where [template] stands against one interval, or two when the template
  /// has both a distance and a date dimension: whichever crosses zero first
  /// marks it overdue, and whichever yields the earlier calendar date wins as
  /// [ServiceDueStatus.projectedDueDate]. [kmInterval] and [dayInterval] are
  /// each null when that dimension does not apply. [baselineOdometer] and
  /// [baselineDate] are the last service point: the most recent matching log
  /// entry, or the vehicle's earliest known reading when nothing has been
  /// logged yet. [averageDailyDistance] projects a calendar date for the
  /// distance dimension, since a notification needs a wall clock time; pass
  /// null when there is not enough refuel history to estimate a pace, and the
  /// distance dimension will still report [ServiceDueStatus.remainingKm] but
  /// contribute no date.
  ServiceDueStatus statusFor({
    required ServiceTemplate template,
    double? kmInterval,
    int? dayInterval,
    double? baselineOdometer,
    DateTime? baselineDate,
    double? latestOdometer,
    double? averageDailyDistance,
    required DateTime now,
  }) {
    double? remainingKm;
    if (kmInterval != null &&
        baselineOdometer != null &&
        latestOdometer != null) {
      remainingKm = baselineOdometer + kmInterval - latestOdometer;
    }

    DateTime? dueByDate;
    int? remainingDays;
    if (dayInterval != null && baselineDate != null) {
      dueByDate = _dateOnly(baselineDate).add(Duration(days: dayInterval));
      remainingDays = dueByDate.difference(_dateOnly(now)).inDays;
    }

    DateTime? dueByProjectedKm;
    if (remainingKm != null &&
        averageDailyDistance != null &&
        averageDailyDistance > 0) {
      final daysToGo = (remainingKm / averageDailyDistance).ceil();
      dueByProjectedKm = _dateOnly(now).add(Duration(days: daysToGo));
    }

    final overdue =
        (remainingKm != null && remainingKm <= 0) ||
        (remainingDays != null && remainingDays <= 0);

    return ServiceDueStatus(
      template: template,
      remainingKm: remainingKm,
      remainingDays: remainingDays,
      projectedDueDate: _earlier(dueByDate, dueByProjectedKm),
      overdue: overdue,
    );
  }

  /// The most recent log entry for [template], or null when the template has
  /// never been logged for this vehicle.
  static ServiceLogEntry? lastLogFor(
    List<ServiceLogEntry> log,
    ServiceTemplate template,
  ) {
    ServiceLogEntry? latest;
    for (final entry in log) {
      if (entry.template != template) continue;
      if (latest == null || entry.performedAt.isAfter(latest.performedAt)) {
        latest = entry;
      }
    }
    return latest;
  }

  /// The odometer baseline for [template]: the last matching service, or the
  /// vehicle's earliest known reading when it has never been serviced. Null
  /// when there is no refuel history at all to fall back on.
  static double? baselineOdometer(
    List<RefuelEntry> refuels,
    List<ServiceLogEntry> log,
    ServiceTemplate template,
  ) {
    final lastLog = lastLogFor(log, template);
    if (lastLog != null) return lastLog.odometer;
    return refuels.isEmpty ? null : refuels.first.odometer;
  }

  /// The date baseline for [template]: the last matching service, or the
  /// vehicle's earliest known fill date when it has never been serviced.
  static DateTime? baselineDate(
    List<RefuelEntry> refuels,
    List<ServiceLogEntry> log,
    ServiceTemplate template,
  ) {
    final lastLog = lastLogFor(log, template);
    if (lastLog != null) return lastLog.performedAt;
    return refuels.isEmpty ? null : refuels.first.filledAt;
  }

  /// Average km driven per day across the full refuel history, or null when
  /// there are fewer than two fills or the span is degenerate (same day, or a
  /// non-increasing reading). Used only to project a calendar date for a
  /// distance-only template; the actual distance countdown never depends on
  /// this figure.
  static double? averageDailyDistance(List<RefuelEntry> refuels) {
    if (refuels.length < 2) return null;
    final totalDistance = refuels.last.odometer - refuels.first.odometer;
    final totalDays = refuels.last.filledAt
        .difference(refuels.first.filledAt)
        .inDays;
    if (totalDistance <= 0 || totalDays <= 0) return null;
    return totalDistance / totalDays;
  }

  static DateTime? _earlier(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

/// Reads each template's editable interval off a vehicle, falling back to the
/// calculator's default when the vehicle has not set its own. Kept as an
/// extension rather than fields on [ServiceTemplate] because the interval is
/// per vehicle, not a property of the template itself.
extension ServiceTemplateIntervals on ServiceTemplate {
  /// The distance interval for this template, or null when this template has
  /// no distance dimension.
  double? kmIntervalFor(Vehicle vehicle) => switch (this) {
    ServiceTemplate.engineOil =>
      vehicle.engineOilIntervalKm ??
          ServiceDueCalculator.defaultEngineOilIntervalKm,
    ServiceTemplate.generalService => null,
  };

  /// The date interval for this template, or null when this template has no
  /// date dimension.
  int? dayIntervalFor(Vehicle vehicle) => switch (this) {
    ServiceTemplate.engineOil => null,
    ServiceTemplate.generalService =>
      vehicle.generalServiceIntervalDays ??
          ServiceDueCalculator.defaultGeneralServiceIntervalDays,
  };
}

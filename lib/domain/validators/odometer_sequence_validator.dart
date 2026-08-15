import '../../core/failures.dart';
import '../entities/odometer_reading.dart';
import '../entities/refuel_entry.dart';

/// One dated odometer reading, from a fill or a manual update. The sequence
/// check compares both kinds against each other.
typedef OdometerPoint = ({DateTime at, double odometer});

/// Checks that a reading's odometer agrees with its date: greater than the
/// closest reading logged before it and less than the closest reading logged
/// after it. Comparing against the date neighbours instead of the highest
/// reading on record lets a backdated fill with a historically correct
/// odometer pass without the override.
class OdometerSequenceValidator {
  const OdometerSequenceValidator._();

  static OdometerPoint refuelPoint(RefuelEntry entry) =>
      (at: entry.filledAt, odometer: entry.odometer);

  static OdometerPoint readingPoint(OdometerReading reading) =>
      (at: reading.recordedAt, odometer: reading.odometer);

  /// Every fill and manual reading a vehicle has, as one list of points, ready
  /// to hand to [check].
  static List<OdometerPoint> pointsOf(
    Iterable<RefuelEntry> refuels,
    Iterable<OdometerReading> readings,
  ) => [
    for (final entry in refuels) refuelPoint(entry),
    for (final reading in readings) readingPoint(reading),
  ];

  /// Null when [point] fits between its neighbours in [others], otherwise the
  /// failure to report against the odometer field. Ties on the timestamp are
  /// treated as earlier records, so a same-moment duplicate still needs a
  /// higher reading.
  static ValidationFailure? check(
    OdometerPoint point,
    Iterable<OdometerPoint> others,
  ) {
    OdometerPoint? before;
    OdometerPoint? after;
    for (final other in others) {
      if (other.at.isAfter(point.at)) {
        if (after == null ||
            other.at.isBefore(after.at) ||
            (other.at == after.at && other.odometer < after.odometer)) {
          after = other;
        }
      } else {
        if (before == null ||
            other.at.isAfter(before.at) ||
            (other.at == before.at && other.odometer > before.odometer)) {
          before = other;
        }
      }
    }
    if (before != null && point.odometer <= before.odometer) {
      return const ValidationFailure(
        field: 'odometer',
        reason: 'Odometer must be greater than the previous reading.',
      );
    }
    if (after != null && point.odometer >= after.odometer) {
      return const ValidationFailure(
        field: 'odometer',
        reason: 'Odometer must be less than the next reading.',
      );
    }
    return null;
  }
}

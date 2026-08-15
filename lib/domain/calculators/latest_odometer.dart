import '../entities/odometer_reading.dart';
import '../entities/refuel_entry.dart';

/// The highest odometer a vehicle is known to have reached, and when it was
/// recorded.
typedef LatestOdometer = ({double odometer, DateTime at});

/// Picks the highest reading across a vehicle's fills and its manual odometer
/// updates. A pure helper rather than a use case so [ServiceReminderPlanner],
/// which takes plain lists and no repositories, can use the same rule as the
/// screens.
abstract final class LatestOdometerCalculator {
  /// Null when the vehicle has neither a fill nor a reading. A tie between a
  /// fill and a reading at the same odometer resolves to the earlier date, so
  /// the figure does not jump around on a duplicate entry.
  static LatestOdometer? of(
    Iterable<RefuelEntry> refuels,
    Iterable<OdometerReading> readings,
  ) {
    LatestOdometer? best;
    void consider(double odometer, DateTime at) {
      if (best == null ||
          odometer > best!.odometer ||
          (odometer == best!.odometer && at.isBefore(best!.at))) {
        best = (odometer: odometer, at: at);
      }
    }

    for (final entry in refuels) {
      consider(entry.odometer, entry.filledAt);
    }
    for (final reading in readings) {
      consider(reading.odometer, reading.recordedAt);
    }
    return best;
  }
}

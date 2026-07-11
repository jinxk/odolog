import '../entities/refuel_entry.dart';
import '../value_objects/entry_derived.dart';
import '../value_objects/window_mileage.dart';

/// Pure full-tank window math. Every method takes the entry list already
/// ordered by odometer then time, exactly as the refuel repository returns it,
/// and returns plain value objects. No Flutter, no database, no Riverpod.
class MileageCalculator {
  const MileageCalculator();

  /// Price per unit and distance since the previous entry, one per entry.
  List<EntryDerived> perEntry(List<RefuelEntry> entries) {
    final derived = <EntryDerived>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      derived.add(
        EntryDerived(
          pricePerUnit: entry.pricePaid / entry.quantity,
          distanceSincePrevious: i == 0
              ? null
              : entry.odometer - entries[i - 1].odometer,
        ),
      );
    }
    return derived;
  }

  /// Closed full-tank windows in odometer order.
  ///
  /// A window opens at a full fill and closes at the next full fill. The fuel
  /// and cost of the opening fill are deliberately left out: they were burned
  /// before this window began and belong to the previous window. Only fills
  /// after the opening, up to and including the closing fill, count here.
  List<WindowMileage> windows(List<RefuelEntry> entries) {
    final result = <WindowMileage>[];
    int? openingIndex;
    var fuelConsumed = 0.0;
    var costInWindow = 0.0;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];

      if (openingIndex == null) {
        // Nothing before the first full fill belongs to any window.
        if (entry.fullTank) {
          openingIndex = i;
        }
        continue;
      }

      fuelConsumed += entry.quantity;
      costInWindow += entry.pricePaid;

      if (entry.fullTank) {
        final opening = entries[openingIndex];
        final distance = entry.odometer - opening.odometer;

        if (distance <= 0) {
          // A non-increasing odometer, reachable through the override, would
          // give an infinite or negative mileage, so this window is dropped.
          // The fill still opens the next window, so its own fuel and cost are
          // backed out of the running totals (they belong to the opening, not
          // to the window it opens). What was burned since the previous opening
          // stays accumulated and rolls into the next window.
          fuelConsumed -= entry.quantity;
          costInWindow -= entry.pricePaid;
          openingIndex = i;
          continue;
        }

        result.add(
          WindowMileage(
            openingEntryId: opening.id,
            closingEntryId: entry.id,
            distance: distance,
            fuelConsumed: fuelConsumed,
            mileage: distance / fuelConsumed,
            costInWindow: costInWindow,
            costPerKm: costInWindow / distance,
          ),
        );
        openingIndex = i;
        fuelConsumed = 0.0;
        costInWindow = 0.0;
      }
    }

    return result;
  }

  /// The most recently closed full-tank window, or null if none has closed.
  WindowMileage? latestWindow(List<RefuelEntry> entries) {
    final closed = windows(entries);
    return closed.isEmpty ? null : closed.last;
  }

  /// Distance driven between the last two entries, or null before the second.
  double? lastFillRange(List<RefuelEntry> entries) {
    if (entries.length < 2) return null;
    return entries.last.odometer - entries[entries.length - 2].odometer;
  }

  /// Latest window mileage projected over a full tank, null without capacity
  /// or before a window has closed.
  double? projectedRange(List<RefuelEntry> entries, double? tankCapacity) {
    if (tankCapacity == null) return null;
    final latest = latestWindow(entries);
    if (latest == null) return null;
    return latest.mileage * tankCapacity;
  }
}

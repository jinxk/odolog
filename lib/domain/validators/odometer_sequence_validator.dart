import '../../core/failures.dart';
import '../entities/refuel_entry.dart';

/// Checks that a fill's odometer agrees with its date: greater than the
/// closest reading logged before it and less than the closest reading logged
/// after it. Comparing against the date neighbours instead of the highest
/// reading on record lets a backdated fill with a historically correct
/// odometer pass without the override.
class OdometerSequenceValidator {
  const OdometerSequenceValidator._();

  /// Null when [entry] fits between its neighbours in [others], otherwise the
  /// failure to report against the odometer field. Ties on the timestamp are
  /// treated as earlier fills, so a same-moment duplicate still needs a
  /// higher reading.
  static ValidationFailure? check(
    RefuelEntry entry,
    Iterable<RefuelEntry> others,
  ) {
    RefuelEntry? before;
    RefuelEntry? after;
    for (final other in others) {
      if (other.filledAt.isAfter(entry.filledAt)) {
        if (after == null ||
            other.filledAt.isBefore(after.filledAt) ||
            (other.filledAt == after.filledAt &&
                other.odometer < after.odometer)) {
          after = other;
        }
      } else {
        if (before == null ||
            other.filledAt.isAfter(before.filledAt) ||
            (other.filledAt == before.filledAt &&
                other.odometer > before.odometer)) {
          before = other;
        }
      }
    }
    if (before != null && entry.odometer <= before.odometer) {
      return const ValidationFailure(
        field: 'odometer',
        reason: 'Odometer must be greater than the previous reading.',
      );
    }
    if (after != null && entry.odometer >= after.odometer) {
      return const ValidationFailure(
        field: 'odometer',
        reason: 'Odometer must be less than the next reading.',
      );
    }
    return null;
  }
}

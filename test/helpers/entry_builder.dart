import 'package:odolog/domain/entities/refuel_entry.dart';

/// Builds a [RefuelEntry] with only the fields a test cares about. The window
/// and per-entry math keys off odometer, quantity, price, and the full-tank
/// flag, so those are the parameters; [filledAt] is supplied only by tests that
/// exercise time-based grouping.
RefuelEntry entry({
  required int id,
  required double odometer,
  required double quantity,
  required double pricePaid,
  bool fullTank = true,
  bool odometerOverride = false,
  int vehicleId = 1,
  DateTime? filledAt,
}) {
  return RefuelEntry(
    id: id,
    vehicleId: vehicleId,
    filledAt: filledAt ?? DateTime.utc(2020).add(Duration(minutes: id)),
    odometer: odometer,
    quantity: quantity,
    pricePaid: pricePaid,
    fullTank: fullTank,
    odometerOverride: odometerOverride,
  );
}

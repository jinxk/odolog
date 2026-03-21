import '../../domain/entities/refuel_entry.dart';

/// Maps a [RefuelEntry] to and from a `refuel_entries` table row. Timestamps
/// are epoch millis, flags are 0 or 1. An entry with id 0 is unsaved, so its
/// id is omitted and SQLite assigns one.
class RefuelRow {
  const RefuelRow._();

  static const table = 'refuel_entries';

  static Map<String, Object?> toMap(RefuelEntry entry) {
    return {
      if (entry.id != 0) 'id': entry.id,
      'vehicle_id': entry.vehicleId,
      'filled_at': entry.filledAt.millisecondsSinceEpoch,
      'odometer': entry.odometer,
      'quantity': entry.quantity,
      'price_paid': entry.pricePaid,
      'full_tank': entry.fullTank ? 1 : 0,
      'variant_id': entry.variantId,
      'variant_other': entry.variantOther,
      'station_name': entry.stationName,
      'notes': entry.notes,
      'odometer_override': entry.odometerOverride ? 1 : 0,
    };
  }

  static RefuelEntry fromMap(Map<String, Object?> map) {
    return RefuelEntry(
      id: map['id']! as int,
      vehicleId: map['vehicle_id']! as int,
      filledAt: DateTime.fromMillisecondsSinceEpoch(map['filled_at']! as int),
      odometer: (map['odometer']! as num).toDouble(),
      quantity: (map['quantity']! as num).toDouble(),
      pricePaid: (map['price_paid']! as num).toDouble(),
      fullTank: (map['full_tank']! as int) == 1,
      variantId: map['variant_id'] as String?,
      variantOther: map['variant_other'] as String?,
      stationName: map['station_name'] as String?,
      notes: map['notes'] as String?,
      odometerOverride: (map['odometer_override']! as int) == 1,
    );
  }
}

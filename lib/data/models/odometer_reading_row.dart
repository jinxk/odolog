import '../../domain/entities/odometer_reading.dart';

/// Maps an [OdometerReading] to and from an `odometer_readings` table row.
/// Timestamps are epoch millis. A reading with id 0 is unsaved, so its id is
/// omitted and SQLite assigns one.
class OdometerReadingRow {
  const OdometerReadingRow._();

  static const table = 'odometer_readings';

  static Map<String, Object?> toMap(OdometerReading reading) {
    return {
      if (reading.id != 0) 'id': reading.id,
      'vehicle_id': reading.vehicleId,
      'odometer': reading.odometer,
      'recorded_at': reading.recordedAt.millisecondsSinceEpoch,
      'note': reading.note,
    };
  }

  static OdometerReading fromMap(Map<String, Object?> map) {
    return OdometerReading(
      id: map['id']! as int,
      vehicleId: map['vehicle_id']! as int,
      odometer: (map['odometer']! as num).toDouble(),
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        map['recorded_at']! as int,
      ),
      note: map['note'] as String?,
    );
  }
}

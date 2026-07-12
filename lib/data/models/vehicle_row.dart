import '../../domain/entities/vehicle.dart';

/// Maps a [Vehicle] to and from a `vehicles` table row. Enums are stored as
/// their name string, matching the TEXT values in the schema comments. Expiry
/// dates are stored as epoch milliseconds in INTEGER columns, the same
/// convention `refuel_entries.filled_at` uses. A vehicle with id 0 is unsaved,
/// so its id is omitted and SQLite assigns one.
class VehicleRow {
  const VehicleRow._();

  static const table = 'vehicles';

  static Map<String, Object?> toMap(Vehicle vehicle) {
    return {
      if (vehicle.id != 0) 'id': vehicle.id,
      'name': vehicle.name,
      'type': vehicle.type.name,
      'fuel_category': vehicle.fuelCategory.name,
      'registration': vehicle.registrationNo,
      'tank_capacity': vehicle.tankCapacity,
      'claimed_mileage': vehicle.claimedMileage,
      'insurance_expiry': vehicle.insuranceExpiry?.millisecondsSinceEpoch,
      'puc_expiry': vehicle.pucExpiry?.millisecondsSinceEpoch,
      'rc_expiry': vehicle.rcExpiry?.millisecondsSinceEpoch,
      'fitness_expiry': vehicle.fitnessExpiry?.millisecondsSinceEpoch,
      'engine_oil_interval_km': vehicle.engineOilIntervalKm,
      'general_service_interval_days': vehicle.generalServiceIntervalDays,
    };
  }

  static Vehicle fromMap(Map<String, Object?> map) {
    return Vehicle(
      id: map['id']! as int,
      name: map['name']! as String,
      type: VehicleType.values.byName(map['type']! as String),
      fuelCategory: FuelCategory.values.byName(map['fuel_category']! as String),
      registrationNo: map['registration'] as String?,
      tankCapacity: (map['tank_capacity'] as num?)?.toDouble(),
      claimedMileage: (map['claimed_mileage'] as num?)?.toDouble(),
      insuranceExpiry: _dateFrom(map['insurance_expiry']),
      pucExpiry: _dateFrom(map['puc_expiry']),
      rcExpiry: _dateFrom(map['rc_expiry']),
      fitnessExpiry: _dateFrom(map['fitness_expiry']),
      engineOilIntervalKm: (map['engine_oil_interval_km'] as num?)?.toDouble(),
      generalServiceIntervalDays: (map['general_service_interval_days'] as num?)
          ?.toInt(),
    );
  }

  static DateTime? _dateFrom(Object? value) => value == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch((value as num).toInt());
}

import '../../domain/entities/vehicle.dart';

/// Maps a [Vehicle] to and from a `vehicles` table row. Enums are stored as
/// their name string, matching the TEXT values in the schema comments. A
/// vehicle with id 0 is unsaved, so its id is omitted and SQLite assigns one.
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
    );
  }
}

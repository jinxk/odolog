import 'package:equatable/equatable.dart';

enum VehicleType { car, motorcycle, scooter, other }

enum FuelCategory {
  petrol('litre'),
  diesel('litre'),
  cng('kg'),
  lpg('litre');

  const FuelCategory(this.unit);

  /// The measurement unit every entry on a vehicle of this category uses.
  final String unit;
}

/// The legal papers whose expiry OdoLog can remind about. Each maps to one
/// nullable date on [Vehicle], read through [Vehicle.expiryFor], so the reminder
/// logic can iterate the documents without naming each field by hand.
enum VehicleDocument { insurance, puc, rc, fitness }

class Vehicle extends Equatable {
  const Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.fuelCategory,
    this.registrationNo,
    this.tankCapacity,
    this.claimedMileage,
    this.insuranceExpiry,
    this.pucExpiry,
    this.rcExpiry,
    this.fitnessExpiry,
  });

  final int id;
  final String name;
  final VehicleType type;
  final FuelCategory fuelCategory;
  final String? registrationNo;
  final double? tankCapacity;

  /// The manufacturer's claimed fuel economy, in km/l (km/kg for a CNG
  /// vehicle), so it can be shown next to the real figure the app measures.
  /// Null when the owner has not entered it; it never feeds the mileage math.
  final double? claimedMileage;

  /// Expiry of the vehicle's third party or comprehensive insurance. Null when
  /// unset, which suppresses every insurance reminder for this vehicle.
  final DateTime? insuranceExpiry;

  /// Expiry of the Pollution Under Control certificate. Null when unset.
  final DateTime? pucExpiry;

  /// Expiry of the Registration Certificate. Null when unset.
  final DateTime? rcExpiry;

  /// Expiry of the fitness certificate (commercial and older vehicles). Null
  /// when unset.
  final DateTime? fitnessExpiry;

  /// The expiry date stored for [document], or null when that document has no
  /// date set on this vehicle.
  DateTime? expiryFor(VehicleDocument document) => switch (document) {
    VehicleDocument.insurance => insuranceExpiry,
    VehicleDocument.puc => pucExpiry,
    VehicleDocument.rc => rcExpiry,
    VehicleDocument.fitness => fitnessExpiry,
  };

  Vehicle copyWith({
    int? id,
    String? name,
    VehicleType? type,
    FuelCategory? fuelCategory,
    String? registrationNo,
    double? tankCapacity,
    double? claimedMileage,
    DateTime? insuranceExpiry,
    DateTime? pucExpiry,
    DateTime? rcExpiry,
    DateTime? fitnessExpiry,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      fuelCategory: fuelCategory ?? this.fuelCategory,
      registrationNo: registrationNo ?? this.registrationNo,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      claimedMileage: claimedMileage ?? this.claimedMileage,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      pucExpiry: pucExpiry ?? this.pucExpiry,
      rcExpiry: rcExpiry ?? this.rcExpiry,
      fitnessExpiry: fitnessExpiry ?? this.fitnessExpiry,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    fuelCategory,
    registrationNo,
    tankCapacity,
    claimedMileage,
    insuranceExpiry,
    pucExpiry,
    rcExpiry,
    fitnessExpiry,
  ];
}

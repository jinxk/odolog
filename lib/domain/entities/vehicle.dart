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

class Vehicle extends Equatable {
  const Vehicle({
    required this.id,
    required this.name,
    required this.type,
    required this.fuelCategory,
    this.registrationNo,
    this.tankCapacity,
  });

  final int id;
  final String name;
  final VehicleType type;
  final FuelCategory fuelCategory;
  final String? registrationNo;
  final double? tankCapacity;

  Vehicle copyWith({
    int? id,
    String? name,
    VehicleType? type,
    FuelCategory? fuelCategory,
    String? registrationNo,
    double? tankCapacity,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      fuelCategory: fuelCategory ?? this.fuelCategory,
      registrationNo: registrationNo ?? this.registrationNo,
      tankCapacity: tankCapacity ?? this.tankCapacity,
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
  ];
}

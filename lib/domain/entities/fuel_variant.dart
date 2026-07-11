import 'package:equatable/equatable.dart';

import 'vehicle.dart';

class FuelVariant extends Equatable {
  const FuelVariant({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.name,
    required this.category,
    required this.unit,
    this.tier,
  });

  final String id;
  final String brandId;
  final String brandName;
  final String name;
  final FuelCategory category;
  final String? tier;
  final String unit;

  @override
  List<Object?> get props => [
    id,
    brandId,
    brandName,
    name,
    category,
    tier,
    unit,
  ];
}

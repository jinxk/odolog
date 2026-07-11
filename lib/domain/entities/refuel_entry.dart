import 'package:equatable/equatable.dart';

class RefuelEntry extends Equatable {
  const RefuelEntry({
    required this.id,
    required this.vehicleId,
    required this.filledAt,
    required this.odometer,
    required this.quantity,
    required this.pricePaid,
    this.fullTank = true,
    this.variantId,
    this.variantOther,
    this.stationName,
    this.notes,
    this.odometerOverride = false,
  });

  final int id;
  final int vehicleId;
  final DateTime filledAt;
  final double odometer;
  final double quantity;
  final double pricePaid;
  final bool fullTank;
  final String? variantId;
  final String? variantOther;
  final String? stationName;
  final String? notes;
  final bool odometerOverride;

  RefuelEntry copyWith({
    int? id,
    int? vehicleId,
    DateTime? filledAt,
    double? odometer,
    double? quantity,
    double? pricePaid,
    bool? fullTank,
    String? variantId,
    String? variantOther,
    String? stationName,
    String? notes,
    bool? odometerOverride,
  }) {
    return RefuelEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      filledAt: filledAt ?? this.filledAt,
      odometer: odometer ?? this.odometer,
      quantity: quantity ?? this.quantity,
      pricePaid: pricePaid ?? this.pricePaid,
      fullTank: fullTank ?? this.fullTank,
      variantId: variantId ?? this.variantId,
      variantOther: variantOther ?? this.variantOther,
      stationName: stationName ?? this.stationName,
      notes: notes ?? this.notes,
      odometerOverride: odometerOverride ?? this.odometerOverride,
    );
  }

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    filledAt,
    odometer,
    quantity,
    pricePaid,
    fullTank,
    variantId,
    variantOther,
    stationName,
    notes,
    odometerOverride,
  ];
}

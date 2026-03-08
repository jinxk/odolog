import 'package:equatable/equatable.dart';

class EntryDerived extends Equatable {
  const EntryDerived({required this.pricePerUnit, this.distanceSincePrevious});

  final double pricePerUnit;
  final double? distanceSincePrevious;

  @override
  List<Object?> get props => [pricePerUnit, distanceSincePrevious];
}

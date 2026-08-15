import 'package:equatable/equatable.dart';

/// One odometer reading recorded without a refuel, so the service countdown
/// and the cost per km stay current between fills.
class OdometerReading extends Equatable {
  const OdometerReading({
    required this.id,
    required this.vehicleId,
    required this.odometer,
    required this.recordedAt,
    this.note,
  });

  final int id;
  final int vehicleId;

  /// The reading itself, in km.
  final double odometer;

  final DateTime recordedAt;
  final String? note;

  OdometerReading copyWith({
    int? id,
    int? vehicleId,
    double? odometer,
    DateTime? recordedAt,
    String? note,
  }) {
    return OdometerReading(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      odometer: odometer ?? this.odometer,
      recordedAt: recordedAt ?? this.recordedAt,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [id, vehicleId, odometer, recordedAt, note];
}

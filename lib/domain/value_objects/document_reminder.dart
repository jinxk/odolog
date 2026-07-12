import 'package:equatable/equatable.dart';

import '../entities/vehicle.dart';

/// One notification that should fire ahead of a document expiry: a specific
/// vehicle's specific document, at a specific lead time. The planner produces
/// these from the vehicles' stored dates; the platform layer turns each into a
/// scheduled local notification.
class DocumentReminder extends Equatable {
  const DocumentReminder({
    required this.vehicleId,
    required this.vehicleName,
    required this.document,
    required this.expiry,
    required this.daysBefore,
    required this.fireAt,
  });

  /// The vehicle whose document expires. Carried so the notification body can
  /// name it ("Swift insurance expires in 7 days") without a second lookup.
  final int vehicleId;
  final String vehicleName;
  final VehicleDocument document;

  /// The date the document lapses.
  final DateTime expiry;

  /// Lead time in days: 30, 15, 7, or 1.
  final int daysBefore;

  /// Local wall-clock instant the reminder should fire, already offset back
  /// from [expiry] by [daysBefore] days. Always in the future relative to the
  /// clock the planner ran against, since past reminders are dropped.
  final DateTime fireAt;

  @override
  List<Object?> get props => [vehicleId, document, expiry, daysBefore, fireAt];
}

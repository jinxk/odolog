import 'package:equatable/equatable.dart';

import '../entities/service_log_entry.dart';

/// One notification that should fire when a maintenance template comes due:
/// a specific vehicle's specific template, at a specific moment. Mirrors
/// [DocumentReminder]'s shape so the same scheduler can carry both kinds.
class ServiceReminder extends Equatable {
  const ServiceReminder({
    required this.vehicleId,
    required this.vehicleName,
    required this.template,
    required this.fireAt,
  });

  final int vehicleId;
  final String vehicleName;
  final ServiceTemplate template;

  /// Local wall-clock instant the reminder should fire. Always in the future
  /// relative to the clock the planner ran against, since past reminders are
  /// dropped.
  final DateTime fireAt;

  @override
  List<Object?> get props => [vehicleId, template, fireAt];
}

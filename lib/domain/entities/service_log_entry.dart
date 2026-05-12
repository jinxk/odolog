import 'package:equatable/equatable.dart';

/// The two maintenance templates OdoLog tracks. Each has exactly one due
/// dimension by default: engine oil by distance, general service by time.
/// Adding a third template is out of scope; this enum is closed on purpose.
/// Display names live in presentation's formatting helpers, the same as the
/// vehicle document enum.
enum ServiceTemplate { engineOil, generalService }

/// One completed maintenance visit: which template it satisfies, when and at
/// what reading it happened, and what it cost. Logging an entry is what resets
/// that template's due countdown; the calculator always reads the most recent
/// entry per template as its new baseline.
class ServiceLogEntry extends Equatable {
  const ServiceLogEntry({
    required this.id,
    required this.vehicleId,
    required this.template,
    required this.performedAt,
    required this.odometer,
    this.cost,
    this.note,
  });

  final int id;
  final int vehicleId;
  final ServiceTemplate template;
  final DateTime performedAt;

  /// Odometer reading at the time of service, in km.
  final double odometer;

  /// What the visit cost, in the vehicle's currency. Null when not recorded.
  /// This is the only place a service's cost lives: it is folded into total
  /// cost of ownership directly and never duplicated into an [Expense] row.
  final double? cost;

  final String? note;

  ServiceLogEntry copyWith({
    int? id,
    int? vehicleId,
    ServiceTemplate? template,
    DateTime? performedAt,
    double? odometer,
    double? cost,
    String? note,
  }) {
    return ServiceLogEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      template: template ?? this.template,
      performedAt: performedAt ?? this.performedAt,
      odometer: odometer ?? this.odometer,
      cost: cost ?? this.cost,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
    id,
    vehicleId,
    template,
    performedAt,
    odometer,
    cost,
    note,
  ];
}

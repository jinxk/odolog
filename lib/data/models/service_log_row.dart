import '../../domain/entities/service_log_entry.dart';

/// Maps a [ServiceLogEntry] to and from a `service_log` table row. The
/// template is stored as its enum name, matching the convention every other
/// enum column in this schema uses. An entry with id 0 is unsaved, so its id
/// is omitted and SQLite assigns one.
class ServiceLogRow {
  const ServiceLogRow._();

  static const table = 'service_log';

  static Map<String, Object?> toMap(ServiceLogEntry entry) {
    return {
      if (entry.id != 0) 'id': entry.id,
      'vehicle_id': entry.vehicleId,
      'template': entry.template.name,
      'performed_at': entry.performedAt.millisecondsSinceEpoch,
      'odometer': entry.odometer,
      'cost': entry.cost,
      'note': entry.note,
    };
  }

  static ServiceLogEntry fromMap(Map<String, Object?> map) {
    return ServiceLogEntry(
      id: map['id']! as int,
      vehicleId: map['vehicle_id']! as int,
      template: ServiceTemplate.values.byName(map['template']! as String),
      performedAt: DateTime.fromMillisecondsSinceEpoch(
        map['performed_at']! as int,
      ),
      odometer: (map['odometer']! as num).toDouble(),
      cost: (map['cost'] as num?)?.toDouble(),
      note: map['note'] as String?,
    );
  }
}

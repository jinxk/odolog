import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/reminders/reminder_planning.dart';
import 'package:odolog/domain/usecases/get_scheduled_reminders.dart';
import 'package:odolog/domain/value_objects/scheduled_reminder.dart';

import '../../helpers/fake_odometer_reading_repository.dart';
import '../../helpers/fake_refuel_repository.dart';
import '../../helpers/fake_service_log_repository.dart';

final _now = DateTime.now();

/// An insurance date far enough out that all four lead times still lie in the
/// future, so the row count is stable whenever the test runs.
final _insuranceExpiry = _now.add(const Duration(days: 60));

/// A general service logged recently, so its 180 day interval projects a due
/// date well ahead of the insurance reminders.
final _servicedAt = _now.subtract(const Duration(days: 10));

final _activa = Vehicle(
  id: 1,
  name: 'Activa',
  type: VehicleType.scooter,
  fuelCategory: FuelCategory.petrol,
  insuranceExpiry: _insuranceExpiry,
);

const _swift = Vehicle(
  id: 2,
  name: 'Swift',
  type: VehicleType.car,
  fuelCategory: FuelCategory.petrol,
);

GetScheduledReminders _useCase() => GetScheduledReminders(
  ReminderPlanning(
    FakeRefuelRepository(),
    FakeServiceLogRepository([
      ServiceLogEntry(
        id: 1,
        vehicleId: _activa.id,
        template: ServiceTemplate.generalService,
        performedAt: _servicedAt,
        odometer: 5000,
      ),
    ]),
    FakeOdometerReadingRepository(),
  ),
);

void main() {
  test('lists both categories soonest first', () async {
    final rows = await _useCase().execute([_activa, _swift]);

    expect(rows.map((r) => r.title), [
      'Insurance expiry',
      'Insurance expiry',
      'Insurance expiry',
      'Insurance expiry',
      'General service',
    ]);
    expect(rows.every((r) => r.vehicleName == 'Activa'), isTrue);
    for (var i = 1; i < rows.length; i++) {
      expect(rows[i].fireAt.isBefore(rows[i - 1].fireAt), isFalse);
    }
  });

  test('a switched off category contributes nothing', () async {
    final documentsOnly = await _useCase().execute([_activa], services: false);
    final servicesOnly = await _useCase().execute([_activa], documents: false);

    expect(
      documentsOnly.every((r) => r.category == ReminderCategory.document),
      isTrue,
    );
    expect(servicesOnly.map((r) => r.category), [ReminderCategory.service]);
  });

  test('a vehicle with no dates and no history contributes nothing', () async {
    final rows = await _useCase().execute([_swift]);

    expect(rows, isEmpty);
  });
}

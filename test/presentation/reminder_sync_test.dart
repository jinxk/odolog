import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/providers/app_providers.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_odometer_reading_repository.dart';
import '../helpers/fake_refuel_repository.dart';
import '../helpers/fake_reminder_scheduler.dart';
import '../helpers/fake_service_log_repository.dart';
import '../helpers/fake_vehicle_repository.dart';

final _now = DateTime.now();

/// A vehicle with something in both categories to schedule, so an empty sync
/// can only mean the switch stopped it.
final _vehicle = Vehicle(
  id: 1,
  name: 'Activa',
  type: VehicleType.scooter,
  fuelCategory: FuelCategory.petrol,
  insuranceExpiry: _now.add(const Duration(days: 60)),
);

Future<FakeReminderScheduler> _runSync() async {
  final scheduler = FakeReminderScheduler();
  final container = ProviderContainer(
    overrides: [
      vehicleRepositoryProvider.overrideWithValue(
        FakeVehicleRepository([_vehicle]),
      ),
      refuelRepositoryProvider.overrideWithValue(FakeRefuelRepository()),
      serviceLogRepositoryProvider.overrideWithValue(
        FakeServiceLogRepository([
          ServiceLogEntry(
            id: 1,
            vehicleId: _vehicle.id,
            template: ServiceTemplate.generalService,
            performedAt: _now.subtract(const Duration(days: 10)),
            odometer: 5000,
          ),
        ]),
      ),
      odometerReadingRepositoryProvider.overrideWithValue(
        FakeOdometerReadingRepository(),
      ),
      reminderSchedulerProvider.overrideWithValue(scheduler),
    ],
  );
  addTearDown(container.dispose);
  container.read(documentReminderSyncProvider);
  container.read(serviceReminderSyncProvider);
  await container.read(vehicleListProvider.future);
  await container.read(settingsProvider.future);
  // The notifiers react to the resolved list and then await the preferences,
  // so a few turns of the loop are needed before the scheduler has been told.
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return scheduler;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a switched off category is synced empty and the other is not',
    () async {
      SharedPreferences.setMockInitialValues({});
      final on = await _runSync();
      expect(on.synced, isNotEmpty);
      expect(on.syncedServiceReminders, isNotEmpty);

      SharedPreferences.setMockInitialValues({
        'settings.documentReminders': false,
      });
      final off = await _runSync();
      expect(off.synced, isEmpty);
      expect(off.syncedServiceReminders, isNotEmpty);
    },
  );
}

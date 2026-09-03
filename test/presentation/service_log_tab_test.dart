import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/service/service_log_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/entry_builder.dart';
import '../helpers/fake_odometer_reading_repository.dart';
import '../helpers/fake_refuel_repository.dart';
import '../helpers/fake_reminder_scheduler.dart';
import '../helpers/fake_service_log_repository.dart';
import '../helpers/fake_vehicle_repository.dart';

const _vehicle = Vehicle(
  id: 1,
  name: 'Swift',
  type: VehicleType.car,
  fuelCategory: FuelCategory.petrol,
);

Future<FakeServiceLogRepository> pumpScreen(
  WidgetTester tester, {
  FakeReminderScheduler? scheduler,
}) async {
  final serviceLogRepo = FakeServiceLogRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          FakeVehicleRepository([_vehicle]),
        ),
        refuelRepositoryProvider.overrideWithValue(
          FakeRefuelRepository([
            entry(id: 1, odometer: 10000, quantity: 20, pricePaid: 2000),
          ]),
        ),
        serviceLogRepositoryProvider.overrideWithValue(serviceLogRepo),
        odometerReadingRepositoryProvider.overrideWithValue(
          FakeOdometerReadingRepository(),
        ),
        reminderSchedulerProvider.overrideWithValue(
          scheduler ?? FakeReminderScheduler(),
        ),
      ],
      child: const MaterialApp(home: ServiceLogTab()),
    ),
  );
  await tester.pumpAndSettle();
  return serviceLogRepo;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('logging a service writes the entry and shows it in history', (
    tester,
  ) async {
    final repo = await pumpScreen(tester);

    await tester.tap(find.text('Log service'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('serviceOdometerField')),
      '10500',
    );
    await tester.tap(find.byKey(const Key('saveServiceButton')));
    await tester.pumpAndSettle();

    expect(repo.entries, hasLength(1));
    expect(repo.entries.single.odometer, 10500);
    expect(find.text('No services logged yet.'), findsNothing);
  });

  testWidgets('a zero odometer is rejected inline', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Log service'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('serviceOdometerField')), '0');
    await tester.tap(find.byKey(const Key('saveServiceButton')));
    await tester.pumpAndSettle();

    expect(find.text('Odometer must be greater than zero.'), findsOneWidget);
  });

  testWidgets('deleting a service entry at once offers undo', (tester) async {
    final repo = await pumpScreen(tester);

    await tester.tap(find.text('Log service'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('serviceOdometerField')),
      '10500',
    );
    await tester.tap(find.byKey(const Key('saveServiceButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete Engine oil'));
    await tester.pumpAndSettle();

    expect(repo.entries, isEmpty);
    expect(find.text('No services logged yet.'), findsOneWidget);
    expect(find.text('Service deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(repo.entries, hasLength(1));
    expect(repo.entries.single.odometer, 10500);
    expect(find.text('No services logged yet.'), findsNothing);
  });

  testWidgets('the first logged service requests notification permission', (
    tester,
  ) async {
    final scheduler = FakeReminderScheduler();
    await pumpScreen(tester, scheduler: scheduler);

    await tester.tap(find.text('Log service'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('serviceOdometerField')),
      '10500',
    );
    await tester.tap(find.byKey(const Key('saveServiceButton')));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequested, isTrue);
  });

  testWidgets('the due card counts down from the last service odometer', (
    tester,
  ) async {
    await pumpScreen(tester);

    // No service logged yet, so the countdown runs from the first fill at
    // 10000 over the 3000 km default interval.
    expect(find.text('Engine oil due in about 3000 km'), findsOneWidget);

    await tester.tap(find.text('Log service'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('serviceOdometerField')),
      '10500',
    );
    await tester.tap(find.byKey(const Key('saveServiceButton')));
    await tester.pumpAndSettle();

    // Logging a service moves the baseline to its odometer, so the interval
    // restarts from 10500 while the latest reading is still 10000.
    expect(find.text('Engine oil due in about 3500 km'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/history/history_screen.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/entry_builder.dart';
import '../helpers/fake_expense_repository.dart';
import '../helpers/fake_odometer_reading_repository.dart';
import '../helpers/fake_refuel_repository.dart';
import '../helpers/fake_service_log_repository.dart';
import '../helpers/fake_vehicle_repository.dart';

const _vehicle = Vehicle(
  id: 1,
  name: 'Swift',
  type: VehicleType.car,
  fuelCategory: FuelCategory.petrol,
);

final _now = DateTime.now();
final _lastWeek = _now.subtract(const Duration(days: 7));

Future<FakeOdometerReadingRepository> pumpHistory(
  WidgetTester tester, {
  required List<OdometerReading> readings,
}) async {
  final readingRepo = FakeOdometerReadingRepository(readings);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          FakeVehicleRepository([_vehicle]),
        ),
        refuelRepositoryProvider.overrideWithValue(
          FakeRefuelRepository([
            entry(
              id: 1,
              odometer: 10000,
              quantity: 30,
              pricePaid: 3000,
              filledAt: _lastWeek,
            ),
          ]),
        ),
        serviceLogRepositoryProvider.overrideWithValue(
          FakeServiceLogRepository(),
        ),
        expenseRepositoryProvider.overrideWithValue(FakeExpenseRepository()),
        odometerReadingRepositoryProvider.overrideWithValue(readingRepo),
      ],
      child: const MaterialApp(home: HistoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return readingRepo;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a reading shows as its own row in the timeline', (tester) async {
    await pumpHistory(
      tester,
      readings: [
        OdometerReading(
          id: 1,
          vehicleId: 1,
          odometer: 10400,
          recordedAt: _now,
          note: 'Before the service booking',
        ),
      ],
    );

    expect(find.text('Odometer update'), findsOneWidget);
    expect(find.byIcon(Icons.speed), findsOneWidget);
    expect(find.textContaining('10,400 km'), findsOneWidget);
    expect(find.textContaining('Before the service booking'), findsOneWidget);
  });

  testWidgets('a long press deletes the reading after confirmation', (
    tester,
  ) async {
    final readingRepo = await pumpHistory(
      tester,
      readings: [
        OdometerReading(id: 1, vehicleId: 1, odometer: 10400, recordedAt: _now),
      ],
    );

    await tester.longPress(find.text('Odometer update'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this reading?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(readingRepo.readings, isEmpty);
    expect(find.text('Odometer update'), findsNothing);
  });

  testWidgets('cancelling the confirmation keeps the reading', (tester) async {
    final readingRepo = await pumpHistory(
      tester,
      readings: [
        OdometerReading(id: 1, vehicleId: 1, odometer: 10400, recordedAt: _now),
      ],
    );

    await tester.longPress(find.text('Odometer update'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(readingRepo.readings, hasLength(1));
    expect(find.text('Odometer update'), findsOneWidget);
  });
}

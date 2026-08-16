import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/odometer/odometer_sheet.dart';
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

/// Pumps a screen whose only action opens the sheet, so a test walks the same
/// path the dashboard button does, snack bar included.
Future<FakeOdometerReadingRepository> pumpSheet(
  WidgetTester tester, {
  List<RefuelEntry> fills = const [],
}) async {
  final readingRepo = FakeOdometerReadingRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          FakeVehicleRepository([_vehicle]),
        ),
        refuelRepositoryProvider.overrideWithValue(FakeRefuelRepository(fills)),
        serviceLogRepositoryProvider.overrideWithValue(
          FakeServiceLogRepository(),
        ),
        expenseRepositoryProvider.overrideWithValue(FakeExpenseRepository()),
        odometerReadingRepositoryProvider.overrideWithValue(readingRepo),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showOdometerSheet(context, ref, _vehicle),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return readingRepo;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a valid save stores the reading and confirms it', (
    tester,
  ) async {
    final readingRepo = await pumpSheet(tester);

    await tester.enterText(
      find.byKey(const Key('odometerReadingField')),
      '10400',
    );
    await tester.tap(find.byKey(const Key('saveOdometerButton')));
    await tester.pumpAndSettle();

    expect(readingRepo.readings.single.odometer, 10400);
    expect(find.byKey(const Key('odometerReadingField')), findsNothing);
    expect(find.text('Odometer updated'), findsOneWidget);
  });

  testWidgets('the last known reading shows under the odometer field', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      fills: [
        entry(
          id: 1,
          odometer: 45210,
          quantity: 30,
          pricePaid: 3000,
          filledAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ],
    );

    expect(find.text('Last reading 45,210 km'), findsOneWidget);
  });

  testWidgets('a reading below the last fill reports on the odometer field', (
    tester,
  ) async {
    final readingRepo = await pumpSheet(
      tester,
      fills: [
        entry(
          id: 1,
          odometer: 10000,
          quantity: 30,
          pricePaid: 3000,
          filledAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ],
    );

    await tester.enterText(
      find.byKey(const Key('odometerReadingField')),
      '9000',
    );
    await tester.tap(find.byKey(const Key('saveOdometerButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Odometer must be greater than the previous reading.'),
      findsOneWidget,
    );
    expect(readingRepo.readings, isEmpty);
    expect(find.text('Odometer updated'), findsNothing);
  });

  testWidgets('an empty odometer field asks for a reading', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.byKey(const Key('saveOdometerButton')));
    await tester.pumpAndSettle();

    expect(find.text('Enter the odometer reading.'), findsOneWidget);
  });
}

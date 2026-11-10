import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/history/history_screen.dart';
import 'package:odolog/presentation/providers/app_providers.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/stats/stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/entry_builder.dart';
import '../helpers/fake_catalog_repository.dart';
import '../helpers/fake_expense_repository.dart';
import '../helpers/fake_odometer_reading_repository.dart';
import '../helpers/fake_refuel_repository.dart';
import '../helpers/fake_service_log_repository.dart';
import '../helpers/fake_vehicle_repository.dart';

const _swift = Vehicle(
  id: 1,
  name: 'Swift',
  type: VehicleType.car,
  fuelCategory: FuelCategory.petrol,
);

const _activa = Vehicle(
  id: 2,
  name: 'Activa',
  type: VehicleType.scooter,
  fuelCategory: FuelCategory.petrol,
);

final _seed = [
  entry(id: 1, odometer: 10000, quantity: 30, pricePaid: 3000),
  entry(id: 2, odometer: 10250, quantity: 15, pricePaid: 1509, fullTank: false),
  entry(id: 3, odometer: 10600, quantity: 25, pricePaid: 2515),
  entry(id: 4, vehicleId: 2, odometer: 500, quantity: 4, pricePaid: 400),
];

/// The real database answers after a frame or two; with no delay a reload
/// would finish before its loading state ever painted.
Duration _dbDelay = Duration.zero;

class _SlowRefuelRepository extends FakeRefuelRepository {
  _SlowRefuelRepository(super.seed);

  @override
  Future<Result<List<RefuelEntry>>> getForVehicle(int vehicleId) async {
    await Future<void>.delayed(_dbDelay);
    return super.getForVehicle(vehicleId);
  }
}

class _SlowVehicleRepository extends FakeVehicleRepository {
  _SlowVehicleRepository(super.seed);

  @override
  Future<Result<List<Vehicle>>> getAll() async {
    await Future<void>.delayed(_dbDelay);
    return super.getAll();
  }
}

Future<_SlowRefuelRepository> _pump(WidgetTester tester, Widget screen) async {
  final refuels = _SlowRefuelRepository(_seed);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          _SlowVehicleRepository([_swift, _activa]),
        ),
        refuelRepositoryProvider.overrideWithValue(refuels),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        serviceLogRepositoryProvider.overrideWithValue(
          FakeServiceLogRepository(),
        ),
        expenseRepositoryProvider.overrideWithValue(FakeExpenseRepository()),
        odometerReadingRepositoryProvider.overrideWithValue(
          FakeOdometerReadingRepository(),
        ),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
  _dbDelay = const Duration(milliseconds: 100);
  addTearDown(() => _dbDelay = Duration.zero);
  return refuels;
}

ProviderContainer _container(WidgetTester tester, Type screen) =>
    ProviderScope.containerOf(tester.element(find.byType(screen)));

/// Saves a fill the way the add refuel screen does, then checks every frame
/// until the reload settles for a loading circle.
Future<void> _saveAndWatch(
  WidgetTester tester,
  _SlowRefuelRepository refuels,
  Type screen,
) async {
  await refuels.add(
    entry(id: 5, odometer: 10900, quantity: 15, pricePaid: 1500),
  );
  final container = _container(tester, screen);
  container.invalidate(vehicleStatsProvider(1));
  container.invalidate(historyProvider(1));
  container.invalidate(vehicleListProvider);

  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 25));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('history keeps its list on screen while a save reloads', (
    tester,
  ) async {
    final refuels = await _pump(tester, const HistoryScreen());

    await _saveAndWatch(tester, refuels, HistoryScreen);

    expect(find.textContaining('1,500.00'), findsOneWidget);
  });

  testWidgets('stats keep every section on screen while a save reloads', (
    tester,
  ) async {
    final refuels = await _pump(tester, const StatsScreen());

    await _saveAndWatch(tester, refuels, StatsScreen);
  });

  testWidgets('stats still show loading when the vehicle changes', (
    tester,
  ) async {
    await _pump(tester, const StatsScreen());

    _container(
      tester,
      StatsScreen,
    ).read(activeVehicleIdProvider.notifier).select(2);
    await tester.pump(const Duration(milliseconds: 25));

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pumpAndSettle();
  });
}

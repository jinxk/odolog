import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/entities/odometer_reading.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/common/motion.dart';
import 'package:odolog/presentation/home/home_screen.dart';
import 'package:odolog/presentation/providers/app_providers.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/entry_builder.dart';
import '../helpers/fake_catalog_repository.dart';
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
  tankCapacity: 35,
);

// The worked example from docs/design.md, so the documented numbers and the
// dashboard cannot drift apart.
final _workedExample = [
  entry(id: 1, odometer: 10000, quantity: 30, pricePaid: 3000),
  entry(id: 2, odometer: 10250, quantity: 15, pricePaid: 1509, fullTank: false),
  entry(id: 3, odometer: 10600, quantity: 25, pricePaid: 2515),
];

/// How long the slow fakes below take to answer. The real database answers
/// after a frame or two; with no delay a reload would finish before its loading
/// state ever painted.
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

Future<void> pumpHome(
  WidgetTester tester, {
  List<RefuelEntry> seed = const [],
  Vehicle vehicle = _vehicle,
  List<Vehicle> fleet = const [],
  List<OdometerReading> readings = const [],
  FakeRefuelRepository? refuels,
  FakeVehicleRepository? vehicles,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          vehicles ?? FakeVehicleRepository(fleet.isEmpty ? [vehicle] : fleet),
        ),
        refuelRepositoryProvider.overrideWithValue(
          refuels ?? FakeRefuelRepository(seed),
        ),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        serviceLogRepositoryProvider.overrideWithValue(
          FakeServiceLogRepository(),
        ),
        expenseRepositoryProvider.overrideWithValue(FakeExpenseRepository()),
        odometerReadingRepositoryProvider.overrideWithValue(
          FakeOdometerReadingRepository(readings),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the first fill empty state before any entry', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.textContaining('Add your first refuel'), findsOneWidget);
  });

  testWidgets('asks for one more full tank after a single fill', (
    tester,
  ) async {
    await pumpHome(
      tester,
      seed: [entry(id: 1, odometer: 10000, quantity: 30, pricePaid: 3000)],
    );

    expect(find.textContaining('Log one more full tank'), findsOneWidget);
  });

  testWidgets('sets the real average against the claimed figure on the hero', (
    tester,
  ) async {
    // The worked example gives a 15.0 km/l real average; claimed is 20, so the
    // line reads 15.0 real vs 20.0 claimed (75%).
    await pumpHome(
      tester,
      seed: _workedExample,
      vehicle: const Vehicle(
        id: 1,
        name: 'Swift',
        type: VehicleType.car,
        fuelCategory: FuelCategory.petrol,
        tankCapacity: 35,
        claimedMileage: 20,
      ),
    );

    expect(find.text('15.0 real vs 20.0 claimed (75%)'), findsOneWidget);
  });

  testWidgets('the hero label speaks a change only when it rounds above 0.0', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    // The last window runs 15.075 km/l against a 15.038 average: a real but
    // sub-0.05 gap that shows as 0.0.
    await pumpHome(
      tester,
      seed: [
        entry(id: 1, odometer: 10000, quantity: 30, pricePaid: 3000),
        entry(id: 2, odometer: 10300, quantity: 20, pricePaid: 2000),
        entry(id: 3, odometer: 10600, quantity: 19.9, pricePaid: 1990),
      ],
    );

    expect(
      find.bySemanticsLabel('Mileage 15.1 km/l over your last full tank'),
      findsOneWidget,
    );

    // 15.152 km/l against a 15.075 average is a 0.077 gap, which shows as 0.1.
    await tester.pumpWidget(const SizedBox());
    await pumpHome(
      tester,
      seed: [
        entry(id: 1, odometer: 10000, quantity: 30, pricePaid: 3000),
        entry(id: 2, odometer: 10300, quantity: 20, pricePaid: 2000),
        entry(id: 3, odometer: 10600, quantity: 19.8, pricePaid: 1980),
      ],
    );

    expect(
      find.bySemanticsLabel(
        'Mileage 15.2 km/l over your last full tank, up 0.1 against your '
        'average',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the title names the switch action when there is a fleet', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHome(
      tester,
      seed: _workedExample,
      fleet: const [
        _vehicle,
        Vehicle(
          id: 2,
          name: 'Activa',
          type: VehicleType.scooter,
          fuelCategory: FuelCategory.petrol,
        ),
      ],
    );

    final data = tester.getSemantics(find.text('Swift'));
    expect(data.hint, 'Switch vehicle');
    handle.dispose();
  });

  testWidgets('surfaces the nearest document expiry within thirty days', (
    tester,
  ) async {
    final pucExpiry = DateTime.now().add(const Duration(days: 5));
    await pumpHome(
      tester,
      seed: _workedExample,
      vehicle: Vehicle(
        id: 1,
        name: 'Swift',
        type: VehicleType.car,
        fuelCategory: FuelCategory.petrol,
        pucExpiry: pucExpiry,
      ),
    );

    expect(find.textContaining('PUC expires in 5 days'), findsOneWidget);
  });

  testWidgets('both primary actions fit a 360 dp wide screen', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpHome(tester, seed: _workedExample);

    expect(find.text('Add refuel'), findsOneWidget);
    expect(find.text('Update odometer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the odometer action opens the update sheet', (tester) async {
    await pumpHome(tester, seed: _workedExample);

    await tester.tap(find.text('Update odometer'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('odometerReadingField')), findsOneWidget);
  });

  testWidgets('a reading leaves the hero window figures alone', (tester) async {
    await pumpHome(
      tester,
      seed: _workedExample,
      readings: [
        OdometerReading(
          id: 1,
          vehicleId: 1,
          odometer: 11000,
          recordedAt: DateTime.now(),
        ),
      ],
    );

    // Mileage and the hero cost per km are measured over closed full tank
    // windows, which a reading with no fuel behind it cannot change.
    expect(find.text('15.0'), findsOneWidget);
    expect(find.textContaining('6.71'), findsOneWidget);
  });

  testWidgets('hero figures move from the old value to the new one after a '
      'save, never back through zero', (tester) async {
    final refuels = _SlowRefuelRepository(_workedExample);
    await pumpHome(
      tester,
      refuels: refuels,
      vehicles: _SlowVehicleRepository([_vehicle]),
    );
    _dbDelay = const Duration(milliseconds: 100);
    addTearDown(() => _dbDelay = Duration.zero);

    // NaN when the figures are not on screen, which fails the range check.
    double shown(int index) {
      if (find.byType(CountUpText).evaluate().isEmpty) return double.nan;
      final text = find.descendant(
        of: find.byType(CountUpText).at(index),
        matching: find.byType(Text),
      );
      final raw = tester.widget<Text>(text).data!;
      return double.parse(RegExp(r'[\d.]+').firstMatch(raw)!.group(0)!);
    }

    final before = [shown(0), shown(1)];

    // The same invalidations a saved refuel makes.
    await refuels.add(
      entry(id: 4, odometer: 10900, quantity: 15, pricePaid: 1500),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    container.invalidate(vehicleStatsProvider(1));
    container.invalidate(historyProvider(1));
    container.invalidate(vehicleListProvider);

    final samples = <List<double>>[];
    for (var i = 0; i < 16; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      samples.add([shown(0), shown(1)]);
    }
    await tester.pumpAndSettle();
    final after = [shown(0), shown(1)];

    for (var figure = 0; figure < 2; figure++) {
      expect(after[figure], isNot(before[figure]));
      final low = before[figure] < after[figure]
          ? before[figure]
          : after[figure];
      final high = before[figure] < after[figure]
          ? after[figure]
          : before[figure];
      for (final sample in samples) {
        expect(sample[figure], inInclusiveRange(low - 0.05, high + 0.05));
      }
    }
  });
}

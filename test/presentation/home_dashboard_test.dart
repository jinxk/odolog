import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/home/home_screen.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/entry_builder.dart';
import '../helpers/fake_catalog_repository.dart';
import '../helpers/fake_expense_repository.dart';
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

Future<void> pumpHome(
  WidgetTester tester, {
  List<RefuelEntry> seed = const [],
  Vehicle vehicle = _vehicle,
  List<Vehicle> fleet = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          FakeVehicleRepository(fleet.isEmpty ? [vehicle] : fleet),
        ),
        refuelRepositoryProvider.overrideWithValue(FakeRefuelRepository(seed)),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        serviceLogRepositoryProvider.overrideWithValue(
          FakeServiceLogRepository(),
        ),
        expenseRepositoryProvider.overrideWithValue(FakeExpenseRepository()),
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

  testWidgets('shows the worked example numbers once the window closes', (
    tester,
  ) async {
    await pumpHome(tester, seed: _workedExample);

    expect(find.text('15.0'), findsOneWidget);
    expect(find.text('km/l'), findsOneWidget);
    expect(find.textContaining('6.71'), findsOneWidget);
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

  testWidgets('reads the hero mileage as one labelled figure', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpHome(tester, seed: _workedExample);

    expect(
      find.bySemanticsLabel(
        'Mileage 15.0 km/l over your last full tank window',
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
}

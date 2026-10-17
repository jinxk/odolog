import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/vehicles/vehicles_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_vehicle_repository.dart';

const _pulsar = Vehicle(
  id: 1,
  name: 'Pulsar 125',
  type: VehicleType.motorcycle,
  fuelCategory: FuelCategory.petrol,
);

Future<void> pumpScreen(
  WidgetTester tester, {
  List<Vehicle> vehicles = const [_pulsar],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          FakeVehicleRepository(vehicles),
        ),
      ],
      child: const MaterialApp(home: VehiclesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('each row names its edit and delete controls by vehicle', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byTooltip('Edit Pulsar 125'), findsOneWidget);
    expect(find.byTooltip('Delete Pulsar 125'), findsOneWidget);
  });

  testWidgets('two-wheelers get the two-wheeler icon, the rest the car icon', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      vehicles: const [
        _pulsar,
        Vehicle(
          id: 2,
          name: 'Activa',
          type: VehicleType.scooter,
          fuelCategory: FuelCategory.petrol,
        ),
        Vehicle(
          id: 3,
          name: 'Swift',
          type: VehicleType.car,
          fuelCategory: FuelCategory.petrol,
        ),
      ],
    );

    Finder iconIn(String name) => find.descendant(
      of: find.widgetWithText(ListTile, name),
      matching: find.byType(Icon),
    );
    Icon leading(String name) => tester.widget<Icon>(iconIn(name).first);

    expect(leading('Pulsar 125').icon, Icons.two_wheeler);
    expect(leading('Activa').icon, Icons.two_wheeler);
    expect(leading('Swift').icon, Icons.directions_car);
  });
}

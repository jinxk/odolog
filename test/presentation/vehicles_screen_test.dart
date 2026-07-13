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

Future<void> pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          FakeVehicleRepository([_pulsar]),
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
}

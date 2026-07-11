import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/vehicles/vehicle_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_vehicle_repository.dart';

Future<Vehicle?> pumpVehicleForm(WidgetTester tester) async {
  Vehicle? saved;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(FakeVehicleRepository()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: VehicleForm(
            saveLabel: 'Save',
            onSaved: (value) => saved = value,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return saved;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a missing name blocks saving and reports on the name field', (
    tester,
  ) async {
    await pumpVehicleForm(tester);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Name is required.'), findsOneWidget);
  });

  testWidgets('a name alone saves, registration and tank are optional', (
    tester,
  ) async {
    final repo = FakeVehicleRepository();
    Vehicle? saved;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [vehicleRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: VehicleForm(
              saveLabel: 'Save',
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Activa');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.name, 'Activa');
    expect(repo.vehicles, hasLength(1));
  });

  testWidgets('the fuel category drives the tank capacity unit label', (
    tester,
  ) async {
    await pumpVehicleForm(tester);

    await tester.tap(find.text('More details'));
    await tester.pumpAndSettle();

    // Petrol measures in litres.
    expect(find.text('L'), findsOneWidget);

    await tester.tap(find.text('CNG'));
    await tester.pumpAndSettle();

    // CNG switches the unit to kg.
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('L'), findsNothing);
  });
}

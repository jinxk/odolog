import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/vehicles/vehicle_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_reminder_scheduler.dart';
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

  testWidgets('a double quote typed into the name field does not appear', (
    tester,
  ) async {
    await pumpVehicleForm(tester);

    await tester.enterText(find.byType(TextField).first, 'My "Activa"');
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, 'My Activa');
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

  testWidgets('the claimed mileage field carries the category mileage unit', (
    tester,
  ) async {
    await pumpVehicleForm(tester);

    await tester.tap(find.text('More details'));
    await tester.pumpAndSettle();

    expect(find.text('Company claimed mileage'), findsOneWidget);
    // Petrol reads in km/l; the tank field's own 'L' suffix is a different
    // string, so this matches only the mileage field.
    expect(find.text('km/l'), findsOneWidget);
  });

  testWidgets('a registration failure reports on the registration field', (
    tester,
  ) async {
    const initial = Vehicle(
      id: 1,
      name: 'Activa',
      type: VehicleType.scooter,
      fuelCategory: FuelCategory.petrol,
      registrationNo: 'MH12 "AB" 1234',
    );
    // An edit opens the "More details" section, so the form is taller than the
    // default test surface; give it room rather than scrolling twice.
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleRepositoryProvider.overrideWithValue(
            FakeVehicleRepository([initial]),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: VehicleForm(
              initial: initial,
              saveLabel: 'Save',
              onSaved: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    const reason = 'Cannot contain a quote mark or a line break.';
    final registration = tester.widget<TextField>(
      find.ancestor(
        of: find.text('Registration number'),
        matching: find.byType(TextField),
      ),
    );
    expect(registration.decoration!.errorText, reason);

    final name = tester.widget<TextField>(find.byType(TextField).first);
    expect(name.decoration!.errorText, isNull);
  });

  testWidgets(
    'a zero tank capacity reports on the tank capacity field and reopens '
    'the collapsed More details section',
    (tester) async {
      await pumpVehicleForm(tester);

      await tester.enterText(find.byType(TextField).first, 'Activa');
      await tester.tap(find.text('More details'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.ancestor(
          of: find.text('Tank capacity'),
          matching: find.byType(TextField),
        ),
        '0',
      );
      // Collapse the section again before saving, so the test exercises the
      // mechanism that reopens it to show the error rather than the error
      // simply being visible because the section was left open.
      await tester.tap(find.text('More details'));
      await tester.pumpAndSettle();
      expect(find.text('Tank capacity'), findsNothing);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Tank capacity'), findsOneWidget);
      expect(
        find.text('Tank capacity must be greater than zero.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a positive tank capacity saves without error', (tester) async {
    final repo = FakeVehicleRepository();
    Vehicle? saved;
    // An open "More details" section is taller than the default test surface,
    // so give it room rather than scrolling to find Save.
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    await tester.tap(find.text('More details'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.ancestor(
        of: find.text('Tank capacity'),
        matching: find.byType(TextField),
      ),
      '35',
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.tankCapacity, 35);
  });

  testWidgets('a document quick-set fills a date without auto-filling others', (
    tester,
  ) async {
    await pumpVehicleForm(tester);

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    // Every document starts unset.
    expect(find.text('Not set'), findsNWidgets(VehicleDocument.values.length));

    // Insurance offers a one year quick-set; tapping it sets only that row.
    await tester.tap(find.text('+1 yr'));
    await tester.pumpAndSettle();

    expect(
      find.text('Not set'),
      findsNWidgets(VehicleDocument.values.length - 1),
    );
    // The set row gains a clear button; no other row does.
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets(
    'saving with a document expiry date requests notification permission',
    (tester) async {
      // The expanded Documents section is taller than the default test
      // surface, so give it room rather than scrolling to find Save.
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final scheduler = FakeReminderScheduler();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleRepositoryProvider.overrideWithValue(
              FakeVehicleRepository(),
            ),
            reminderSchedulerProvider.overrideWithValue(scheduler),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VehicleForm(saveLabel: 'Save', onSaved: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Activa');
      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+1 yr'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(scheduler.permissionRequested, isTrue);
    },
  );

  testWidgets(
    'saving without a document expiry date does not request notification '
    'permission',
    (tester) async {
      final scheduler = FakeReminderScheduler();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleRepositoryProvider.overrideWithValue(
              FakeVehicleRepository(),
            ),
            reminderSchedulerProvider.overrideWithValue(scheduler),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: VehicleForm(saveLabel: 'Save', onSaved: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Activa');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(scheduler.permissionRequested, isFalse);
    },
  );
}

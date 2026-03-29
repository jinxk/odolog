import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/add_refuel/add_refuel_screen.dart';
import 'package:odolog/presentation/providers/refuel_form_provider.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/entry_builder.dart';
import '../helpers/fake_catalog_repository.dart';
import '../helpers/fake_refuel_repository.dart';
import '../helpers/fake_vehicle_repository.dart';

const _vehicle = Vehicle(
  id: 1,
  name: 'Swift',
  type: VehicleType.car,
  fuelCategory: FuelCategory.petrol,
);

Future<FakeRefuelRepository> pumpForm(
  WidgetTester tester, {
  List<RefuelEntry> seed = const [],
}) async {
  final refuelRepo = FakeRefuelRepository(seed);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('home'))),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const AddRefuelScreen(vehicle: _vehicle),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          FakeVehicleRepository([_vehicle]),
        ),
        refuelRepositoryProvider.overrideWithValue(refuelRepo),
        catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  unawaited(router.push('/add'));
  await tester.pumpAndSettle();
  return refuelRepo;
}

RefuelForm _controller(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(AddRefuelScreen)),
  );
  return container.read(refuelFormProvider('add:1').notifier);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'the three numeric fields are ordered odometer, quantity, price',
    (tester) async {
      await pumpForm(tester);

      final odometerY = tester
          .getTopLeft(find.byKey(const Key('odometerField')))
          .dy;
      final quantityY = tester
          .getTopLeft(find.byKey(const Key('quantityField')))
          .dy;
      final priceY = tester.getTopLeft(find.byKey(const Key('priceField'))).dy;

      expect(odometerY, lessThan(quantityY));
      expect(quantityY, lessThan(priceY));
    },
  );

  testWidgets('the price per unit hint updates as you type', (tester) async {
    await pumpForm(tester);

    await tester.enterText(find.byKey(const Key('quantityField')), '15');
    await tester.enterText(find.byKey(const Key('priceField')), '1509');
    await tester.pump();

    expect(find.textContaining('100.60'), findsOneWidget);
  });

  testWidgets('the optional section is collapsed by default', (tester) async {
    await pumpForm(tester);

    expect(find.text('Optional details'), findsOneWidget);
    expect(find.byKey(const Key('fullTankToggle')), findsNothing);
  });

  testWidgets('the full tank toggle defaults on', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Optional details'));
    await tester.pumpAndSettle();

    final toggle = tester.widget<SwitchListTile>(
      find.byKey(const Key('fullTankToggle')),
    );
    expect(toggle.value, isTrue);
  });

  testWidgets('a zero quantity is rejected on the quantity field', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(find.byKey(const Key('odometerField')), '100');
    await tester.enterText(find.byKey(const Key('quantityField')), '0');
    await tester.enterText(find.byKey(const Key('priceField')), '500');
    await tester.tap(find.text('Save refuel'));
    await tester.pumpAndSettle();

    expect(find.text('Quantity must be greater than zero.'), findsOneWidget);
  });

  testWidgets('a future date is rejected on the date field', (tester) async {
    await pumpForm(tester);

    final controller = _controller(tester);
    controller.setOdometer('100');
    controller.setQuantity('10');
    controller.setPrice('500');
    controller.setFilledAt(DateTime.now().add(const Duration(days: 2)));
    await tester.pump();

    await tester.tap(find.text('Save refuel'));
    await tester.pumpAndSettle();

    expect(find.text('Date cannot be in the future.'), findsOneWidget);
  });

  testWidgets('a non increasing odometer offers the override checkbox inline', (
    tester,
  ) async {
    await pumpForm(
      tester,
      seed: [entry(id: 1, odometer: 1000, quantity: 20, pricePaid: 2000)],
    );

    expect(find.byKey(const Key('overrideCheckbox')), findsNothing);

    await tester.enterText(find.byKey(const Key('odometerField')), '500');
    await tester.enterText(find.byKey(const Key('quantityField')), '10');
    await tester.enterText(find.byKey(const Key('priceField')), '500');
    await tester.tap(find.text('Save refuel'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('overrideCheckbox')), findsOneWidget);
  });

  testWidgets('a valid save writes the entry through the use case', (
    tester,
  ) async {
    final refuelRepo = await pumpForm(tester);

    await tester.enterText(find.byKey(const Key('odometerField')), '12000');
    await tester.enterText(find.byKey(const Key('quantityField')), '20');
    await tester.enterText(find.byKey(const Key('priceField')), '2000');
    await tester.tap(find.text('Save refuel'));
    await tester.pumpAndSettle();

    expect(refuelRepo.entries, hasLength(1));
    expect(refuelRepo.entries.single.odometer, 12000);
    expect(find.text('home'), findsOneWidget);
  });
}

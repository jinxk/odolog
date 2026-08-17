import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/entry_detail/entry_detail_screen.dart';
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

Future<FakeRefuelRepository> pumpEntryDetail(WidgetTester tester) async {
  final refuelRepo = FakeRefuelRepository([
    entry(id: 1, odometer: 10000, quantity: 20, pricePaid: 2000),
  ]);
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('home'))),
      ),
      GoRoute(
        path: '/entry',
        builder: (context, state) =>
            const EntryDetailScreen(entryId: 1, vehicle: _vehicle),
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
  unawaited(router.push('/entry'));
  await tester.pumpAndSettle();
  return refuelRepo;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('deleting a refuel at once offers undo and pops the screen', (
    tester,
  ) async {
    final repo = await pumpEntryDetail(tester);

    await tester.tap(find.byTooltip('Delete refuel'));
    await tester.pumpAndSettle();

    expect(repo.entries, isEmpty);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('Refuel deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('tapping undo brings the deleted refuel back', (tester) async {
    final repo = await pumpEntryDetail(tester);

    await tester.tap(find.byTooltip('Delete refuel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(repo.entries, hasLength(1));
    expect(repo.entries.single.id, 1);
    expect(repo.entries.single.odometer, 10000);
  });
}

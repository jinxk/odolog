import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/service/service_log_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/entry_builder.dart';
import '../helpers/fake_refuel_repository.dart';
import '../helpers/fake_service_log_repository.dart';
import '../helpers/fake_vehicle_repository.dart';

const _vehicle = Vehicle(
  id: 1,
  name: 'Swift',
  type: VehicleType.car,
  fuelCategory: FuelCategory.petrol,
);

Future<FakeServiceLogRepository> pumpScreen(WidgetTester tester) async {
  final serviceLogRepo = FakeServiceLogRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          FakeVehicleRepository([_vehicle]),
        ),
        refuelRepositoryProvider.overrideWithValue(
          FakeRefuelRepository([
            entry(id: 1, odometer: 10000, quantity: 20, pricePaid: 2000),
          ]),
        ),
        serviceLogRepositoryProvider.overrideWithValue(serviceLogRepo),
      ],
      child: const MaterialApp(home: ServiceLogTab()),
    ),
  );
  await tester.pumpAndSettle();
  return serviceLogRepo;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the due card shows a countdown for engine oil', (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('Engine oil'), findsWidgets);
  });

  testWidgets('logging a service writes the entry and shows it in history', (
    tester,
  ) async {
    final repo = await pumpScreen(tester);

    await tester.tap(find.text('Log service'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('serviceOdometerField')),
      '10500',
    );
    await tester.tap(find.byKey(const Key('saveServiceButton')));
    await tester.pumpAndSettle();

    expect(repo.entries, hasLength(1));
    expect(repo.entries.single.odometer, 10500);
    expect(find.text('No services logged yet.'), findsNothing);
  });

  testWidgets('a logged service row carries a labelled delete control', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Log service'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('serviceOdometerField')),
      '10500',
    );
    await tester.tap(find.byKey(const Key('saveServiceButton')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Delete Engine oil'), findsOneWidget);
  });

  testWidgets('a zero odometer is rejected inline', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Log service'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('serviceOdometerField')), '0');
    await tester.tap(find.byKey(const Key('saveServiceButton')));
    await tester.pumpAndSettle();

    expect(find.text('Odometer must be greater than zero.'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odolog/data/db/app_database.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/add_refuel/add_refuel_screen.dart';
import 'package:odolog/presentation/home/home_screen.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/stats/stats_screen.dart';
import 'package:odolog/presentation/vehicles/vehicle_form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// End to end regression against the real data layer: an in memory sqflite
/// database wired through the real repositories and use cases, driven through
/// the real form and dashboard widgets. The database provider is the only seam
/// the test overrides; everything downstream is production code. Each scenario
/// reuses one database across several widget trees, so a fill logged through the
/// add form is read back by a freshly pumped dashboard exactly as the app does.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    // The no isolate factory runs SQLite on the main isolate, so its futures
    // resolve on the microtask queue that pumpAndSettle drains. The default ffi
    // factory hops to a background isolate whose work never completes under the
    // widget tester's fake async.
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late Database db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await AppDatabase.open(path: inMemoryDatabasePath);
  });

  tearDown(() async {
    await db.close();
  });

  String plain(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  // Creates a vehicle by driving the real vehicle form to a save.
  Future<Vehicle> createVehicle(
    WidgetTester tester, {
    required String name,
    FuelCategory category = FuelCategory.petrol,
    double? tankCapacity,
  }) async {
    Vehicle? saved;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: VehicleForm(
              saveLabel: 'Add vehicle',
              onSaved: (value) => saved = value,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, name);
    if (category == FuelCategory.cng) {
      await tester.tap(find.text('CNG'));
      await tester.pumpAndSettle();
    }
    if (tankCapacity != null) {
      await tester.tap(find.text('More details'));
      await tester.pumpAndSettle();
      // After more details expands the fields read name, registration, tank.
      await tester.enterText(find.byType(TextField).at(2), plain(tankCapacity));
    }
    await tester.tap(find.text('Add vehicle'));
    await tester.pumpAndSettle();
    return saved!;
  }

  // Logs one fill by driving the real add refuel form. When [expectOrderError]
  // is set, the first save is expected to bounce on the odometer order rule and
  // the override checkbox path is taken to let the fill through.
  Future<void> logRefuel(
    WidgetTester tester, {
    required Vehicle vehicle,
    required String odometer,
    required String quantity,
    required String price,
    bool fullTank = true,
    bool expectOrderError = false,
    String? expectQuantityUnit,
  }) async {
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
          builder: (context, state) => AddRefuelScreen(vehicle: vehicle),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    unawaited(router.push('/add'));
    await tester.pumpAndSettle();

    if (expectQuantityUnit != null) {
      expect(find.text(expectQuantityUnit), findsOneWidget);
    }

    await tester.enterText(find.byKey(const Key('odometerField')), odometer);
    await tester.enterText(find.byKey(const Key('quantityField')), quantity);
    await tester.enterText(find.byKey(const Key('priceField')), price);
    await tester.pump();

    if (!fullTank) {
      // The full tank choice is always visible in the fast path now, so no
      // expander to open first.
      await tester.tap(find.text('Part fill'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Save refuel'));
    await tester.pumpAndSettle();

    if (expectOrderError) {
      expect(
        find.text('Odometer must be greater than the previous reading.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('overrideCheckbox')), findsOneWidget);
      await tester.tap(find.byKey(const Key('overrideCheckbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save refuel'));
      await tester.pumpAndSettle();
    }

    // Landing back on the placeholder home means the save committed.
    expect(find.text('home'), findsOneWidget);
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpStats(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The documented worked example: a petrol car with a 35 L tank and the three
  // fills from docs/design.md, logged through the real add form.
  Future<Vehicle> seedWorkedExample(WidgetTester tester) async {
    final vehicle = await createVehicle(
      tester,
      name: 'Swift',
      tankCapacity: 35,
    );
    await logRefuel(
      tester,
      vehicle: vehicle,
      odometer: '10000',
      quantity: '30',
      price: '3000',
    );
    await logRefuel(
      tester,
      vehicle: vehicle,
      odometer: '10250',
      quantity: '15',
      price: '1509',
      fullTank: false,
    );
    await logRefuel(
      tester,
      vehicle: vehicle,
      odometer: '10600',
      quantity: '25',
      price: '2515',
    );
    return vehicle;
  }

  testWidgets('scenario A: the worked example lands the documented numbers', (
    tester,
  ) async {
    await seedWorkedExample(tester);

    // The database holds exactly the three fills, in odometer order.
    final rows = await db.query('refuel_entries', orderBy: 'odometer');
    expect(rows, hasLength(3));
    expect(rows.map((r) => r['odometer']).toList(), [
      10000.0,
      10250.0,
      10600.0,
    ]);
    expect(rows.map((r) => r['quantity']).toList(), [30.0, 15.0, 25.0]);
    expect(rows.map((r) => r['price_paid']).toList(), [3000.0, 1509.0, 2515.0]);
    expect(rows.map((r) => r['full_tank']).toList(), [1, 0, 1]);

    // Home dashboard: mileage 15.0 km/l, cost per km Rs 6.71, last fill 350 km.
    await pumpHome(tester);
    expect(find.text('15.0'), findsOneWidget);
    expect(find.text('km/l'), findsOneWidget);
    expect(find.text('Rs 6.71'), findsOneWidget);
    expect(find.text('350 km'), findsOneWidget);

    // Stats: lifetime spend Rs 7024, total quantity 70 L, projected range
    // 525 km, average mileage 15.0 km/l, average cost per km Rs 6.71 /km.
    await pumpStats(tester);
    expect(find.text('Rs 7024.00'), findsWidgets);
    expect(find.text('70.00 L'), findsOneWidget);
    expect(find.text('525 km'), findsOneWidget);
    expect(find.text('15.0 km/l'), findsOneWidget);
    expect(find.text('Rs 6.71 /km'), findsOneWidget);
  });

  testWidgets(
    'scenario B: a lower odometer needs the override and recomputes cleanly',
    (tester) async {
      final vehicle = await seedWorkedExample(tester);

      // A partial fill read at 10500, below the last reading of 10600. The form
      // rejects it, then the override checkbox lets the correction through.
      await logRefuel(
        tester,
        vehicle: vehicle,
        odometer: '10500',
        quantity: '10',
        price: '1000',
        fullTank: false,
        expectOrderError: true,
      );

      // The override wrote a fourth row.
      final rows = await db.query('refuel_entries', orderBy: 'odometer');
      expect(rows, hasLength(4));
      expect(rows.map((r) => r['odometer']).toList(), [
        10000.0,
        10250.0,
        10500.0,
        10600.0,
      ]);

      // The window still opens at 10000 and closes at 10600 (distance 600), but
      // now carries the partial's 10 L: fuel 15 + 10 + 25 = 50 L, so mileage is
      // 600 / 50 = 12.0 km/l and cost per km is (1509 + 1000 + 2515) / 600 =
      // 5024 / 600 = 8.3733... which renders as Rs 8.37. No infinite or negative
      // figure, a finite recompute the hardened calculator produced.
      await pumpHome(tester);
      expect(find.text('12.0'), findsOneWidget);
      expect(find.text('km/l'), findsOneWidget);
      expect(find.text('Rs 8.37'), findsOneWidget);
    },
  );

  testWidgets('scenario C: a CNG vehicle logs in kg and reads km/kg', (
    tester,
  ) async {
    final vehicle = await createVehicle(
      tester,
      name: 'City CNG',
      category: FuelCategory.cng,
    );
    expect(vehicle.fuelCategory, FuelCategory.cng);

    // The quantity field announces kg, and two full fills close one window.
    await logRefuel(
      tester,
      vehicle: vehicle,
      odometer: '20000',
      quantity: '10',
      price: '900',
      expectQuantityUnit: 'kg',
    );
    await logRefuel(
      tester,
      vehicle: vehicle,
      odometer: '20400',
      quantity: '8',
      price: '720',
    );

    // Window fuel excludes the opening fill: 8 kg over 400 km is 50.0 km/kg, and
    // cost per km is 720 / 400 = 1.80.
    await pumpHome(tester);
    expect(find.text('50.0'), findsOneWidget);
    expect(find.text('km/kg'), findsOneWidget);
    expect(find.text('Rs 1.80'), findsOneWidget);
  });
}

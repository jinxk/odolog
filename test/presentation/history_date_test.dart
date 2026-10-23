import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/app/theme/theme.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/history/history_screen.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/entry_builder.dart';
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
);

Future<void> _loadInter() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await loader.load();
}

/// Two fills, so the newer one closes a window and shows the mileage column
/// when it is a full tank. The newer fill is dated 23 Oct 2026, one of the
/// wider dates.
Future<void> _pumpHistory(WidgetTester tester, {required bool fullTank}) async {
  await tester.binding.setSurfaceSize(const Size(360, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          FakeVehicleRepository([_vehicle]),
        ),
        refuelRepositoryProvider.overrideWithValue(
          FakeRefuelRepository([
            entry(
              id: 1,
              odometer: 10000,
              quantity: 30,
              pricePaid: 3000,
              filledAt: DateTime(2026, 9, 1),
            ),
            entry(
              id: 2,
              odometer: 10400,
              quantity: 20,
              pricePaid: 2000,
              fullTank: fullTank,
              filledAt: DateTime(2026, 10, 23),
            ),
          ]),
        ),
        serviceLogRepositoryProvider.overrideWithValue(
          FakeServiceLogRepository(),
        ),
        expenseRepositoryProvider.overrideWithValue(FakeExpenseRepository()),
        odometerReadingRepositoryProvider.overrideWithValue(
          FakeOdometerReadingRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const HistoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(_loadInter);

  testWidgets(
    'the date stays clear of the mileage figure at 360 dp, scale 2.0',
    (tester) async {
      await _pumpHistory(tester, fullTank: true);

      expect(tester.takeException(), isNull);
      final date = tester.getRect(find.text('23 Oct 2026'));
      final mileage = tester.getRect(find.text('20.0'));
      expect(date.right, lessThanOrEqualTo(mileage.left));
    },
  );

  testWidgets('the date and the Partial pill stay inside the row at 360 dp, '
      'scale 2.0', (tester) async {
    await _pumpHistory(tester, fullTank: false);

    expect(tester.takeException(), isNull);
    final date = tester.getRect(find.text('23 Oct 2026'));
    final pill = tester.getRect(find.text('Partial'));
    final chevron = tester.getRect(find.byIcon(Icons.chevron_right).first);
    expect(date.right, lessThanOrEqualTo(chevron.left));
    expect(pill.right, lessThanOrEqualTo(chevron.left));
  });
}

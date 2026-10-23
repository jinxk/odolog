import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

Future<void> _pumpHistory(
  WidgetTester tester, {
  required double width,
  required double scale,
  required double price,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final now = DateTime.now();
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
              filledAt: now.subtract(const Duration(days: 20)),
            ),
            entry(
              id: 2,
              odometer: 10400,
              quantity: 20,
              pricePaid: price,
              filledAt: now.subtract(const Duration(days: 2)),
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
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const HistoryScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The history date overflows at 360 dp and scale 2.0, which is a separate
/// defect. Any other exception still fails the test.
void _drainDateOverflow(WidgetTester tester) {
  Object? error;
  while ((error = tester.takeException()) != null) {
    expect(error.toString(), contains('overflowed'));
  }
}

/// Number of lines the symbol, separator and [number] occupy.
int _amountLines(WidgetTester tester, String number) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.textContaining(number),
  );
  final text = paragraph.text.toPlainText();
  final at = text.indexOf(number);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: at - 3, extentOffset: at + number.length),
  );
  return boxes.map((b) => b.top.round()).toSet().length;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(_loadInter);

  testWidgets('a refuel amount stays on one line at 411 dp, scale 2.0', (
    tester,
  ) async {
    await _pumpHistory(tester, width: 411, scale: 2, price: 2000);
    _drainDateOverflow(tester);

    expect(_amountLines(tester, '2,000.00'), 1);
  });

  testWidgets('a 7-digit refuel amount stays whole at 360 dp, scale 2.0', (
    tester,
  ) async {
    await _pumpHistory(tester, width: 360, scale: 2, price: 1234567);
    _drainDateOverflow(tester);

    expect(_amountLines(tester, '1,234,567.00'), 1);
    expect(
      tester.getRect(find.textContaining('1,234,567.00')).right,
      lessThanOrEqualTo(360 - 16),
    );
  });
}

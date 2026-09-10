import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/entities/expense.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/presentation/expenses/expenses_tab.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_expense_repository.dart';
import '../helpers/fake_vehicle_repository.dart';

const _vehicle = Vehicle(
  id: 1,
  name: 'Swift',
  type: VehicleType.car,
  fuelCategory: FuelCategory.petrol,
);

Future<FakeExpenseRepository> pumpScreen(
  WidgetTester tester, {
  FakeExpenseRepository? repo,
}) async {
  final expenseRepo = repo ?? FakeExpenseRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          FakeVehicleRepository([_vehicle]),
        ),
        expenseRepositoryProvider.overrideWithValue(expenseRepo),
      ],
      child: const MaterialApp(home: ExpensesTab()),
    ),
  );
  await tester.pumpAndSettle();
  return expenseRepo;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('an empty vehicle shows the empty state', (tester) async {
    await pumpScreen(tester);

    expect(find.text('No expenses yet'), findsOneWidget);
  });

  testWidgets('a suggestion chip fills the category field', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Log expense'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ActionChip, 'Tyre'));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const Key('expenseCategoryField')),
    );
    expect(field.controller!.text, 'Tyre');
  });

  testWidgets('logging an expense writes it through the use case', (
    tester,
  ) async {
    final repo = await pumpScreen(tester);

    await tester.tap(find.text('Log expense'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('expenseAmountField')), '800');
    await tester.tap(find.widgetWithText(ActionChip, 'Tyre'));
    await tester.tap(find.byKey(const Key('saveExpenseButton')));
    await tester.pumpAndSettle();

    expect(repo.expenses, hasLength(1));
    expect(repo.expenses.single.amount, 800);
    expect(repo.expenses.single.category, 'Tyre');
    expect(find.text('No expenses yet'), findsNothing);
  });

  testWidgets('a zero amount is rejected inline', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Log expense'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('expenseAmountField')), '0');
    await tester.tap(find.widgetWithText(ActionChip, 'Tyre'));
    await tester.tap(find.byKey(const Key('saveExpenseButton')));
    await tester.pumpAndSettle();

    expect(find.text('Amount must be greater than zero.'), findsOneWidget);
  });

  testWidgets('deleting an expense at once offers undo', (tester) async {
    final repo = await pumpScreen(tester);

    await tester.tap(find.text('Log expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expenseAmountField')), '800');
    await tester.tap(find.widgetWithText(ActionChip, 'Tyre'));
    await tester.tap(find.byKey(const Key('saveExpenseButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete Tyre'));
    await tester.pumpAndSettle();

    expect(repo.expenses, isEmpty);
    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.text('Expense deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(repo.expenses, hasLength(1));
    expect(repo.expenses.single.category, 'Tyre');
    expect(find.text('No expenses yet'), findsNothing);
  });

  testWidgets(
    'a long expense list builds a far row only when scrolled to, and a delete still finishes and undoes after the row is scrolled away',
    (tester) async {
      final gate = Completer<void>();
      final repo = await pumpScreen(
        tester,
        repo: _GatedExpenseRepository(gate, [
          for (var i = 1; i <= 40; i++)
            Expense(
              id: i,
              vehicleId: 1,
              amount: 100,
              date: DateTime.now().subtract(Duration(days: i)),
              category: 'Item $i',
            ),
        ]),
      );

      expect(find.text('Item 40', skipOffstage: false), findsNothing);

      await tester.scrollUntilVisible(find.text('Item 40'), 500);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete Item 40'));
      await tester.pump();

      await tester.drag(find.byType(Scrollable), const Offset(0, 10000));
      await tester.pumpAndSettle();
      expect(find.text('Item 40', skipOffstage: false), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(repo.expenses.map((e) => e.id), isNot(contains(40)));
      expect(find.text('Expense deleted'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(repo.expenses.map((e) => e.id), contains(40));
    },
  );
}

/// Holds every delete until [gate] completes.
class _GatedExpenseRepository extends FakeExpenseRepository {
  _GatedExpenseRepository(this.gate, super.seed);

  final Completer<void> gate;

  @override
  Future<Result<Unit>> delete(int id) async {
    await gate.future;
    return super.delete(id);
  }
}

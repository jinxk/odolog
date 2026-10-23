import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/app/theme/theme.dart';
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
  ThemeData? theme,
  double textScale = 1,
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
      child: MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const ExpensesTab(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return expenseRepo;
}

Future<void> _loadInter() async {
  final loader = FontLoader('Inter');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
  }
  await loader.load();
}

Future<void> _pumpLargeAmount(
  WidgetTester tester, {
  required double width,
  required double textScale,
}) async {
  await _loadInter();
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await pumpScreen(
    tester,
    theme: AppTheme.light,
    textScale: textScale,
    repo: FakeExpenseRepository([
      Expense(
        id: 1,
        vehicleId: 1,
        amount: 1234567,
        date: DateTime(2026, 9, 23),
        odometer: 12345,
        category: 'Insurance',
      ),
    ]),
  );
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

  testWidgets('a 7-digit amount stays whole at 360 dp, scale 2.0', (
    tester,
  ) async {
    await _pumpLargeAmount(tester, width: 360, textScale: 2);

    expect(tester.takeException(), isNull);
    final amount = find.textContaining('1,234,567.00');
    final paragraph = tester.renderObject<RenderParagraph>(amount);
    final text = paragraph.text.toPlainText();
    final at = text.indexOf('1,234,567.00');
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: at - 3, extentOffset: at + 12),
    );
    expect(boxes.map((b) => b.top.round()).toSet(), hasLength(1));
    expect(tester.getRect(amount).right, lessThanOrEqualTo(360));
  });

  testWidgets('the category is not squeezed by a 7-digit amount at 360 dp', (
    tester,
  ) async {
    await _pumpLargeAmount(tester, width: 360, textScale: 1);

    expect(tester.getSize(find.text('Insurance')).height, lessThan(40));
  });
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

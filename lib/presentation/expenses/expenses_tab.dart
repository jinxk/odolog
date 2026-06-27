import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/spacing.dart';
import '../../core/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/vehicle.dart';
import '../common/csv_safe_text_formatter.dart';
import '../common/empty_state.dart';
import '../common/formatting.dart';
import '../common/grouped_list.dart';
import '../common/single_decimal_formatter.dart';
import '../providers/app_providers.dart';
import '../providers/auto_backup_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/usecases.dart';

const _categorySuggestions = [
  'Service',
  'Tyre',
  'Repair',
  'Insurance',
  'Other',
];

/// The expenses segment of the history tab: the active vehicle's non-fuel
/// spend as a flat list, most recent first. A nested Scaffold, so the segment
/// carries its own log action instead of borrowing the shell's refuel button.
/// Kept deliberately narrow, matching [Expense]'s own scope: amount, date, an
/// optional odometer, and one free text category.
class ExpensesTab extends ConsumerWidget {
  const ExpensesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(currentVehicleProvider).value;
    return Scaffold(
      body: vehicle == null
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No vehicle yet',
              message: 'Add a vehicle to track its expenses.',
            )
          : _ExpensesBody(vehicle: vehicle),
      floatingActionButton: vehicle == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _logExpense(context, ref, vehicle),
              icon: const Icon(Icons.add),
              label: const Text('Log expense'),
            ),
    );
  }

  Future<void> _logExpense(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LogExpenseSheet(vehicle: vehicle),
    );
    if (saved != true) return;
    ref.invalidate(expensesProvider(vehicle.id));
    ref.invalidate(vehicleStatsProvider(vehicle.id));
    unawaited(ref.read(autoBackupProvider.notifier).runIfDue());
  }
}

class _ExpensesBody extends ConsumerWidget {
  const _ExpensesBody({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(settingsProvider).value?.currencySymbol ?? 'Rs';
    final expenses = ref.watch(expensesProvider(vehicle.id));
    return expenses.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses yet',
            message: 'Log a tyre change, a repair, or anything else non-fuel.',
          );
        }
        return ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenH,
            right: AppSpacing.screenH,
            top: 8,
            bottom: 88,
          ),
          children: [
            GroupedList(
              rows: [
                for (final expense in list)
                  _ExpenseRow(
                    vehicle: vehicle,
                    expense: expense,
                    currency: currency,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ExpenseRow extends ConsumerWidget {
  const _ExpenseRow({
    required this.vehicle,
    required this.expense,
    required this.currency,
  });

  final Vehicle vehicle;
  final Expense expense;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitleParts = <String>[
      formatDate(expense.date),
      if (expense.odometer != null) formatDistance(expense.odometer!),
    ];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.receipt_long_outlined),
      title: Text(expense.category),
      subtitle: Text(subtitleParts.join(', ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatMoney(expense.amount, currency),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deleteExpenseProvider).execute(expense.id);
    ref.invalidate(expensesProvider(vehicle.id));
    ref.invalidate(vehicleStatsProvider(vehicle.id));
    unawaited(ref.read(autoBackupProvider.notifier).runIfDue());
  }
}

/// A compact bottom sheet form: amount, date, an optional odometer, and the
/// category as free text backed by suggestion chips rather than a fixed enum,
/// so a category outside the five suggestions is still one tap of typing away.
class _LogExpenseSheet extends ConsumerStatefulWidget {
  const _LogExpenseSheet({required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<_LogExpenseSheet> createState() => _LogExpenseSheetState();
}

class _LogExpenseSheetState extends ConsumerState<_LogExpenseSheet> {
  DateTime _date = DateTime.now();
  final _amount = TextEditingController();
  final _odometer = TextEditingController();
  final _category = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _odometer.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null) {
      setState(() {
        _saving = false;
        _error = 'Enter the amount.';
      });
      return;
    }
    final expense = Expense(
      id: 0,
      vehicleId: widget.vehicle.id,
      amount: amount,
      date: _date,
      odometer: double.tryParse(_odometer.text.trim()),
      category: _category.text.trim(),
    );
    final result = await ref.read(logExpenseProvider).execute(expense);
    if (!mounted) return;
    result.match(
      (failure) => setState(() {
        _saving = false;
        _error = _message(failure);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  String _message(Failure failure) => switch (failure) {
    ValidationFailure(:final reason) => reason,
    NotFoundFailure(:final message) => message,
    DatabaseFailure(:final message) => message,
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log expense', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              key: const Key('expenseAmountField'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [SingleDecimalFormatter()],
              decoration: InputDecoration(
                labelText: 'Amount',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Date'),
              subtitle: Text(formatDate(_date)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('expenseOdometerField'),
              controller: _odometer,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [SingleDecimalFormatter()],
              decoration: const InputDecoration(
                labelText: 'Odometer',
                suffixText: 'km',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('expenseCategoryField'),
              controller: _category,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [csvSafeTextFormatter],
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final suggestion in _categorySuggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () =>
                        setState(() => _category.text = suggestion),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('saveExpenseButton'),
                onPressed: _saving ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

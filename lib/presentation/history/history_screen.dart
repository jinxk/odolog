import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_vehicle_history.dart';
import '../../domain/value_objects/window_mileage.dart';
import '../common/empty_state.dart';
import '../common/formatting.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';

/// A reverse chronological timeline of fills for the active vehicle. Partial
/// fills are marked, since they do not close a mileage window on their own, and
/// the per window mileage is shown against the fill that closed the window.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(currentVehicleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: vehicle.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (vehicle) => vehicle == null
            ? const EmptyState(
                icon: Icons.history,
                title: 'No history yet',
                message: 'Add a vehicle and log a fill to see it here.',
              )
            : _HistoryList(vehicle: vehicle),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider(vehicle.id));
    final windows =
        ref.watch(vehicleWindowsProvider(vehicle.id)).value ??
        const <WindowMileage>[];
    final currency = ref.watch(settingsProvider).value?.currencySymbol ?? 'Rs';
    final byClosing = {for (final w in windows) w.closingEntryId: w};

    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.local_gas_station_outlined,
            title: 'No fills yet',
            message: 'Log your first refuel to start the timeline.',
          );
        }
        final reversed = items.reversed.toList();
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: reversed.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = reversed[index];
            return _HistoryRow(
              vehicle: vehicle,
              item: item,
              window: byClosing[item.entry.id],
              currency: currency,
            );
          },
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.vehicle,
    required this.item,
    required this.window,
    required this.currency,
  });

  final Vehicle vehicle;
  final HistoryItem item;
  final WindowMileage? window;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = unitLabel(vehicle.fuelCategory);
    final entry = item.entry;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Row(
        children: [
          Text(formatDate(entry.filledAt), style: theme.textTheme.titleMedium),
          const SizedBox(width: 8),
          if (!entry.fullTank)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Partial',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '${formatQuantity(entry.quantity)} $unit, '
            '${formatMoney(entry.pricePaid, currency)}',
          ),
          if (window != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${formatMileage(window!.mileage)} '
                '${mileageUnit(vehicle.fuelCategory)}, '
                '${formatMoneyPerKm(window!.costPerKm, currency)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/entry/${entry.id}', extra: vehicle),
    );
  }
}

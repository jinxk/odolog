import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/fuel_variant.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_vehicle_history.dart';
import '../../domain/value_objects/window_mileage.dart';
import '../add_refuel/refuel_args.dart';
import '../common/formatting.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';
import '../providers/usecases.dart';

/// The full record for one fill: every stored field plus the derived values
/// that involve it. Edit reopens the refuel form seeded with this entry; delete
/// asks for confirmation first.
class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({
    super.key,
    required this.entryId,
    required this.vehicle,
  });

  final int entryId;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider(vehicle.id));
    final windows =
        ref.watch(vehicleWindowsProvider(vehicle.id)).value ??
        const <WindowMileage>[];
    final currency = ref.watch(settingsProvider).value?.currencySymbol ?? 'Rs';
    final variants =
        ref.watch(catalogProvider(vehicle.fuelCategory)).value ??
        const <FuelVariant>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Refuel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (items) {
          HistoryItem? match;
          for (final item in items) {
            if (item.entry.id == entryId) match = item;
          }
          if (match == null) {
            return const Center(child: Text('This entry no longer exists.'));
          }
          final window = windows
              .where((w) => w.closingEntryId == entryId)
              .firstOrNull;
          return _Detail(
            vehicle: vehicle,
            item: match,
            window: window,
            currency: currency,
            variants: variants,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.edit),
        label: const Text('Edit'),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final items = ref.read(historyProvider(vehicle.id)).value ?? const [];
    final match = items.where((i) => i.entry.id == entryId).firstOrNull;
    if (match == null) return;
    await context.push(
      '/add',
      extra: RefuelArgs(vehicle: vehicle, existing: match.entry),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this refuel?'),
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
    await ref.read(deleteRefuelProvider).execute(entryId);
    ref.invalidate(historyProvider(vehicle.id));
    ref.invalidate(vehicleStatsProvider(vehicle.id));
    ref.invalidate(vehicleWindowsProvider(vehicle.id));
    ref.invalidate(vehicleMonthlyProvider(vehicle.id));
    if (context.mounted && context.canPop()) context.pop();
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.vehicle,
    required this.item,
    required this.window,
    required this.currency,
    required this.variants,
  });

  final Vehicle vehicle;
  final HistoryItem item;
  final WindowMileage? window;
  final String currency;
  final List<FuelVariant> variants;

  /// The catalog display name for a stored variant id. The raw id is the
  /// fallback for an entry whose variant has left the catalog, so the record
  /// still says something rather than nothing.
  String _variantName(String id) {
    for (final variant in variants) {
      if (variant.id == id) return '${variant.brandName} ${variant.name}';
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;
    final unit = unitLabel(vehicle.fuelCategory);
    final rows = <(String, String)>[
      ('Date', formatDateTime(entry.filledAt)),
      ('Odometer', formatDistance(entry.odometer)),
      ('Quantity', '${formatQuantity(entry.quantity)} $unit'),
      ('Price paid', formatMoney(entry.pricePaid, currency)),
      ('Price per $unit', formatMoney(item.derived.pricePerUnit, currency)),
      ('Full tank', entry.fullTank ? 'Yes' : 'No, partial fill'),
      if (entry.variantOther != null && entry.variantOther!.isNotEmpty)
        ('Fuel', entry.variantOther!)
      else if (entry.variantId != null)
        ('Fuel', _variantName(entry.variantId!)),
      if (entry.stationName != null) ('Station', entry.stationName!),
      if (entry.notes != null) ('Notes', entry.notes!),
      if (entry.odometerOverride)
        ('Odometer override', 'A lower reading was allowed'),
      if (item.derived.distanceSincePrevious != null)
        ('Since previous', formatDistance(item.derived.distanceSincePrevious!)),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final row in rows) _DetailRow(label: row.$1, value: row.$2),
        if (window != null) ...[
          const SizedBox(height: 12),
          Text(
            'This fill closed a full tank window',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Mileage',
            value:
                '${formatMileage(window!.mileage)} '
                '${mileageUnit(vehicle.fuelCategory)}',
          ),
          _DetailRow(
            label: 'Cost per km',
            value: formatMoneyPerKm(window!.costPerKm, currency),
          ),
          _DetailRow(
            label: 'Window distance',
            value: formatDistance(window!.distance),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

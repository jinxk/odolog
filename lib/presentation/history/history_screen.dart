import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_vehicle_history.dart';
import '../../domain/value_objects/window_mileage.dart';
import '../common/empty_state.dart';
import '../common/formatting.dart';
import '../common/motion.dart';
import '../expenses/expenses_tab.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';
import '../service/service_log_tab.dart';

/// Every log the app keeps, in one place, split by a segment control: the
/// refuel timeline, the service log, and the non-fuel expenses. The refuel
/// timeline is reverse chronological, grouped under month headers; partial
/// fills are marked, since they do not close a mileage window on their own,
/// and the per window mileage is shown against the fill that closed the
/// window. The segment lives in [historyTabProvider] rather than local state
/// so the shell can float the matching add button and the dashboard's service
/// glance can land here on the right segment.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(historyTabProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: EntranceFade(child: _ScreenTitle('History')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                8,
                AppSpacing.screenH,
                4,
              ),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<HistorySegment>(
                  segments: const [
                    ButtonSegment(
                      value: HistorySegment.fuel,
                      label: Text('Fuel'),
                    ),
                    ButtonSegment(
                      value: HistorySegment.service,
                      label: Text('Service'),
                    ),
                    ButtonSegment(
                      value: HistorySegment.expenses,
                      label: Text('Expenses'),
                    ),
                  ],
                  selected: {segment},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => ref
                      .read(historyTabProvider.notifier)
                      .select(selection.first),
                ),
              ),
            ),
            Expanded(
              child: switch (segment) {
                HistorySegment.fuel => const _FuelHistory(),
                HistorySegment.service => const ServiceLogTab(),
                HistorySegment.expenses => const ExpensesTab(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The fuel segment: the refuel timeline for the active vehicle.
class _FuelHistory extends ConsumerWidget {
  const _FuelHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(currentVehicleProvider);
    return vehicle.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (vehicle) => vehicle == null
          ? const EmptyState(
              icon: Icons.history,
              title: 'No history yet',
              message: 'Add a vehicle and log a fill to see it here.',
            )
          : _HistoryList(vehicle: vehicle),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roles =
        theme.extension<AppColorRoles>() ??
        AppColorRoles.of(theme.colorScheme.onSurface, theme.brightness);
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
        // Rows carry their own month header when the month changes, so one flat
        // list stays lazy instead of building every group up front.
        final children = <Widget>[];
        DateTime? runningMonth;
        for (var i = 0; i < reversed.length; i++) {
          final item = reversed[i];
          final month = DateTime(
            item.entry.filledAt.year,
            item.entry.filledAt.month,
          );
          final newMonth = runningMonth == null || month != runningMonth;
          if (newMonth) {
            runningMonth = month;
            children.add(
              Padding(
                padding: EdgeInsets.only(
                  top: children.isEmpty ? 8 : AppSpacing.betweenSections,
                  bottom: 4,
                ),
                child: Text(
                  formatMonth(month),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            );
          } else {
            // Inset hairline between rows in the same month, stopping short of
            // the row edges rather than cutting fully across.
            children.add(Divider(height: 1, color: roles.hairline));
          }
          children.add(
            _HistoryRow(
              vehicle: vehicle,
              item: item,
              window: byClosing[item.entry.id],
              currency: currency,
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenH,
            right: AppSpacing.screenH,
            bottom: 88,
          ),
          children: children,
        );
      },
    );
  }
}

/// The left aligned large title that anchors the screen.
class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
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
    final roles =
        theme.extension<AppColorRoles>() ??
        AppColorRoles.of(theme.colorScheme.onSurface, theme.brightness);
    final isDark = theme.brightness == Brightness.dark;
    final unit = unitLabel(vehicle.fuelCategory);
    final entry = item.entry;
    // Amber marks the window mileage where it is legible, on the dark theme's
    // dark rows. On the light surface amber drops to 1.72:1, so the figure falls
    // back to a quiet tertiary and leans on its position and tabular weight
    // instead of colour.
    final mileageColor = isDark ? AppColors.amber : roles.textTertiary;
    return InkWell(
      onTap: () => context.push('/entry/${entry.id}', extra: vehicle),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        formatDate(entry.filledAt),
                        style: theme.textTheme.titleMedium,
                      ),
                      if (!entry.fullTank) ...[
                        const SizedBox(width: 8),
                        const _PartialPill(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatQuantity(entry.quantity)} $unit, '
                    '${formatMoney(entry.pricePaid, currency)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: roles.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (window != null) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMileage(window!.mileage),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: mileageColor,
                    ),
                  ),
                  Text(
                    mileageUnit(vehicle.fuelCategory),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: roles.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// A small teal pill marking a partial fill, which does not close a window.
class _PartialPill extends StatelessWidget {
  const _PartialPill();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? AppColors.tealBright : theme.colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.15),
        shape: const StadiumBorder(),
      ),
      child: Text(
        'Partial',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

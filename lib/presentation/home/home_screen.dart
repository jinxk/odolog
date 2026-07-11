import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/theme.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/value_objects/vehicle_stats.dart';
import '../common/empty_state.dart';
import '../common/formatting.dart';
import '../common/mileage_trend.dart';
import '../add_refuel/refuel_args.dart';
import '../common/section_header.dart';
import '../common/stat_card.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';

/// The home dashboard: greeting, the hero stat card, quick actions, and the
/// last fill and this month cards. The centre of gravity is the add refuel
/// action, reachable here and from the bottom navigation.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(currentVehicleProvider);
    return Scaffold(
      body: SafeArea(
        child: vehicle.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (vehicle) {
            if (vehicle == null) {
              return EmptyState(
                icon: Icons.directions_car_outlined,
                title: 'No vehicle yet',
                message: 'Add a vehicle to start logging fills.',
                action: FilledButton(
                  onPressed: () => context.go('/vehicles/new'),
                  child: const Text('Add vehicle'),
                ),
              );
            }
            return _Dashboard(vehicle: vehicle);
          },
        ),
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(settingsProvider).value?.currencySymbol ?? 'Rs';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Greeting(vehicle: vehicle),
        const SizedBox(height: 16),
        _HeroCard(vehicle: vehicle, currency: currency),
        const SizedBox(height: 20),
        _QuickActions(vehicle: vehicle),
        const SizedBox(height: 8),
        _LastFillCard(vehicle: vehicle, currency: currency),
        _ThisMonthCard(vehicle: vehicle, currency: currency),
        _TrendCard(vehicle: vehicle),
      ],
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vehicles = ref.watch(vehicleListProvider).value ?? const [];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OdoLog', style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                InkWell(
                  onTap: vehicles.length > 1
                      ? () => _openSwitcher(context, ref, vehicles)
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vehicle.name, style: theme.textTheme.titleLarge),
                      if (vehicles.length > 1)
                        const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_gas_station, size: 28),
        ],
      ),
    );
  }

  Future<void> _openSwitcher(
    BuildContext context,
    WidgetRef ref,
    List<Vehicle> vehicles,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in vehicles)
              ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text(option.name),
                selected: option.id == vehicle.id,
                onTap: () {
                  ref.read(activeVehicleIdProvider.notifier).select(option.id);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.vehicle, required this.currency});

  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(vehicleStatsProvider(vehicle.id));
    // The hero keeps its dark ink fill in the light theme, where it floats
    // against the near white surface. On the true black dark scaffold that same
    // ink separates at only 1.14:1 and the card boundary disappears, so there
    // the fill lifts to surfaceDark with an amber tinted hairline to read as a
    // card without recolouring the numerals.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: AppColors.amber.withValues(alpha: 0.24))
            : null,
      ),
      child: stats.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) =>
            Text('$error', style: const TextStyle(color: AppColors.offWhite)),
        data: (stats) => _heroContent(context, stats),
      ),
    );
  }

  Widget _heroContent(BuildContext context, VehicleStats stats) {
    if (stats.totalQuantity == 0) {
      return const _HeroMessage(
        title: 'Ready when you are',
        message: 'Add your first refuel to get started.',
      );
    }
    final window = stats.latestWindow;
    if (window == null) {
      return const _HeroMessage(
        title: 'Almost there',
        message: 'Log one more full tank to see your mileage.',
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _HeroFigure(
            label: 'Mileage',
            value: formatMileage(window.mileage),
            unit: mileageUnit(vehicle.fuelCategory),
            valueColor: AppColors.amber,
          ),
        ),
        Expanded(
          child: _HeroFigure(
            label: 'Cost per km',
            value: '$currency ${window.costPerKm.toStringAsFixed(2)}',
            unit: '/km',
            valueColor: AppColors.offWhite,
          ),
        ),
      ],
    );
  }
}

class _HeroFigure extends StatelessWidget {
  const _HeroFigure({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.offWhite,
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // The 56px numeral must never overflow the narrow half of the row on a
        // 360 to 412dp phone, so it scales down to fit rather than clipping.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomLeft,
          child: Text(
            value,
            style: heroNumberStyle.copyWith(color: valueColor),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(color: AppColors.offWhite, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          'over your last full tank window',
          style: TextStyle(
            color: AppColors.offWhite.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _HeroMessage extends StatelessWidget {
  const _HeroMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.amber,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(color: AppColors.offWhite, fontSize: 15),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionTile(
          icon: Icons.add,
          label: 'Add refuel',
          highlight: true,
          onTap: () =>
              context.push('/add', extra: RefuelArgs(vehicle: vehicle)),
        ),
        _ActionTile(
          icon: Icons.directions_car,
          label: 'Vehicles',
          onTap: () => context.push('/vehicles'),
        ),
        _ActionTile(
          icon: Icons.history,
          label: 'History',
          onTap: () => context.go('/history'),
        ),
        _ActionTile(
          icon: Icons.insights,
          label: 'Stats',
          onTap: () => context.go('/stats'),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = highlight
        ? AppColors.amber
        : theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final foreground = highlight ? AppColors.ink : theme.colorScheme.onSurface;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(color: foreground, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LastFillCard extends ConsumerWidget {
  const _LastFillCard({required this.vehicle, required this.currency});

  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider(vehicle.id));
    return history.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final last = items.last;
        final unit = unitLabel(vehicle.fuelCategory);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Last fill'),
            SectionCard(
              onTap: () =>
                  context.push('/entry/${last.entry.id}', extra: vehicle),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDate(last.entry.filledAt),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      StatTile(
                        label: 'Quantity',
                        value: '${formatQuantity(last.entry.quantity)} $unit',
                      ),
                      StatTile(
                        label: 'Price',
                        value: formatMoney(last.entry.pricePaid, currency),
                      ),
                      StatTile(
                        label: 'Per $unit',
                        value: formatMoney(last.derived.pricePerUnit, currency),
                      ),
                      if (last.derived.distanceSincePrevious != null)
                        StatTile(
                          label: 'Since previous',
                          value: formatDistance(
                            last.derived.distanceSincePrevious!,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThisMonthCard extends ConsumerWidget {
  const _ThisMonthCard({required this.vehicle, required this.currency});

  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthly = ref.watch(vehicleMonthlyProvider(vehicle.id));
    return monthly.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (byMonth) {
        final now = DateTime.now();
        final key = DateTime(now.year, now.month);
        final stats = byMonth[key];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('This month'),
            SectionCard(
              child: stats == null
                  ? Text(
                      'No fills this month yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        StatTile(
                          label: 'Spend',
                          value: formatMoney(stats.totalSpend, currency),
                        ),
                        StatTile(
                          label: 'Distance',
                          value: formatDistance(stats.totalDistance),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TrendCard extends ConsumerWidget {
  const _TrendCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windows = ref.watch(vehicleWindowsProvider(vehicle.id));
    return windows.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (list) {
        if (list.length < 2) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('Mileage trend'),
            SectionCard(child: MileageTrend(windows: list)),
          ],
        );
      },
    );
  }
}

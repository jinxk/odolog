import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/value_objects/vehicle_stats.dart';
import '../../domain/value_objects/window_mileage.dart';
import '../common/empty_state.dart';
import '../common/formatting.dart';
import '../common/mileage_trend.dart';
import '../common/motion.dart';
import '../common/section_header.dart';
import '../common/stat_card.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';

/// Per vehicle aggregates: lifetime totals led by average mileage, a mileage
/// over time chart with one point per closed full tank window, and per month
/// rollups as a grouped list. Every figure has a defined empty state, so nothing
/// shows as a bare zero before its data.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(currentVehicleProvider);
    return Scaffold(
      body: SafeArea(
        child: vehicle.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (vehicle) => vehicle == null
              ? const EmptyState(
                  icon: Icons.insights,
                  title: 'No stats yet',
                  message: 'Add a vehicle and log fills to see your stats.',
                )
              : _StatsBody(vehicle: vehicle),
        ),
      ),
    );
  }
}

class _StatsBody extends ConsumerWidget {
  const _StatsBody({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(vehicleStatsProvider(vehicle.id));
    final monthly = ref.watch(vehicleMonthlyProvider(vehicle.id));
    final windows = ref.watch(vehicleWindowsProvider(vehicle.id));
    final currency = ref.watch(settingsProvider).value?.currencySymbol ?? 'Rs';

    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (stats) {
        if (stats.totalQuantity == 0) {
          return const EmptyState(
            icon: Icons.insights,
            title: 'Nothing to show yet',
            message: 'Log a couple of fills to see your stats.',
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
            const EntranceFade(child: _ScreenTitle('Stats')),
            const SizedBox(height: 12),
            EntranceFade(
              delay: const Duration(milliseconds: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('Lifetime'),
                  _LifetimeCard(
                    vehicle: vehicle,
                    stats: stats,
                    currency: currency,
                  ),
                ],
              ),
            ),
            const SectionHeader('Mileage trend'),
            _TrendSection(vehicle: vehicle, windows: windows),
            const SectionHeader('By month'),
            _MonthlySection(
              vehicle: vehicle,
              monthly: monthly,
              currency: currency,
            ),
          ],
        );
      },
    );
  }
}

/// The left aligned large title that anchors a screen.
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

/// Lifetime totals, led by average mileage as the one hero figure with the
/// remaining totals in a supporting two column grid, so the number riders care
/// about most is not lost among the accounting figures.
class _LifetimeCard extends StatelessWidget {
  const _LifetimeCard({
    required this.vehicle,
    required this.stats,
    required this.currency,
  });

  final Vehicle vehicle;
  final VehicleStats stats;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = unitLabel(vehicle.fuelCategory);
    final average = stats.averageMileage;
    final supporting = <Widget>[
      StatTile(
        label: 'Total spend',
        value: formatMoney(stats.totalSpend, currency),
      ),
      StatTile(
        label: 'Total distance',
        value: formatDistance(stats.totalDistance),
      ),
      StatTile(
        label: 'Total quantity',
        value: '${formatQuantity(stats.totalQuantity)} $unit',
      ),
      StatTile(
        label: 'Average cost per km',
        value: stats.averageCostPerKm == null
            ? 'Not yet'
            : formatMoneyPerKm(stats.averageCostPerKm!, currency),
      ),
      if (stats.projectedRange != null)
        StatTile(
          label: 'Projected range',
          value: formatDistance(stats.projectedRange!),
        ),
      // Non-fuel spend (expenses plus logged service cost) only earns a slot
      // once it exists, so a vehicle with no service or expense history reads
      // exactly as it did before this figure existed: fuel only.
      if (stats.nonFuelSpend > 0) ...[
        StatTile(
          label: 'Non-fuel spend',
          value: formatMoney(stats.nonFuelSpend, currency),
        ),
        StatTile(
          label: 'Total cost of ownership',
          value: formatMoney(stats.totalCostOfOwnership, currency),
          caption: stats.costPerKmOfOwnership == null
              ? null
              : '${formatMoneyPerKm(stats.costPerKmOfOwnership!, currency)} overall',
        ),
      ],
    ];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Average mileage', style: theme.textTheme.labelMedium),
          const SizedBox(height: 6),
          if (average == null) ...[
            Text('Not yet', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 2),
            Text('After one more full tank', style: theme.textTheme.bodySmall),
          ] else
            // The unit rides in the same string as the numeral so the hero
            // reads as one figure. Fitted so the 56px display never overflows a
            // narrow phone.
            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${formatMileage(average)} ${mileageUnit(vehicle.fuelCategory)}',
                  style: theme.textTheme.displayLarge,
                ),
              ),
            ),
          const SizedBox(height: 24),
          _twoColumnGrid(supporting),
        ],
      ),
    );
  }

  /// Lays [tiles] into two columns of equal width, so the supporting figures sit
  /// in a calm grid under the hero rather than in an uneven wrap.
  Widget _twoColumnGrid(List<Widget> tiles) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final hasSecond = i + 1 < tiles.length;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < tiles.length ? 16 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 16),
              Expanded(child: hasSecond ? tiles[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.vehicle, required this.windows});

  final Vehicle vehicle;
  final AsyncValue<List<WindowMileage>> windows;

  @override
  Widget build(BuildContext context) {
    return windows.maybeWhen(
      orElse: () => const SectionCard(child: Text('Loading trend...')),
      data: (list) {
        if (list.isEmpty) {
          return SectionCard(
            child: Text(
              'Log one more full tank to start the mileage trend.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MileageTrend(
                windows: list,
                unit: mileageUnit(vehicle.fuelCategory),
              ),
              const SizedBox(height: 12),
              Text(
                'Oldest to newest, one point per full tank window. The best '
                'window is marked in amber.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Per month rollups as one inset grouped list rather than a card per month, so
/// the months read as a single scannable column.
class _MonthlySection extends StatelessWidget {
  const _MonthlySection({
    required this.vehicle,
    required this.monthly,
    required this.currency,
  });

  final Vehicle vehicle;
  final AsyncValue<Map<DateTime, VehicleStats>> monthly;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles =
        theme.extension<AppColorRoles>() ??
        AppColorRoles.of(theme.colorScheme.onSurface, theme.brightness);
    return monthly.maybeWhen(
      orElse: () => const SectionCard(child: Text('Loading months...')),
      data: (byMonth) {
        if (byMonth.isEmpty) {
          return SectionCard(
            child: Text(
              'Monthly totals appear once you have logged a fill.',
              style: theme.textTheme.bodyLarge,
            ),
          );
        }
        final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
        return SectionCard(
          child: Column(
            children: [
              for (var i = 0; i < months.length; i++) ...[
                if (i > 0) Divider(height: 1, color: roles.hairline),
                _MonthRow(
                  vehicle: vehicle,
                  month: months[i],
                  stats: byMonth[months[i]]!,
                  currency: currency,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.vehicle,
    required this.month,
    required this.stats,
    required this.currency,
  });

  final Vehicle vehicle;
  final DateTime month;
  final VehicleStats stats;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mileage = stats.averageMileage;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatMonth(month), style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  formatDistance(stats.totalDistance),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(stats.totalSpend, currency),
                style: theme.textTheme.titleLarge,
              ),
              if (mileage != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Avg ${formatMileage(mileage)} '
                  '${mileageUnit(vehicle.fuelCategory)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

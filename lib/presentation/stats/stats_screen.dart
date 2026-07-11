import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vehicle.dart';
import '../../domain/value_objects/vehicle_stats.dart';
import '../../domain/value_objects/window_mileage.dart';
import '../common/empty_state.dart';
import '../common/formatting.dart';
import '../common/mileage_trend.dart';
import '../common/section_header.dart';
import '../common/stat_card.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';

/// Per vehicle aggregates: lifetime totals, per month rollups, and a mileage
/// over time chart with one point per closed full tank window. Every figure has
/// a defined empty state, so nothing shows as a bare zero before its data.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(currentVehicleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: vehicle.when(
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
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader('Lifetime'),
            _LifetimeCard(vehicle: vehicle, stats: stats, currency: currency),
            const SectionHeader('Mileage trend'),
            _TrendSection(vehicle: vehicle, windows: windows),
            const SectionHeader('By month'),
            _MonthlySection(monthly: monthly, currency: currency),
          ],
        );
      },
    );
  }
}

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
    final unit = unitLabel(vehicle.fuelCategory);
    return SectionCard(
      child: Wrap(
        spacing: 28,
        runSpacing: 16,
        children: [
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
            label: 'Average mileage',
            value: stats.averageMileage == null
                ? 'Not yet'
                : '${formatMileage(stats.averageMileage!)} '
                      '${mileageUnit(vehicle.fuelCategory)}',
            caption: stats.averageMileage == null
                ? 'After one more full tank'
                : null,
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
        ],
      ),
    );
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MileageTrend(windows: list),
              const SizedBox(height: 8),
              Text(
                'Oldest to newest, one bar per full tank window.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthlySection extends StatelessWidget {
  const _MonthlySection({required this.monthly, required this.currency});

  final AsyncValue<Map<DateTime, VehicleStats>> monthly;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return monthly.maybeWhen(
      orElse: () => const SectionCard(child: Text('Loading months...')),
      data: (byMonth) {
        if (byMonth.isEmpty) {
          return SectionCard(
            child: Text(
              'Monthly totals appear once you have logged a fill.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
        return Column(
          children: [
            for (final month in months)
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatMonth(month),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        StatTile(
                          label: 'Spend',
                          value: formatMoney(
                            byMonth[month]!.totalSpend,
                            currency,
                          ),
                        ),
                        StatTile(
                          label: 'Distance',
                          value: formatDistance(byMonth[month]!.totalDistance),
                        ),
                        if (byMonth[month]!.averageMileage != null)
                          StatTile(
                            label: 'Mileage',
                            value: formatMileage(
                              byMonth[month]!.averageMileage!,
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

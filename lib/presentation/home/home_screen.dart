import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/shapes.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/theme.dart';
import '../../domain/calculators/document_reminder_planner.dart';
import '../../domain/entities/refuel_entry.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/value_objects/document_alert.dart';
import '../../domain/value_objects/vehicle_stats.dart';
import '../add_refuel/refuel_args.dart';
import '../common/empty_state.dart';
import '../common/formatting.dart';
import '../common/mileage_trend.dart';
import '../common/motion.dart';
import '../common/section_header.dart';
import '../common/stat_card.dart';
import '../common/trend_delta_chip.dart';
import '../providers/app_providers.dart';
import '../providers/reminder_nudge_provider.dart';
import '../providers/settings_provider.dart';

/// The home dashboard: an editorial header, one dominant hero number, the add
/// refuel action, and the last fill, this month, and trend cards. The centre of
/// gravity is the add refuel action, reachable here and from the bottom
/// navigation.
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenH,
        vertical: 8,
      ),
      children: [
        _EditorialHeader(vehicle: vehicle),
        _DocumentsGlance(vehicle: vehicle),
        _ServiceDueGlance(vehicle: vehicle),
        const SizedBox(height: 20),
        EntranceFade(
          child: _HeroCard(vehicle: vehicle, currency: currency),
        ),
        const SizedBox(height: AppSpacing.betweenSections),
        EntranceFade(
          delay: const Duration(milliseconds: 40),
          child: _PrimaryActions(vehicle: vehicle),
        ),
        _BatteryNudgeCard(vehicle: vehicle),
        const SizedBox(height: AppSpacing.betweenSections),
        _LastFillCard(vehicle: vehicle, currency: currency),
        _ThisMonthCard(vehicle: vehicle, currency: currency),
        _TrendCard(vehicle: vehicle),
      ],
    );
  }
}

/// The screen header: a teal overline over the vehicle name as a large title,
/// with a switcher chevron only when there is more than one vehicle to switch
/// between. No container, left aligned, so the name anchors the screen the way
/// a large title does. The switcher opens as a menu anchored to the title
/// itself, not a bottom sheet: the finger is already at the top of the screen,
/// so the choices should appear under it instead of across the display where
/// the hand covers them on the way down.
class _EditorialHeader extends ConsumerWidget {
  const _EditorialHeader({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vehicles = ref.watch(vehicleListProvider).value ?? const [];
    final hasMany = vehicles.length > 1;
    // Teal reads at 5.7:1 on the light surface but only 3.2:1 on black, so the
    // dark theme lifts the overline to the brighter teal.
    final overlineColor = isDark ? AppColors.tealBright : AppColors.teal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OdoLog',
          style: theme.textTheme.labelMedium?.copyWith(
            color: overlineColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        MenuAnchor(
          menuChildren: [
            for (final option in vehicles)
              MenuItemButton(
                leadingIcon: const Icon(Icons.directions_car),
                trailingIcon: option.id == vehicle.id
                    ? const Icon(Icons.check)
                    : null,
                onPressed: () => ref
                    .read(activeVehicleIdProvider.notifier)
                    .select(option.id),
                child: Text(option.name),
              ),
          ],
          builder: (context, controller, _) => InkWell(
            onTap: hasMany
                ? () =>
                      controller.isOpen ? controller.close() : controller.open()
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    vehicle.name,
                    style: theme.textTheme.headlineMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasMany)
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 28,
                    color: theme.colorScheme.onSurface,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The dark hero surface built around a single dominant number: window mileage
/// as the amber numeral, with cost per km demoted below it. The fill stays dark
/// ink in the light theme where it floats on a soft shadow, and lifts to
/// surfaceDark with a hairline in the dark theme where ink on black would
/// disappear.
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.vehicle, required this.currency});

  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Fall back to the brightness-appropriate depth when the app theme
    // extension is absent, so the hero still renders under a bare theme.
    final depth =
        theme.extension<AppDepth>() ??
        (isDark ? AppDepth.dark : AppDepth.light);
    final stats = ref.watch(vehicleStatsProvider(vehicle.id));
    final shape = isDark
        ? ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.heroRadius),
            side: BorderSide(
              color: depth.heroTopHighlight ?? Colors.transparent,
            ),
          )
        : AppShapes.heroBorder;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.heroPadding),
      decoration: ShapeDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.ink,
        shape: shape,
        shadows: depth.heroShadow,
      ),
      child: stats.when(
        loading: () => const SizedBox(
          height: 140,
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
    final theme = Theme.of(context);
    final label = theme.textTheme.labelMedium?.copyWith(
      color: AppColors.offWhite.withValues(alpha: 0.7),
    );
    // The trend rides against the vehicle's rolling average, so a fresh figure
    // that has no average yet, or one that matches it exactly, shows no chip
    // rather than a misleading zero.
    final average = stats.averageMileage;
    final delta = average == null ? 0.0 : window.mileage - average;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mileage', style: label),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: CountUpText(
                  value: window.mileage,
                  format: formatMileage,
                  style: heroNumberStyle.copyWith(color: AppColors.amber),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                mileageUnit(vehicle.fuelCategory),
                style: const TextStyle(
                  color: AppColors.offWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (delta != 0) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TrendDeltaChip(
                  delta: delta,
                  format: formatMileage,
                  // The hero card is dark in both themes, so the delta always
                  // uses the dark semantic pair.
                  positiveColor: AppColors.positiveDark,
                  negativeColor: AppColors.negativeDark,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'over your last full tank window',
          style: TextStyle(
            color: AppColors.offWhite.withValues(alpha: 0.55),
            fontSize: 12,
          ),
        ),
        _ClaimedComparison(
          real: stats.averageMileage,
          claimed: vehicle.claimedMileage,
          category: vehicle.fuelCategory,
        ),
        const SizedBox(height: 22),
        Text('Cost per km', style: label),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CountUpText(
              value: window.costPerKm,
              format: (v) => '$currency ${v.toStringAsFixed(2)}',
              style: theme.textTheme.displaySmall!.copyWith(
                color: AppColors.offWhite,
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '/km',
                style: TextStyle(
                  color: AppColors.offWhite.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ),
          ],
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

/// The one taught primary action. The amber fill marks add refuel as the
/// thing to do here; history, stats, and vehicles are reached from the bottom
/// navigation and settings instead, so this card has no other pull on the eye.
class _PrimaryActions extends StatelessWidget {
  const _PrimaryActions({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _openAddRefuel(context, vehicle),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
        icon: const Icon(Icons.add),
        label: const Text('Add refuel'),
      ),
    );
  }

  /// Pushes the add refuel form and confirms a committed write with a snack bar,
  /// the same flow the shell's floating button runs, so the taught path here and
  /// the everywhere path from the bar behave identically.
  Future<void> _openAddRefuel(BuildContext context, Vehicle vehicle) async {
    final saved = await context.push<RefuelEntry?>(
      '/add',
      extra: RefuelArgs(vehicle: vehicle),
    );
    if (saved != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Refuel saved')));
    }
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

/// This month's spend, led by the figure and carrying a delta against last
/// month so the answer to "am I spending more than usual?" is on the card. Laid
/// out spend-first rather than as a tile grid so it does not read as a clone of
/// the last fill card above it.
class _ThisMonthCard extends ConsumerWidget {
  const _ThisMonthCard({required this.vehicle, required this.currency});

  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final roles =
        theme.extension<AppColorRoles>() ??
        AppColorRoles.of(theme.colorScheme.onSurface, theme.brightness);
    final monthly = ref.watch(vehicleMonthlyProvider(vehicle.id));
    return monthly.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (byMonth) {
        final now = DateTime.now();
        final stats = byMonth[DateTime(now.year, now.month)];
        // DateTime normalises a month of 0 to December of the prior year, so
        // this reaches last month without a special case in January.
        final previous = byMonth[DateTime(now.year, now.month - 1)];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader('This month'),
            SectionCard(
              child: stats == null
                  ? Text(
                      'No fills this month yet.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: roles.textSecondary,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spend', style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatMoney(stats.totalSpend, currency),
                              style: theme.textTheme.displaySmall,
                            ),
                            const SizedBox(width: 12),
                            if (previous != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: TrendDeltaChip(
                                  delta: stats.totalSpend - previous.totalSpend,
                                  format: (m) => formatMoney(m, currency),
                                  higherIsBetter: false,
                                  positiveColor: roles.positive,
                                  negativeColor: roles.negative,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.route_outlined,
                              size: 18,
                              color: roles.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Distance',
                              style: theme.textTheme.labelMedium,
                            ),
                            const Spacer(),
                            Text(
                              formatDistance(stats.totalDistance),
                              style: theme.textTheme.titleLarge,
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

/// The supporting line under the hero mileage that sets the owner's real
/// average against the manufacturer's claimed figure, the "company bola 60,
/// mil raha 45" comparison every Indian rider makes out loud. It uses the
/// lifetime average as the honest "real" number and shows the ratio as a
/// percentage. Hidden until both a claimed figure and a real average exist,
/// since a comparison needs both sides. Labelled "claimed", never "ARAI".
class _ClaimedComparison extends StatelessWidget {
  const _ClaimedComparison({
    required this.real,
    required this.claimed,
    required this.category,
  });

  final double? real;
  final double? claimed;
  final FuelCategory category;

  @override
  Widget build(BuildContext context) {
    final realValue = real;
    final claimedValue = claimed;
    if (realValue == null || claimedValue == null || claimedValue <= 0) {
      return const SizedBox.shrink();
    }
    final percent = (realValue / claimedValue * 100).round();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${formatMileage(realValue)} real vs '
        '${formatMileage(claimedValue)} claimed ($percent%)',
        style: TextStyle(
          color: AppColors.offWhite.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A slim, glanceable line that surfaces the nearest document expiry once it is
/// within thirty days or already overdue. It follows the same rule as the trend
/// chip: never colour alone. An icon and the words carry the meaning, and the
/// colour only reinforces it, amber for an approaching date and the theme's
/// negative for one that has lapsed. Renders nothing when nothing is due.
class _DocumentsGlance extends StatelessWidget {
  const _DocumentsGlance({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final alert = const DocumentReminderPlanner().nearestAlert(
      vehicle,
      now: DateTime.now(),
    );
    if (alert == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final roles =
        theme.extension<AppColorRoles>() ??
        AppColorRoles.of(theme.colorScheme.onSurface, theme.brightness);
    final isDark = theme.brightness == Brightness.dark;
    final color = alert.overdue
        ? roles.negative
        : (isDark ? AppColors.amber : AppColors.teal);
    final icon = alert.overdue
        ? Icons.warning_amber_rounded
        : Icons.schedule_outlined;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _glanceText(alert),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _glanceText(DocumentAlert alert) {
    final label = documentLabel(alert.document);
    if (alert.overdue) {
      final days = -alert.daysRemaining;
      return '$label expired ${_days(days)} ago';
    }
    if (alert.daysRemaining == 0) return '$label expires today';
    return '$label expires in ${_days(alert.daysRemaining)}';
  }

  String _days(int days) => days == 1 ? '1 day' : '$days days';
}

/// A glance line per maintenance template that has anything to show, tapping
/// through to the history tab's service segment. Unlike [_DocumentsGlance],
/// which surfaces
/// only the nearest alert, both templates get their own line here: there are
/// only ever two, so showing both costs nothing and a countdown line the
/// owner is not close to yet is still useful context, not noise.
class _ServiceDueGlance extends ConsumerWidget {
  const _ServiceDueGlance({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(serviceDueProvider(vehicle)).value;
    if (due == null) return const SizedBox.shrink();
    final withData = due
        .where((s) => s.remainingKm != null || s.remainingDays != null)
        .toList();
    if (withData.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final roles =
        theme.extension<AppColorRoles>() ??
        AppColorRoles.of(theme.colorScheme.onSurface, theme.brightness);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        ref.read(historyTabProvider.notifier).select(HistorySegment.service);
        context.go('/history');
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final status in withData)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      status.overdue
                          ? Icons.warning_amber_rounded
                          : Icons.build_outlined,
                      size: 18,
                      color: status.overdue
                          ? roles.negative
                          : (isDark ? AppColors.amber : AppColors.teal),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        serviceDueSummary(status),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: status.overdue
                              ? roles.negative
                              : (isDark ? AppColors.amber : AppColors.teal),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A one-time, dismissible card that warns about aggressive OEM battery
/// managers (MIUI, ColorOS, and the like) silently killing scheduled reminders,
/// and offers a shortcut into the app's system settings so the owner can allow
/// background activity. Shown only once the owner has entered at least one
/// document date, so it appears exactly when reminders start to matter, and
/// never again after it is dismissed.
class _BatteryNudgeCard extends ConsumerWidget {
  const _BatteryNudgeCard({required this.vehicle});

  final Vehicle vehicle;

  static const _packageName = 'com.jinxk.odolog';

  bool get _hasAnyDocument =>
      VehicleDocument.values.any((d) => vehicle.expiryFor(d) != null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_hasAnyDocument) return const SizedBox.shrink();
    final dismissed = ref.watch(reminderNudgeDismissedProvider).value ?? true;
    if (dismissed) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.betweenSections),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.battery_alert_outlined,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Keep reminders alive',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Some phones (MIUI, ColorOS, and others) shut down background '
                'apps to save battery, which can stop these reminders from '
                'firing. Allowing OdoLog to run in the background keeps them '
                'on time.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ref
                        .read(reminderNudgeDismissedProvider.notifier)
                        .dismiss(),
                    child: const Text('Got it'),
                  ),
                  if (Platform.isAndroid)
                    FilledButton(
                      onPressed: _openSettings,
                      child: const Text('Open settings'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens this app's system settings page, from which the battery and
  /// background limits are reachable on every OEM skin. The exact autostart
  /// screen is not a standard intent, so app details is the reliable landing
  /// spot to point the owner at.
  Future<void> _openSettings() async {
    if (!Platform.isAndroid) return;
    final intent = AndroidIntent(
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      data: 'package:$_packageName',
    );
    await intent.launch();
  }
}

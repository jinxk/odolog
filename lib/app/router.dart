import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entities/refuel_entry.dart';
import '../domain/entities/vehicle.dart';
import '../presentation/add_refuel/add_refuel_screen.dart';
import '../presentation/add_refuel/refuel_args.dart';
import '../presentation/entry_detail/entry_detail_screen.dart';
import '../presentation/history/history_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/providers/app_providers.dart';
import '../presentation/providers/auto_backup_provider.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/stats/stats_screen.dart';
import '../presentation/vehicles/vehicle_form_screen.dart';
import '../presentation/vehicles/vehicles_screen.dart';
import 'theme/colors.dart';

part 'router.g.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The single app router. It is built once and never rebuilt: recreating a
/// GoRouter that owns a StatefulShellRoute collides its GlobalKeys. So this
/// provider does not watch anything. Instead it listens to the vehicle list and
/// pushes the result into a refresh notifier that drives the onboarding
/// redirect, which keeps the router instance stable.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // null means unknown (still loading); the redirect waits rather than
  // bouncing to onboarding before the first read completes.
  final hasVehicles = ValueNotifier<bool?>(null);
  ref.onDispose(hasVehicles.dispose);
  ref.listen(vehicleListProvider, (previous, next) {
    hasVehicles.value = next.hasValue ? next.requireValue.isNotEmpty : null;
  }, fireImmediately: true);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: hasVehicles,
    redirect: (context, state) {
      final known = hasVehicles.value;
      if (known == null) return null;
      final atOnboarding = state.uri.path == '/onboarding';
      if (!known && !atOnboarding) return '/onboarding';
      if (known && atOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final args = state.extra as RefuelArgs;
          return AddRefuelScreen(
            vehicle: args.vehicle,
            existing: args.existing,
          );
        },
      ),
      GoRoute(
        path: '/entry/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return EntryDetailScreen(
            entryId: id,
            vehicle: state.extra as Vehicle,
          );
        },
      ),
      GoRoute(
        path: '/vehicles',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const VehiclesScreen(),
      ),
      GoRoute(
        path: '/vehicles/new',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const VehicleFormScreen(),
      ),
      GoRoute(
        path: '/vehicles/:id/edit',
        parentNavigatorKey: _rootKey,
        builder: (context, state) =>
            VehicleFormScreen(initial: state.extra as Vehicle?),
      ),
    ],
  );
}

/// The shell scaffold behind the bottom navigation bar. Also owns the
/// persistent add refuel entry point: a floating action button beats a center
/// `NavigationBar` destination here because `/add` is a modal push over the
/// root navigator rather than a fifth branch of the indexed stack, and a FAB
/// keeps that distinction visible instead of pretending it is another tab.
/// The FAB only shows on Stats and on the History tab's fuel segment, the
/// data views where a one-thumb add-refuel shortcut earns its place; Home
/// already has its own primary button, Settings has no logging context, and
/// the service and expenses segments float their own log buttons instead.
/// Centered above the bar it sits in the thumb's easy reach zone.
class _ShellScaffold extends ConsumerStatefulWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<_ShellScaffold> {
  bool _consentPromptScheduled = false;

  @override
  Widget build(BuildContext context) {
    final navigationShell = widget.navigationShell;
    final vehicle = ref.watch(currentVehicleProvider).value;
    final backup = ref.watch(autoBackupProvider).value;
    final segment = ref.watch(historyTabProvider);
    _maybePromptForConsent(hasVehicle: vehicle != null, backup: backup);
    final showFab =
        vehicle != null &&
        (navigationShell.currentIndex == 2 ||
            (navigationShell.currentIndex == 1 &&
                segment == HistorySegment.fuel));
    return Scaffold(
      body: navigationShell,
      floatingActionButton: showFab
          ? FloatingActionButton(
              key: const Key('addRefuelFab'),
              tooltip: 'Add refuel',
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.ink,
              onPressed: () => _openAddRefuel(context, vehicle),
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Stats',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  /// Pushes the add refuel form for [vehicle] and, once it reports a saved
  /// entry, confirms the write with a brief snack bar here on the shell. In
  /// glare the rider cannot always read fine print, so the haptic fired on
  /// save and this snack bar are the two forms of confirmation that survive
  /// sunlight.
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

  /// Shows the one time automatic backup consent, once, the first time the
  /// shell is reached with a vehicle on record and the platform supports the
  /// feature. Waiting for a vehicle keeps it out of a fresh install's
  /// onboarding, so the prompt lands when there is data actually worth
  /// protecting.
  void _maybePromptForConsent({
    required bool hasVehicle,
    required AutoBackupState? backup,
  }) {
    if (_consentPromptScheduled || !hasVehicle || backup == null) return;
    if (!backup.available || backup.consentAsked) return;
    _consentPromptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showConsentDialog();
    });
  }

  Future<void> _showConsentDialog() async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Keep a backup outside the app?'),
        content: const Text(
          'OdoLog can save a copy of your data to the Downloads folder on your '
          'phone, in Downloads/OdoLog, once a day. That copy stays even if you '
          'uninstall or reinstall the app, so a bad update cannot take your '
          'fuel history with it. It never leaves your phone. You can change '
          'this any time under Settings, Data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Turn on'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    await ref
        .read(autoBackupProvider.notifier)
        .recordConsent(accepted: accepted ?? false);
  }
}

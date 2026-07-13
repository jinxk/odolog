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
class _ShellScaffold extends ConsumerWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(currentVehicleProvider).value;
    final segment = ref.watch(historyTabProvider);
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
}

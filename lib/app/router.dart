import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

class _ShellScaffold extends StatelessWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
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
}

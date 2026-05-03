import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odolog/presentation/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the Vehicles row pushes the vehicles route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SettingsScreen()),
        GoRoute(
          path: '/vehicles',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('vehicles'))),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    final vehiclesRow = find.widgetWithText(ListTile, 'Vehicles');
    expect(vehiclesRow, findsOneWidget);

    await tester.tap(vehiclesRow);
    await tester.pumpAndSettle();

    expect(find.text('vehicles'), findsOneWidget);
  });
}

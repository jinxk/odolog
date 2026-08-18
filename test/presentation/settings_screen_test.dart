import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:odolog/domain/backup/auto_backup_policy.dart';
import 'package:odolog/domain/usecases/reset_all_data.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/providers/usecases.dart';
import 'package:odolog/presentation/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auto_backup_writer.dart';
import '../helpers/fake_data_eraser.dart';
import '../helpers/fake_reminder_scheduler.dart';
import '../helpers/fake_vehicle_repository.dart';

GoRouter _settingsRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SettingsScreen()),
  ],
);

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

  testWidgets(
    'the backup row explains itself when the platform cannot run it',
    (tester) async {
      // A tall surface so the whole settings list, backup row included, builds
      // without scrolling.
      await tester.binding.setSurfaceSize(const Size(1200, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autoBackupWriterProvider.overrideWithValue(
              FakeAutoBackupWriter(available: false),
            ),
          ],
          child: MaterialApp.router(routerConfig: _settingsRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Automatic backup'), findsOneWidget);
      expect(find.text('Needs Android 10 or newer.'), findsOneWidget);
    },
  );

  testWidgets('the backup toggle turns the feature on', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // A last backup already recorded for today keeps the toggle from firing a
    // real backup (nothing is due), so the tap only flips the preference.
    SharedPreferences.setMockInitialValues({
      'autoBackup.lastDay': AutoBackupPolicy.dayStamp(DateTime.now()),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          autoBackupWriterProvider.overrideWithValue(
            FakeAutoBackupWriter(available: true),
          ),
        ],
        child: MaterialApp.router(routerConfig: _settingsRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.textContaining('survives an uninstall'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.textContaining('On.'), findsOneWidget);
  });

  testWidgets('the Delete button stays disabled until DELETE is typed', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleRepositoryProvider.overrideWithValue(FakeVehicleRepository()),
          resetAllDataProvider.overrideWithValue(
            ResetAllData(FakeDataEraser(), FakeReminderScheduler()),
          ),
        ],
        child: MaterialApp.router(routerConfig: _settingsRouter()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Delete all data'));
    await tester.pumpAndSettle();

    final deleteButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete'),
    );
    expect(deleteButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('tapping Delete erases everything and leaves for onboarding', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final eraser = FakeDataEraser();
    final scheduler = FakeReminderScheduler();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SettingsScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('onboarding'))),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleRepositoryProvider.overrideWithValue(FakeVehicleRepository()),
          resetAllDataProvider.overrideWithValue(
            ResetAllData(eraser, scheduler),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'Delete all data'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(eraser.erased, isTrue);
    expect(scheduler.cancelledAll, isTrue);
    expect(find.text('onboarding'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
  });
}

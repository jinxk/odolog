import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:odolog/app/theme/theme.dart';
import 'package:odolog/domain/backup/auto_backup_policy.dart';
import 'package:odolog/domain/entities/service_log_entry.dart';
import 'package:odolog/domain/entities/vehicle.dart';
import 'package:odolog/domain/usecases/import_data.dart';
import 'package:odolog/domain/usecases/reset_all_data.dart';
import 'package:odolog/presentation/providers/backup_file_picker.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/providers/usecases.dart';
import 'package:odolog/presentation/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auto_backup_writer.dart';
import '../helpers/fake_data_eraser.dart';
import '../helpers/fake_odometer_reading_repository.dart';
import '../helpers/fake_refuel_repository.dart';
import '../helpers/fake_reminder_scheduler.dart';
import '../helpers/fake_service_log_repository.dart';
import '../helpers/fake_vehicle_repository.dart';
import '../helpers/held_import.dart';
import '../helpers/unreadable_file.dart';

GoRouter _settingsRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SettingsScreen()),
  ],
);

final _now = DateTime.now();

/// A vehicle with an insurance date and a logged general service, so both
/// reminder categories have something to list.
final _activa = Vehicle(
  id: 1,
  name: 'Activa',
  type: VehicleType.scooter,
  fuelCategory: FuelCategory.petrol,
  insuranceExpiry: _now.add(const Duration(days: 60)),
);

Future<void> _pumpSettings(
  WidgetTester tester,
  FakeReminderScheduler scheduler, {
  ThemeData? theme,
  FakeVehicleRepository? vehicles,
  BackupFilePicker? picker,
  ImportData? import,
}) async {
  await tester.binding.setSurfaceSize(const Size(1200, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          vehicles ?? FakeVehicleRepository([_activa]),
        ),
        if (picker != null) backupFilePickerProvider.overrideWithValue(picker),
        if (import != null) importDataProvider.overrideWithValue(import),
        refuelRepositoryProvider.overrideWithValue(FakeRefuelRepository()),
        serviceLogRepositoryProvider.overrideWithValue(
          FakeServiceLogRepository([
            ServiceLogEntry(
              id: 1,
              vehicleId: _activa.id,
              template: ServiceTemplate.generalService,
              performedAt: _now.subtract(const Duration(days: 10)),
              odometer: 5000,
            ),
          ]),
        ),
        odometerReadingRepositoryProvider.overrideWithValue(
          FakeOdometerReadingRepository(),
        ),
        reminderSchedulerProvider.overrideWithValue(scheduler),
      ],
      child: MaterialApp.router(theme: theme, routerConfig: _settingsRouter()),
    ),
  );
  await tester.pumpAndSettle();
}

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
      ProviderScope(
        overrides: [
          vehicleRepositoryProvider.overrideWithValue(FakeVehicleRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
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
            vehicleRepositoryProvider.overrideWithValue(
              FakeVehicleRepository(),
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
          vehicleRepositoryProvider.overrideWithValue(FakeVehicleRepository()),
        ],
        child: MaterialApp.router(routerConfig: _settingsRouter()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('survives an uninstall'), findsOneWidget);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Automatic backup'));
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

  testWidgets('the reminders section lists what is scheduled', (tester) async {
    await _pumpSettings(tester, FakeReminderScheduler(enabled: true));

    expect(find.text('Document reminders'), findsOneWidget);
    expect(find.text('Service reminders'), findsOneWidget);
    expect(find.text('Insurance expiry, Activa'), findsOneWidget);
    expect(find.textContaining('then 3 more'), findsOneWidget);
    expect(find.text('General service, Activa'), findsOneWidget);
    expect(find.text('Nothing scheduled'), findsNothing);
  });

  testWidgets('turning off document reminders hides and persists', (
    tester,
  ) async {
    await _pumpSettings(tester, FakeReminderScheduler(enabled: true));

    await tester.tap(find.widgetWithText(SwitchListTile, 'Document reminders'));
    await tester.pumpAndSettle();

    expect(find.text('Insurance expiry, Activa'), findsNothing);
    expect(find.text('General service, Activa'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings.documentReminders'), isFalse);
  });

  testWidgets('the test row sends one reminder and confirms it', (
    tester,
  ) async {
    final scheduler = FakeReminderScheduler(enabled: true);
    await _pumpSettings(tester, scheduler);

    await tester.tap(find.widgetWithText(ListTile, 'Send a test reminder'));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequested, isTrue);
    expect(scheduler.shownTest, isTrue);
    expect(find.text('Test reminder sent'), findsOneWidget);
  });

  testWidgets('the blocked line shows only when notifications are off', (
    tester,
  ) async {
    const blocked = 'Notifications are off for OdoLog in Android settings';

    await _pumpSettings(tester, FakeReminderScheduler(enabled: false));
    expect(find.text(blocked), findsOneWidget);

    await _pumpSettings(tester, FakeReminderScheduler(enabled: true));
    expect(find.text(blocked), findsNothing);

    await _pumpSettings(tester, FakeReminderScheduler());
    expect(find.text(blocked), findsNothing);
  });

  testWidgets('opening Settings with the app theme raises no ink assertion', (
    tester,
  ) async {
    await _pumpSettings(tester, FakeReminderScheduler(), theme: AppTheme.light);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'an unreadable import file shows the failure and frees the rows',
    (tester) async {
      final vehicles = FakeVehicleRepository([_activa]);
      await _pumpSettings(
        tester,
        FakeReminderScheduler(),
        vehicles: vehicles,
        picker: () async => UnreadableFile(),
      );

      await tester.tap(find.text('Import data'));
      await tester.pumpAndSettle();

      expect(find.text('Could not import your data.'), findsOneWidget);
      expect(find.text('Check the file and try again.'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      for (final row in [
        'Export data',
        'Import data',
        'Download template',
        'Download template with your vehicles',
      ]) {
        final tile = tester.widget<ListTile>(
          find.widgetWithText(ListTile, row),
        );
        expect(tile.enabled, isTrue, reason: row);
      }
      expect(vehicles.vehicles, [_activa]);
    },
  );

  testWidgets('the Import data row shows a spinner until the summary shows', (
    tester,
  ) async {
    final import = HeldImport();
    await _pumpSettings(
      tester,
      FakeReminderScheduler(),
      picker: () async => XFile.fromData(utf8.encode('{}'), name: 'b.json'),
      import: import,
    );
    final spinner = find.descendant(
      of: find.widgetWithText(ListTile, 'Import data'),
      matching: find.byType(CircularProgressIndicator),
    );
    expect(spinner, findsNothing);

    await tester.tap(find.text('Import data'));
    await tester.pump();
    expect(spinner, findsOneWidget);

    import.result.complete(
      right((
        vehicles: const <Vehicle>[],
        entries: const [],
        serviceLog: const [],
        expenses: const [],
        odometerReadings: const [],
      )),
    );
    await tester.pump();
    expect(spinner, findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}

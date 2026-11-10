import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/failures.dart';
import 'package:odolog/presentation/onboarding/onboarding_screen.dart';
import 'package:odolog/presentation/providers/backup_file_picker.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:odolog/presentation/providers/usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_vehicle_repository.dart';
import '../helpers/held_import.dart';
import '../helpers/unreadable_file.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'an unreadable restore file shows the failure and frees the button',
    (tester) async {
      const restore = 'Been here before? Restore a backup';
      final vehicles = FakeVehicleRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleRepositoryProvider.overrideWithValue(vehicles),
            backupFilePickerProvider.overrideWithValue(
              () async => UnreadableFile(),
            ),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(restore));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not restore: Check the file and try again.'),
        findsOneWidget,
      );
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, restore),
      );
      expect(button.onPressed, isNotNull);
      expect(vehicles.vehicles, isEmpty);
    },
  );

  testWidgets('the restore button shows a spinner until the failure shows', (
    tester,
  ) async {
    final import = HeldImport();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleRepositoryProvider.overrideWithValue(FakeVehicleRepository()),
          backupFilePickerProvider.overrideWithValue(
            () async => XFile.fromData(utf8.encode('{}'), name: 'b.json'),
          ),
          importDataProvider.overrideWithValue(import),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final spinner = find.descendant(
      of: find.byType(TextButton),
      matching: find.byType(CircularProgressIndicator),
    );
    expect(spinner, findsNothing);

    await tester.tap(find.text('Been here before? Restore a backup'));
    await tester.pump();
    expect(spinner, findsOneWidget);

    import.result.complete(
      left(const ValidationFailure(field: 'file', reason: 'Not a backup.')),
    );
    await tester.pump();
    expect(spinner, findsNothing);
    expect(find.text('Could not restore: Not a backup.'), findsOneWidget);
  });
}

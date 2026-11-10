import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/presentation/onboarding/onboarding_screen.dart';
import 'package:odolog/presentation/providers/backup_file_picker.dart';
import 'package:odolog/presentation/providers/repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_vehicle_repository.dart';
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
}

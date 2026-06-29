import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/failures.dart';
import '../providers/app_providers.dart';
import '../providers/usecases.dart';
import '../vehicles/vehicle_form.dart';

/// First launch lands here: add your first vehicle. No sign up, no tour. Once a
/// vehicle is saved the app moves to the home dashboard for it.
///
/// Restoring a backup lives here too, not only in Settings, because after a
/// reinstall this screen is the wall between the user and their data: Settings
/// is unreachable until a vehicle exists, and creating a throwaway vehicle
/// first would take the id the backup's own first vehicle needs. Importing
/// from here lands on an empty database, where the backup's ids always fit.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to OdoLog',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first vehicle to start logging fills.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  TextButton(
                    onPressed: _busy ? null : _restoreBackup,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('Been here before? Restore a backup'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: VehicleForm(
                saveLabel: 'Save vehicle',
                onSaved: (saved) {
                  ref.read(activeVehicleIdProvider.notifier).select(saved.id);
                  if (context.mounted) context.go('/');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreBackup() async {
    setState(() => _busy = true);
    final picked = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'OdoLog backup', extensions: ['json', 'csv']),
      ],
    );
    if (picked == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final content = await picked.readAsString();
    final result = await ref.read(importDataProvider).execute(content);
    if (!mounted) return;
    result.match(
      (failure) {
        setState(() => _busy = false);
        final reason = failure is ValidationFailure
            ? failure.reason
            : 'Check the file and try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not restore: $reason')));
      },
      (bundle) {
        ref.invalidate(vehicleListProvider);
        if (bundle.vehicles.isNotEmpty) {
          ref
              .read(activeVehicleIdProvider.notifier)
              .select(bundle.vehicles.first.id);
        }
        if (context.mounted) context.go('/');
      },
    );
  }
}

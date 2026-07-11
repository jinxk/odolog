import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../vehicles/vehicle_form.dart';

/// First launch lands here: add your first vehicle. No sign up, no tour. Once a
/// vehicle is saved the app moves to the home dashboard for it.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
}

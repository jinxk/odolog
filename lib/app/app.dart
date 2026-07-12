import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/providers/app_providers.dart';
import '../presentation/providers/settings_provider.dart';
import 'router.dart';
import 'theme/theme.dart';

/// The root widget: MaterialApp.router wired to the light and dark themes and
/// the single app router. The theme mode follows the persisted setting, which
/// defaults to the system setting.
class OdoLogApp extends ConsumerWidget {
  const OdoLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Instantiate the reminder syncs so they stay alive for the app's
    // lifetime: they reschedule document and service reminders on start and
    // after any vehicle edit.
    ref.watch(documentReminderSyncProvider);
    ref.watch(serviceReminderSyncProvider);
    final themeMode =
        ref.watch(settingsProvider).value?.themeMode ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'OdoLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'reminder_nudge_provider.g.dart';

const _dismissedKey = 'reminders.batteryNudgeDismissed';

/// Whether the user has dismissed the battery-optimization nudge. Persisted in
/// shared_preferences so the one-time card does not return on the next launch.
/// Kept off the database, like the other UI preferences.
@Riverpod(keepAlive: true)
class ReminderNudgeDismissed extends _$ReminderNudgeDismissed {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dismissedKey) ?? false;
  }

  /// Records that the nudge was dismissed and hides it for good.
  Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
    state = const AsyncData(true);
  }
}

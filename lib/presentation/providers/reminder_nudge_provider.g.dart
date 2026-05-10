// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_nudge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the user has dismissed the battery-optimization nudge. Persisted in
/// shared_preferences so the one-time card does not return on the next launch.
/// Kept off the database, like the other UI preferences.

@ProviderFor(ReminderNudgeDismissed)
final reminderNudgeDismissedProvider = ReminderNudgeDismissedProvider._();

/// Whether the user has dismissed the battery-optimization nudge. Persisted in
/// shared_preferences so the one-time card does not return on the next launch.
/// Kept off the database, like the other UI preferences.
final class ReminderNudgeDismissedProvider
    extends $AsyncNotifierProvider<ReminderNudgeDismissed, bool> {
  /// Whether the user has dismissed the battery-optimization nudge. Persisted in
  /// shared_preferences so the one-time card does not return on the next launch.
  /// Kept off the database, like the other UI preferences.
  ReminderNudgeDismissedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reminderNudgeDismissedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reminderNudgeDismissedHash();

  @$internal
  @override
  ReminderNudgeDismissed create() => ReminderNudgeDismissed();
}

String _$reminderNudgeDismissedHash() =>
    r'89ab798b0527edbff52e92ce2bd7884a34826f3a';

/// Whether the user has dismissed the battery-optimization nudge. Persisted in
/// shared_preferences so the one-time card does not return on the next launch.
/// Kept off the database, like the other UI preferences.

abstract class _$ReminderNudgeDismissed extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

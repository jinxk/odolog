// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auto_backup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Coordinates the automatic backup: it owns the on/off preference and the one
/// time consent, and it holds the once a day debounce so a backup runs at most
/// once per calendar day no matter how many writes trigger it. Kept alive for
/// the app's lifetime. Every screen that completes a data write calls
/// [runIfDue], which is the single place the debounce and the write live; the
/// screens themselves carry no backup logic.

@ProviderFor(AutoBackup)
final autoBackupProvider = AutoBackupProvider._();

/// Coordinates the automatic backup: it owns the on/off preference and the one
/// time consent, and it holds the once a day debounce so a backup runs at most
/// once per calendar day no matter how many writes trigger it. Kept alive for
/// the app's lifetime. Every screen that completes a data write calls
/// [runIfDue], which is the single place the debounce and the write live; the
/// screens themselves carry no backup logic.
final class AutoBackupProvider
    extends $AsyncNotifierProvider<AutoBackup, AutoBackupState> {
  /// Coordinates the automatic backup: it owns the on/off preference and the one
  /// time consent, and it holds the once a day debounce so a backup runs at most
  /// once per calendar day no matter how many writes trigger it. Kept alive for
  /// the app's lifetime. Every screen that completes a data write calls
  /// [runIfDue], which is the single place the debounce and the write live; the
  /// screens themselves carry no backup logic.
  AutoBackupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoBackupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoBackupHash();

  @$internal
  @override
  AutoBackup create() => AutoBackup();
}

String _$autoBackupHash() => r'5a3684cc2c9b72577857ef65d44dccf4ed8e6dae';

/// Coordinates the automatic backup: it owns the on/off preference and the one
/// time consent, and it holds the once a day debounce so a backup runs at most
/// once per calendar day no matter how many writes trigger it. Kept alive for
/// the app's lifetime. Every screen that completes a data write calls
/// [runIfDue], which is the single place the debounce and the write live; the
/// screens themselves carry no backup logic.

abstract class _$AutoBackup extends $AsyncNotifier<AutoBackupState> {
  FutureOr<AutoBackupState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AutoBackupState>, AutoBackupState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AutoBackupState>, AutoBackupState>,
              AsyncValue<AutoBackupState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

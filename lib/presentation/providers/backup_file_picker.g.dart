// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_file_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backupFilePicker)
final backupFilePickerProvider = BackupFilePickerProvider._();

final class BackupFilePickerProvider
    extends
        $FunctionalProvider<
          BackupFilePicker,
          BackupFilePicker,
          BackupFilePicker
        >
    with $Provider<BackupFilePicker> {
  BackupFilePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupFilePickerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupFilePickerHash();

  @$internal
  @override
  $ProviderElement<BackupFilePicker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupFilePicker create(Ref ref) {
    return backupFilePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupFilePicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupFilePicker>(value),
    );
  }
}

String _$backupFilePickerHash() => r'6880f851c266cd98f23cc101bb5ff0fd1762cbff';

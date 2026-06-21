import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/failures.dart';
import '../../core/typedefs.dart';
import '../../domain/backup/auto_backup_writer.dart';

/// [AutoBackupWriter] over a MethodChannel into the Android host, which writes
/// to the shared Downloads collection under Download/OdoLog through MediaStore.
/// Files there outlive the app's own storage, so a backup survives an uninstall
/// or a sideloaded update. Every channel call is wrapped: a missing channel
/// (any non Android host, or a unit test) and a platform error both come back
/// as a Failure, and [isAvailable] resolves to false rather than throwing, so
/// the feature simply disables itself where it cannot run.
class MediaStoreAutoBackupWriter implements AutoBackupWriter {
  const MediaStoreAutoBackupWriter();

  static const _channel = MethodChannel('com.jinxk.odolog/auto_backup');

  @override
  Future<Result<bool>> isAvailable() async {
    try {
      final available = await _channel.invokeMethod<bool>('isAvailable');
      return right(available ?? false);
    } on MissingPluginException {
      return right(false);
    } on PlatformException catch (e) {
      return left(DatabaseFailure(e.message ?? 'Backup storage unavailable.'));
    }
  }

  @override
  Future<Result<Unit>> write(String fileName, String content) async {
    try {
      await _channel.invokeMethod<void>('write', {
        'fileName': fileName,
        'content': content,
      });
      return right(unit);
    } on MissingPluginException {
      return left(const DatabaseFailure('Backup storage unavailable.'));
    } on PlatformException catch (e) {
      return left(DatabaseFailure(e.message ?? 'Could not write the backup.'));
    }
  }

  @override
  Future<Result<List<String>>> list() async {
    try {
      final names = await _channel.invokeListMethod<String>('list');
      return right(names ?? const []);
    } on MissingPluginException {
      return left(const DatabaseFailure('Backup storage unavailable.'));
    } on PlatformException catch (e) {
      return left(DatabaseFailure(e.message ?? 'Could not read the backups.'));
    }
  }

  @override
  Future<Result<Unit>> delete(String fileName) async {
    try {
      await _channel.invokeMethod<void>('delete', {'fileName': fileName});
      return right(unit);
    } on MissingPluginException {
      return left(const DatabaseFailure('Backup storage unavailable.'));
    } on PlatformException catch (e) {
      return left(DatabaseFailure(e.message ?? 'Could not delete a backup.'));
    }
  }
}

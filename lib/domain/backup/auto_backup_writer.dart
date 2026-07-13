import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';

/// Port for writing backup files to storage that outlives the app's own data
/// directory, so a backup survives an uninstall or a sideloaded update. The
/// domain decides what a backup holds and when to take one; an outer layer
/// decides where the bytes land. On Android that is the shared Downloads
/// collection. A platform that cannot offer uninstall surviving storage reports
/// itself unavailable through [isAvailable] and the feature stands down.
abstract interface class AutoBackupWriter {
  /// Whether this platform can write backups that outlive the app. False below
  /// the supported Android version and off Android entirely.
  Future<Result<bool>> isAvailable();

  /// Writes [content] under [fileName], replacing any existing file with the
  /// same name so a second backup on the same day overwrites the first.
  Future<Result<Unit>> write(String fileName, String content);

  /// The names of the backup files this app has written to the shared folder,
  /// used to prune the rolling set. After a reinstall the app may no longer see
  /// or own files from a previous install, so those simply do not appear here.
  Future<Result<List<String>>> list();

  /// Deletes the backup file named [fileName]. A file the app no longer owns
  /// cannot be removed, which comes back as a Failure the caller can ignore.
  Future<Result<Unit>> delete(String fileName);
}

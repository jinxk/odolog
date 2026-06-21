import 'package:fpdart/fpdart.dart';

import '../../core/typedefs.dart';
import '../backup/auto_backup_policy.dart';
import '../backup/auto_backup_writer.dart';
import 'export_data.dart';

/// Writes one automatic backup: it asks [ExportData] for the same JSON bundle
/// the manual export produces, writes it under today's file name through
/// [AutoBackupWriter], then prunes the shared folder back to the newest few
/// daily files. Every step returns through [Result]. The pruning is best effort
/// and never fails a backup that already wrote; the caller decides whether a
/// write failure is worth surfacing, and the auto backup path swallows it.
class RunAutoBackup {
  const RunAutoBackup(this._exportData, this._writer);

  final ExportData _exportData;
  final AutoBackupWriter _writer;

  Future<Result<Unit>> execute({required DateTime now}) async {
    final exported = await _exportData.execute();
    return exported.match(
      (failure) => Future<Result<Unit>>.value(left(failure)),
      (content) async {
        final written = await _writer.write(
          AutoBackupPolicy.fileName(now),
          content,
        );
        final writeFailure = written.getLeft().toNullable();
        if (writeFailure != null) return left(writeFailure);
        await _prune();
        return right(unit);
      },
    );
  }

  /// Deletes backups beyond the newest [AutoBackupPolicy.keep]. A listing or a
  /// delete that fails leaves the extra files in place rather than turning a
  /// backup that already landed into a failure.
  Future<void> _prune() async {
    final listed = await _writer.list();
    final names = listed.getRight().toNullable();
    if (names == null) return;
    for (final name in AutoBackupPolicy.stale(names, AutoBackupPolicy.keep)) {
      await _writer.delete(name);
    }
  }
}

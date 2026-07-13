import 'package:fpdart/fpdart.dart';
import 'package:odolog/core/typedefs.dart';
import 'package:odolog/domain/backup/auto_backup_writer.dart';

/// In-memory [AutoBackupWriter] for tests. Records what it was asked to write
/// and delete, and keeps a set of file names so the rolling cleanup can be
/// exercised without a platform channel.
class FakeAutoBackupWriter implements AutoBackupWriter {
  FakeAutoBackupWriter({this.available = true, List<String>? existing}) {
    if (existing != null) _files.addAll(existing);
  }

  final bool available;
  final List<String> _files = [];
  final List<({String name, String content})> writes = [];
  final List<String> deleted = [];

  List<String> get files => List.unmodifiable(_files);

  @override
  Future<Result<bool>> isAvailable() async => right(available);

  @override
  Future<Result<Unit>> write(String fileName, String content) async {
    writes.add((name: fileName, content: content));
    _files
      ..removeWhere((f) => f == fileName)
      ..add(fileName);
    return right(unit);
  }

  @override
  Future<Result<List<String>>> list() async => right(List.of(_files));

  @override
  Future<Result<Unit>> delete(String fileName) async {
    deleted.add(fileName);
    _files.remove(fileName);
    return right(unit);
  }
}

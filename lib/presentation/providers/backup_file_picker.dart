import 'package:file_selector/file_selector.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_file_picker.g.dart';

/// Opens the system picker for a backup file. Completes with null when the
/// user cancels.
typedef BackupFilePicker = Future<XFile?> Function();

// CSV stays accepted so a backup exported before the JSON format still
// restores; the codec sniffs the content and picks the right reader.
@Riverpod(keepAlive: true)
BackupFilePicker backupFilePicker(Ref ref) =>
    () => openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'OdoLog backup', extensions: ['json', 'csv']),
      ],
    );

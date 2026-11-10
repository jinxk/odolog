import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

/// A picked file that cannot be read as text, the way a photo renamed .json
/// fails on a phone: dart:io throws while decoding it as UTF-8.
class UnreadableFile extends XFile {
  UnreadableFile() : super('photo.json');

  @override
  Future<String> readAsString({Encoding encoding = utf8}) => Future.error(
    const FileSystemException("Failed to decode data using encoding 'utf-8'"),
  );
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/app/version.dart';

/// Reads pubspec.yaml straight off disk (tests run from the repo root) and
/// checks its version line still starts with [appVersion], so the two can
/// never quietly drift apart the way the hardcoded About string once did.
void main() {
  test('appVersion matches the version in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final versionLine = pubspec
        .split('\n')
        .firstWhere((line) => line.startsWith('version:'));
    expect(versionLine, startsWith('version: $appVersion'));
  });
}

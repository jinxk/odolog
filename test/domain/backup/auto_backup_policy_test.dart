import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/backup/auto_backup_policy.dart';

void main() {
  group('dayStamp', () {
    test('is one stable key for a whole calendar day', () {
      final morning = DateTime(2020, 1, 2, 6, 30);
      final night = DateTime(2020, 1, 2, 23, 59);
      expect(AutoBackupPolicy.dayStamp(morning), hasLength(8));
      expect(
        AutoBackupPolicy.dayStamp(morning),
        AutoBackupPolicy.dayStamp(night),
      );
    });

    test('zero pads month and day to YYYYMMDD', () {
      expect(AutoBackupPolicy.dayStamp(DateTime(2026, 3, 5)), '20260305');
    });
  });

  group('fileName', () {
    test('carries the day stamp and the json extension', () {
      final now = DateTime.now();
      final name = AutoBackupPolicy.fileName(now);
      expect(name, startsWith('odolog_auto_'));
      expect(name, endsWith('.json'));
      expect(name, contains(AutoBackupPolicy.dayStamp(now)));
    });
  });

  group('isDue', () {
    test('not due when the last backup is from today', () {
      final now = DateTime.now();
      expect(
        AutoBackupPolicy.isDue(AutoBackupPolicy.dayStamp(now), now),
        false,
      );
    });

    test('due when the last backup is from a previous day', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      expect(
        AutoBackupPolicy.isDue(AutoBackupPolicy.dayStamp(yesterday), now),
        true,
      );
    });

    test('due when nothing was ever backed up', () {
      expect(AutoBackupPolicy.isDue(null, DateTime.now()), true);
    });
  });

  group('stale', () {
    test('keeps the newest N and returns the rest oldest first', () {
      final names = [
        'odolog_auto_20260103.json',
        'odolog_auto_20260101.json',
        'odolog_auto_20260102.json',
      ];
      expect(AutoBackupPolicy.stale(names, 2), ['odolog_auto_20260101.json']);
    });

    test('returns nothing when at or under the limit', () {
      expect(AutoBackupPolicy.stale(['odolog_auto_20260101.json'], 7), isEmpty);
    });

    test('ignores files that are not auto backups', () {
      final names = [
        'manual_backup.json',
        'odolog_auto_20260101.json',
        'notes.txt',
      ];
      expect(AutoBackupPolicy.stale(names, 7), isEmpty);
    });
  });
}

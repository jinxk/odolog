/// Naming and retention rules for automatic backups, kept as pure functions so
/// the debounce and the rolling cleanup can be unit tested without a platform
/// channel. Backups are keyed by calendar day: a second backup on the same day
/// reuses the same file name and so replaces the first, and the rolling set
/// holds at most one file per day.
abstract final class AutoBackupPolicy {
  static const filePrefix = 'odolog_auto_';
  static const fileExtension = '.json';

  /// How many daily backups to keep before the oldest is pruned.
  static const keep = 7;

  /// The YYYYMMDD stamp for [date], the key both the file name and the once a
  /// day debounce are built on.
  static String dayStamp(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  /// The backup file name for [date], for example odolog_auto_20260713.json.
  static String fileName(DateTime date) =>
      '$filePrefix${dayStamp(date)}$fileExtension';

  /// True when the last backup, taken on [lastStamp], does not cover the day of
  /// [now], so a fresh one is due. A null [lastStamp] means none was ever taken.
  static bool isDue(String? lastStamp, DateTime now) =>
      lastStamp != dayStamp(now);

  /// The names to delete so only the newest [keep] daily backups remain. Names
  /// that do not match the auto backup pattern are left alone. Sorting is
  /// lexicographic, which for the zero padded YYYYMMDD stamp is the same as
  /// chronological, so the front of the sorted list is the oldest.
  static List<String> stale(Iterable<String> names, int keep) {
    final ours =
        names
            .where((n) => n.startsWith(filePrefix) && n.endsWith(fileExtension))
            .toList()
          ..sort();
    if (ours.length <= keep) return const [];
    return ours.sublist(0, ours.length - keep);
  }
}

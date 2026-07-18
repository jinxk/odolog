/// The app version shown on Settings > About. This is the single source of
/// truth for that display string; it must be kept in step with the
/// `version:` line in `pubspec.yaml` by hand, since Flutter has no built in
/// way to read the manifest at runtime without an extra dependency.
/// `test/app/version_test.dart` checks the two still agree, so a forgotten
/// bump fails the test suite instead of shipping a stale number.
const appVersion = '1.1.0';

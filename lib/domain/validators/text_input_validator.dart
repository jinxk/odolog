/// Backs up the input formatters on free text fields (vehicle name,
/// registration, station name, notes). Every exported field is quoted CSV, so
/// a literal quote mark forces doubling and a line break spans physical
/// lines; rejecting both at entry keeps a field a single quoted token with no
/// escaping decisions left for the writer to make.
class TextInputValidator {
  const TextInputValidator._();

  /// Null when [value] is clean, otherwise the reason to report against the
  /// field it came from.
  static String? check(String value) {
    if (value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return 'Cannot contain a quote mark or a line break.';
    }
    return null;
  }
}

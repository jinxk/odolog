/// Spacing scale for OdoLog, on a 4pt base grid. Layout code reads these names
/// instead of hardcoding numbers so the rhythm stays consistent across screens
/// and can be tuned in one place. All values are logical pixels.
abstract final class AppSpacing {
  /// Horizontal padding from the screen edge to its content.
  static const double screenH = 20;

  /// Interior padding for a standard card.
  static const double cardPadding = 20;

  /// Interior padding for the hero card, a touch more generous so the large
  /// numeral has room to breathe.
  static const double heroPadding = 24;

  /// Gap between a section header and the content it introduces.
  static const double headerToContent = 12;

  /// Gap between two stacked sections.
  static const double betweenSections = 28;

  /// Gap between rows inside a single card.
  static const double rowGap = 16;
}

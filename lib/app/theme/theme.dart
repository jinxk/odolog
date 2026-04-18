import 'package:flutter/material.dart';

import 'colors.dart';
import 'shapes.dart';

/// Light and dark [ThemeData] built on Material 3. Hierarchy comes from large
/// jumps in size and weight, not from uniformly medium text, so a screen has a
/// clear focal point when read at arm's length in glare. Both themes are wired
/// as first class citizens following the system setting.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.surface,
    onBackground: AppColors.ink,
    card: AppColors.surfaceMuted,
    depth: AppDepth.light,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.black,
    onBackground: AppColors.offWhite,
    card: AppColors.surfaceDark,
    depth: AppDepth.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color onBackground,
    required Color card,
    required AppDepth depth,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.amber,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.amber,
          onPrimary: AppColors.ink,
          secondary: AppColors.teal,
          error: AppColors.error,
          surface: background,
          onSurface: onBackground,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
    );

    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme, onBackground),
      extensions: [depth, AppColorRoles.of(onBackground, brightness)],
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: AppShapes.cardBorder,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppShapes.inputRadius),
        ),
        filled: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.ink,
          shape: AppShapes.buttonBorder,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// The OdoLog type scale mapped onto Material's [TextTheme] slots. Numeric
  /// styles turn on tabular figures so columns of numbers hold their width as
  /// values change, the engineered feel a fuel log wants. The two display slots
  /// use InterDisplay, Inter's optical cut for large sizes.
  static TextTheme _buildTextTheme(TextTheme base, Color onSurface) {
    const tabular = [FontFeature.tabularFigures()];
    final secondary = onSurface.withValues(alpha: AppColors.textSecondaryAlpha);
    final tertiary = onSurface.withValues(alpha: AppColors.textTertiaryAlpha);

    return base.copyWith(
      // Hero numeral: dashboard mileage, stats lead figure.
      displayLarge: base.displayLarge?.copyWith(
        fontFamily: 'InterDisplay',
        fontSize: 56,
        fontWeight: FontWeight.w700,
        letterSpacing: -2,
        height: 1,
        color: onSurface,
        fontFeatures: tabular,
      ),
      // Secondary numeral: cost per km, per month values.
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: 'InterDisplay',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: onSurface,
        fontFeatures: tabular,
      ),
      // Large title: per screen header.
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      // Section title, sentence case.
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: onSurface,
      ),
      // Stat value.
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurface,
        fontFeatures: tabular,
      ),
      // Body: descriptions, list subtitles.
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      // Label or overline: stat labels, metadata.
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: secondary,
      ),
      // Caption: footnotes.
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: tertiary,
      ),
    );
  }
}

/// The oversized numeral style for a hero figure, sized for arm's length
/// reading. Colour is set by the caller so it reads on ink or on amber. Matches
/// the `displayLarge` slot but exists as a standalone constant for callers that
/// paint the numeral over the ink hero card. Tabular so the figure does not
/// reflow as it counts up.
const heroNumberStyle = TextStyle(
  fontFamily: 'InterDisplay',
  fontSize: 56,
  fontWeight: FontWeight.w700,
  letterSpacing: -2,
  height: 1,
  fontFeatures: [FontFeature.tabularFigures()],
);

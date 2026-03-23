import 'package:flutter/material.dart';

import 'colors.dart';

/// Light and dark [ThemeData] built on Material 3. The hero numeral styles are
/// large and bold because they are read at arm's length in glare, and both
/// themes are wired as first class citizens following the system setting.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.surface,
    onBackground: AppColors.ink,
    card: AppColors.surfaceMuted,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.black,
    onBackground: AppColors.offWhite,
    card: AppColors.surfaceDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color onBackground,
    required Color card,
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
    );

    return base.copyWith(
      textTheme: _heroTextTheme(base.textTheme, onBackground),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.ink,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// The base text theme extended with the large bold numeral styles used for
  /// hero numbers. `heroNumber` is the headline figure on the dashboard card,
  /// `heroUnit` the small unit that rides beside it.
  static TextTheme _heroTextTheme(TextTheme base, Color onBackground) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: onBackground,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: onBackground,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: onBackground,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: onBackground,
      ),
    );
  }
}

/// The oversized numeral style for a hero figure, sized for arm's length
/// reading. Colour is set by the caller so it reads on ink or on amber.
const heroNumberStyle = TextStyle(
  fontSize: 44,
  fontWeight: FontWeight.w800,
  letterSpacing: -1.5,
  height: 1.05,
);

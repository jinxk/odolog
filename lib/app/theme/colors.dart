import 'package:flutter/material.dart';

/// Palette tokens for OdoLog. The names and values match the Theme and palette
/// section of docs/design.md exactly. The app gets used outdoors, so contrast
/// comes first: body text never drops to a soft grey, and nothing meaningful is
/// carried by colour alone.
abstract final class AppColors {
  /// Near black ink for text on the light surface. Maximum contrast in glare.
  static const ink = Color(0xFF101418);

  /// Near white surface behind the light theme.
  static const surface = Color(0xFFFAFAF7);

  /// True black background for the dark theme. Clean on OLED at night.
  static const black = Color(0xFF000000);

  /// Off white text on the true black dark background.
  static const offWhite = Color(0xFFF2F2EC);

  /// The single accent: a vivid, high visibility amber for the hero numbers,
  /// the add refuel action, and selection states.
  static const amber = Color(0xFFFFB300);

  /// Deep teal for secondary structure: chips, links, and the trend line, so
  /// amber keeps its meaning as the number and the action.
  static const teal = Color(0xFF00695C);

  /// A brighter teal for the same structural role on the dark theme, where the
  /// deep [teal] clears only 2.69:1 on a dark card. This reads about 5.9:1 on
  /// the dark card, above the 4.5:1 needed to stay legible in glare.
  static const tealBright = Color(0xFF26A69A);

  /// Saturated error red for hard form validation only, never for trend or
  /// budget signals. On the dark theme it clears only 4.22:1 on black, which is
  /// marginal in glare, so negative semantic figures use [negativeDark] instead.
  static const error = Color(0xFFD32F2F);

  /// A muted surface for cards on the light theme.
  static const surfaceMuted = Color(0xFFEFEFE9);

  /// A raised surface for cards on the true black dark theme.
  static const surfaceDark = Color(0xFF15181C);

  // Neutral text ramp. Applied as an alpha over the theme's onSurface colour so
  // one set of levels works on both the light ink and the dark off white. Text
  // primary is onSurface at full strength; the levels below are the formal
  // replacement for ad hoc withValues() calls scattered through widgets.

  /// Secondary text: labels and list subtitles. onSurface at 0.60.
  static const double textSecondaryAlpha = 0.60;

  /// Tertiary text: captions and footnotes. onSurface at 0.38.
  static const double textTertiaryAlpha = 0.38;

  /// Hairline strokes and faint fills. onSurface at 0.08.
  static const double hairlineAlpha = 0.08;

  // Semantic pair for valenced figures: mileage trend, budget deltas. Meaning
  // is never carried by colour alone, so every use pairs these with a glyph
  // (up or down arrow) and a sign. Each value clears WCAG AAA large text
  // (4.5:1) with headroom on every surface it lands on, so it holds up in
  // sunlight. Amber is identity, not valence, and stays out of this pair.

  /// Positive (efficient, under budget) on the light theme. 6.17:1 on surface,
  /// 5.59:1 on a card. Beats the common Material green for outdoor legibility.
  static const positiveLight = Color(0xFF146C43);

  /// Positive on the dark theme. 11.77:1 on black, 10.37:1 on the hero card.
  static const positiveDark = Color(0xFF3DDC84);

  /// Negative (worse, over budget) on the light theme. 6.25:1 on surface,
  /// 5.66:1 on a card.
  static const negativeLight = Color(0xFFB3261E);

  /// Negative on the dark theme. 8.27:1 on black, 7.28:1 on the hero card. Used
  /// in place of [error], which is too dim on black for a glanceable signal.
  static const negativeDark = Color(0xFFFF7A70);
}

/// Theme resolved colour roles, read through
/// `Theme.of(context).extension<AppColorRoles>()`.
///
/// Formalizes the neutral text ramp and the good/bad semantic pair so widgets
/// stop hardcoding alphas and hex values. The values flip with brightness, so
/// resolving them once here keeps every screen consistent in both themes.
@immutable
class AppColorRoles extends ThemeExtension<AppColorRoles> {
  const AppColorRoles({
    required this.textSecondary,
    required this.textTertiary,
    required this.hairline,
    required this.positive,
    required this.negative,
  });

  /// Builds the roles for a theme from its [onSurface] colour and [brightness].
  factory AppColorRoles.of(Color onSurface, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return AppColorRoles(
      textSecondary: onSurface.withValues(alpha: AppColors.textSecondaryAlpha),
      textTertiary: onSurface.withValues(alpha: AppColors.textTertiaryAlpha),
      hairline: onSurface.withValues(alpha: AppColors.hairlineAlpha),
      positive: isDark ? AppColors.positiveDark : AppColors.positiveLight,
      negative: isDark ? AppColors.negativeDark : AppColors.negativeLight,
    );
  }

  /// Secondary text colour: onSurface at [AppColors.textSecondaryAlpha].
  final Color textSecondary;

  /// Tertiary text colour: onSurface at [AppColors.textTertiaryAlpha].
  final Color textTertiary;

  /// Hairline stroke colour: onSurface at [AppColors.hairlineAlpha].
  final Color hairline;

  /// Positive semantic colour for this theme.
  final Color positive;

  /// Negative semantic colour for this theme.
  final Color negative;

  @override
  AppColorRoles copyWith({
    Color? textSecondary,
    Color? textTertiary,
    Color? hairline,
    Color? positive,
    Color? negative,
  }) {
    return AppColorRoles(
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      hairline: hairline ?? this.hairline,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
    );
  }

  @override
  AppColorRoles lerp(ThemeExtension<AppColorRoles>? other, double t) {
    if (other is! AppColorRoles) return this;
    return AppColorRoles(
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
    );
  }
}

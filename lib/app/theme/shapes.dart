import 'package:flutter/material.dart';

import 'colors.dart';

/// Shape and depth tokens for OdoLog.
///
/// Cards and buttons use [ContinuousRectangleBorder] (the superellipse
/// "squircle") rather than a plain rounded rectangle. Continuous corners look
/// tighter for a given radius, so the numbers here are roughly 1.6x the
/// circular radius they read as: hero 40 reads about 24, card 32 reads about 20.
/// All radii are logical pixels.
abstract final class AppShapes {
  /// Radius for the hero card, the one floating surface on a screen.
  static const double heroRadius = 40;

  /// Radius for standard cards, which sit flat behind the hero.
  static const double cardRadius = 32;

  /// Radius for buttons.
  static const double buttonRadius = 22;

  /// Radius for text inputs. Plain rounded rect, since [InputBorder] does not
  /// support the continuous shape.
  static const double inputRadius = 16;

  /// Continuous border for the hero card.
  static const ContinuousRectangleBorder heroBorder = ContinuousRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(heroRadius)),
  );

  /// Continuous border for standard cards.
  static const ContinuousRectangleBorder cardBorder = ContinuousRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
  );

  /// Continuous border for buttons.
  static const ContinuousRectangleBorder buttonBorder =
      ContinuousRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(buttonRadius)),
      );

  /// Pill shape for chips.
  static const StadiumBorder chipBorder = StadiumBorder();
}

/// Depth treatment that a plain [ThemeData] cannot express, resolved per
/// brightness and read through `Theme.of(context).extension<AppDepth>()`.
///
/// Figure and ground are separated differently in each theme. In light the hero
/// floats on a soft drop shadow; in dark, where a shadow reads as a smudge on
/// OLED black, it instead gets a hairline top highlight so the eye still sees an
/// edge. Secondary cards never carry the hero's shadow; they recede to a flat
/// fill with an optional hairline in dark.
@immutable
class AppDepth extends ThemeExtension<AppDepth> {
  const AppDepth({
    required this.heroShadow,
    required this.heroTopHighlight,
    required this.cardHairline,
  });

  /// Shadow cast by the hero card. Empty in dark theme.
  final List<BoxShadow> heroShadow;

  /// One pixel highlight along the top edge of surfaces in dark theme, standing
  /// in for the shadow the light theme uses. Null in light theme.
  final Color? heroTopHighlight;

  /// Hairline outline that gives a secondary card an edge against the
  /// background. Null in light theme, where the fill alone separates it.
  final Color? cardHairline;

  /// Light theme depth: hero floats on a soft shadow, secondary cards stay flat.
  static const AppDepth light = AppDepth(
    heroShadow: [
      BoxShadow(
        color: Color(0x2E000000), // black at 0.18 alpha
        blurRadius: 30,
        offset: Offset(0, 12),
      ),
    ],
    heroTopHighlight: null,
    cardHairline: null,
  );

  /// Dark theme depth: no shadow on OLED black, a faint top highlight and card
  /// hairline provide the edge instead.
  static final AppDepth dark = AppDepth(
    heroShadow: const [],
    heroTopHighlight: AppColors.offWhite.withValues(alpha: 0.06),
    cardHairline: AppColors.offWhite.withValues(alpha: 0.06),
  );

  @override
  AppDepth copyWith({
    List<BoxShadow>? heroShadow,
    Color? heroTopHighlight,
    Color? cardHairline,
  }) {
    return AppDepth(
      heroShadow: heroShadow ?? this.heroShadow,
      heroTopHighlight: heroTopHighlight ?? this.heroTopHighlight,
      cardHairline: cardHairline ?? this.cardHairline,
    );
  }

  @override
  AppDepth lerp(ThemeExtension<AppDepth>? other, double t) {
    if (other is! AppDepth) return this;
    return AppDepth(
      heroShadow:
          BoxShadow.lerpList(heroShadow, other.heroShadow, t) ?? const [],
      heroTopHighlight: Color.lerp(heroTopHighlight, other.heroTopHighlight, t),
      cardHairline: Color.lerp(cardHairline, other.cardHairline, t),
    );
  }
}

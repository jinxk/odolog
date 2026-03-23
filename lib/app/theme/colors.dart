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

  /// Saturated error red. Signal colours are never pale.
  static const error = Color(0xFFD32F2F);

  /// A muted surface for cards on the light theme.
  static const surfaceMuted = Color(0xFFEFEFE9);

  /// A raised surface for cards on the true black dark theme.
  static const surfaceDark = Color(0xFF15181C);
}

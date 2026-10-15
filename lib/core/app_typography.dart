import 'package:flutter/material.dart';

/// Single source of truth for the type scale. See DESIGN.md §3.
///
/// Display and UI text use **Plus Jakarta Sans**; numerics use
/// **JetBrains Mono** via `context.mono(...)`. Both are bundled as assets
/// (see pubspec `fonts:`), so there is no runtime fetch and no font swap.
///
/// Role           size / weight   typical use
/// displayLarge   48 / w800       hero numbers, splash wordmark
/// displayMedium  40 / w800
/// displaySmall   36 / w800
/// headlineLarge  32 / w800       login title
/// headlineMedium 28 / w700       page titles
/// headlineSmall  24 / w700       section headers
/// titleLarge     20 / w700       card titles
/// titleMedium    18 / w700       app bar & dialog titles
/// titleSmall     16 / w600       list item titles
/// bodyLarge      16 / w400       primary reading text
/// bodyMedium     14 / w400       default body
/// bodySmall      13 / w400       secondary body, captions (muted color)
/// labelLarge     14 / w600       buttons
/// labelMedium    12 / w600       chips, badges, nav labels
/// labelSmall     11 / w500       overlines, timestamps (muted color)
abstract final class AppTypography {
  static const String family = 'PlusJakartaSans';
  static const String monoFamily = 'JetBrainsMono';

  static TextTheme textTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
  }) {
    TextStyle s(
      double size,
      FontWeight weight, {
      double height = 1.3,
      double letterSpacing = 0,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? primary,
        decoration: TextDecoration.none,
      );
    }

    return TextTheme(
      displayLarge: s(48, FontWeight.w800, height: 1.05, letterSpacing: -1.6),
      displayMedium: s(40, FontWeight.w800, height: 1.1, letterSpacing: -1.2),
      displaySmall: s(36, FontWeight.w800, height: 1.12, letterSpacing: -1.0),
      headlineLarge: s(32, FontWeight.w800, height: 1.15, letterSpacing: -0.8),
      headlineMedium: s(28, FontWeight.w700, height: 1.2, letterSpacing: -0.6),
      headlineSmall: s(24, FontWeight.w700, height: 1.25, letterSpacing: -0.4),
      titleLarge: s(20, FontWeight.w700, letterSpacing: -0.3),
      titleMedium: s(18, FontWeight.w700, letterSpacing: -0.2),
      titleSmall: s(16, FontWeight.w600, height: 1.35, letterSpacing: -0.1),
      bodyLarge: s(16, FontWeight.w400, height: 1.5),
      bodyMedium: s(14, FontWeight.w400, height: 1.5),
      bodySmall: s(13, FontWeight.w400, height: 1.45, color: secondary),
      labelLarge: s(14, FontWeight.w600, height: 1.2, letterSpacing: 0.1),
      labelMedium: s(12, FontWeight.w600, height: 1.2, letterSpacing: 0.2),
      labelSmall: s(11, FontWeight.w500, height: 1.2, letterSpacing: 0.5, color: secondary),
    );
  }

  /// Monospace numeric style. Prefer `context.mono(...)`.
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    required Color color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height ?? 1.1,
      letterSpacing: -0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

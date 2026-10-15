import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for the type scale. See DESIGN.md §3.
///
/// Display and UI text use **Outfit**. Anything numeric (timers, scores,
/// points) uses **JetBrains Mono** via `context.mono(...)`.
///
/// Role           size / weight   typical use
/// displayLarge   48 / w700       hero numbers, splash wordmark
/// displayMedium  40 / w700
/// displaySmall   36 / w600
/// headlineLarge  32 / w600       login title
/// headlineMedium 28 / w600       page titles
/// headlineSmall  24 / w600       section headers
/// titleLarge     20 / w600       card titles
/// titleMedium    18 / w600       app bar & dialog titles
/// titleSmall     16 / w600       list item titles
/// bodyLarge      16 / w400       primary reading text
/// bodyMedium     14 / w400       default body
/// bodySmall      13 / w400       secondary body, captions (muted color)
/// labelLarge     14 / w600       buttons
/// labelMedium    12 / w600       chips, badges, nav labels
/// labelSmall     11 / w500       overlines, timestamps (muted color)
abstract final class AppTypography {
  static TextTheme textTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
  }) {
    final base = GoogleFonts.outfitTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    TextStyle? style(
      TextStyle? source,
      double size,
      FontWeight weight, {
      double height = 1.3,
      double letterSpacing = 0,
      Color? color,
    }) {
      return source?.copyWith(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? primary,
      );
    }

    return base.copyWith(
      displayLarge: style(base.displayLarge, 48, FontWeight.w700,
          height: 1.05, letterSpacing: -1.2),
      displayMedium: style(base.displayMedium, 40, FontWeight.w700,
          height: 1.1, letterSpacing: -1.0),
      displaySmall: style(base.displaySmall, 36, FontWeight.w600,
          height: 1.12, letterSpacing: -0.8),
      headlineLarge: style(base.headlineLarge, 32, FontWeight.w600,
          height: 1.15, letterSpacing: -0.6),
      headlineMedium: style(base.headlineMedium, 28, FontWeight.w600,
          height: 1.2, letterSpacing: -0.5),
      headlineSmall: style(base.headlineSmall, 24, FontWeight.w600,
          height: 1.25, letterSpacing: -0.4),
      titleLarge: style(base.titleLarge, 20, FontWeight.w600,
          letterSpacing: -0.3),
      titleMedium: style(base.titleMedium, 18, FontWeight.w600,
          letterSpacing: -0.2),
      titleSmall: style(base.titleSmall, 16, FontWeight.w600, height: 1.35),
      bodyLarge: style(base.bodyLarge, 16, FontWeight.w400, height: 1.5),
      bodyMedium: style(base.bodyMedium, 14, FontWeight.w400, height: 1.5),
      bodySmall: style(base.bodySmall, 13, FontWeight.w400,
          height: 1.45, color: secondary),
      labelLarge: style(base.labelLarge, 14, FontWeight.w600,
          height: 1.2, letterSpacing: 0.1),
      labelMedium: style(base.labelMedium, 12, FontWeight.w600,
          height: 1.2, letterSpacing: 0.2),
      labelSmall: style(base.labelSmall, 11, FontWeight.w500,
          height: 1.2, letterSpacing: 0.4, color: secondary),
    );
  }
}

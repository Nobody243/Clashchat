import 'package:flutter/material.dart';

/// Brand and seed constants. See DESIGN.md.
///
/// Anything that changes with the theme (text, surfaces, borders, pills) lives
/// in [AppColorsExt] and is read via `context.colors`. Constants here are for
/// values that are the same in both themes (rank colors, brand seeds) and for
/// seeding the dark/light extension values.
abstract final class AppColors {
  // ──── Brand ────
  /// The one accent. Trophies, CTAs (dark), active states.
  static const Color brass = Color(0xFFD4A84B);
  /// Brass darkened for text/icons on light surfaces (passes 4.5:1 on white).
  static const Color brassDeep = Color(0xFF9A7520);
  static const Color brassLight = Color(0xFFE2BE6B);
  /// Warm near-black used for primary buttons in light mode.
  static const Color ink = Color(0xFF1A1719);
  /// Warm paper used for light canvas and text on ink.
  static const Color paper = Color(0xFFF6F4F0);

  // ──── Semantic hues (dark-theme strength) ────
  static const Color sage = Color(0xFF6FC29B); // for / success / easy
  static const Color terracotta = Color(0xFFED8B72); // against / error / hard
  static const Color amber = Color(0xFFE2B45C); // warning / medium / points
  static const Color sky = Color(0xFF86B0E3); // info / learning

  // ──── Dark neutrals ("Arena Night") ────
  static const Color canvasDark = Color(0xFF121113);
  static const Color surfaceDark = Color(0xFF1A181B);
  static const Color surfaceRaisedDark = Color(0xFF232025);
  static const Color insetDark = Color(0xFF0D0C0E);

  // ──── Light neutrals ("Arena Day") ────
  static const Color canvasLight = Color(0xFFF6F4F0);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color insetLight = Color(0xFFEDE9E2);

  // ──── Rank colors (same in both themes) ────
  static const Color rankNewcomer = Color(0xFF8E8A85); // stone
  static const Color rankChallenger = Color(0xFFB5793F); // bronze
  static const Color rankDebater = Color(0xFFA9B0BA); // silver
  static const Color rankOrator = Color(0xFFD4A84B); // brass
  static const Color rankGrandmaster = Color(0xFFCFE3F0); // ice

  // ──── Legacy aliases ────
  // Kept so existing call sites compile while screens are restyled. New code
  // must use `context.colors.*`. These will be removed.
  static const Color primary = brass;
  static const Color primaryLight = brassLight;
  static const Color secondary = sky;
  static const Color gold = brass;
  static const Color success = sage;
  static const Color successAlt = sage;
  static const Color warning = amber;
  static const Color error = terracotta;
  static const Color errorAlt = terracotta;
  static const Color background = canvasDark;
  static const Color surface = surfaceDark;
  static const Color surfaceDeep = surfaceRaisedDark;
  static const Color backgroundLight = canvasLight;
  static const Color surfaceDeepLight = insetLight;
  static const Color accentGreen = sage;
  static const Color accentRed = terracotta;
  static const Color accentAmber = amber;
}

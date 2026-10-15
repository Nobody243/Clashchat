import 'package:flutter/material.dart';

/// Brand and seed constants. See DESIGN.md §2.
///
/// Anything that changes with the theme (text, surfaces, borders, pills) lives
/// in [AppColorsExt] and is read via `context.colors`. Constants here are for
/// values that are the same in both themes (rank colors, brand seeds) and for
/// seeding the dark/light extension values.
abstract final class AppColors {
  // ──── Brand ────
  /// The one accent: a luminous gold. CTAs (dark), active states, trophies.
  static const Color gold = Color(0xFFF0B94B);
  /// Gold darkened for text/icons on light surfaces (passes 4.5:1 on white).
  static const Color goldDeep = Color(0xFFB47F1E);
  static const Color goldLight = Color(0xFFF7CF7A);
  /// Ink: a deep violet-black. Primary buttons in light mode, light-mode text.
  static const Color ink = Color(0xFF171320);
  /// Warm paper used for the light canvas and text on ink.
  static const Color paper = Color(0xFFF7F4EE);

  // ──── Semantic hues (dark-theme strength) ────
  static const Color sage = Color(0xFF5BD29B); // for / success / easy
  static const Color ember = Color(0xFFFF8A6A); // against / error / hard
  static const Color amber = Color(0xFFF5C76A); // warning / medium / points
  static const Color sky = Color(0xFF7FB4FF); // info / learning
  /// Ambience only (backdrop lights), never for UI chrome.
  static const Color violet = Color(0xFF7C5CFF);

  // ──── Dark neutrals ("Arena Night": violet-black with real steps) ────
  static const Color canvasDark = Color(0xFF0D0B12);
  static const Color surfaceDark = Color(0xFF17141D);
  static const Color surfaceRaisedDark = Color(0xFF211D2A);
  static const Color insetDark = Color(0xFF07060A);

  // ──── Light neutrals ("Arena Day") ────
  static const Color canvasLight = Color(0xFFF7F4EE);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color insetLight = Color(0xFFECE7DE);

  // ──── Rank colors (same in both themes) ────
  static const Color rankNewcomer = Color(0xFF9A958F); // stone
  static const Color rankChallenger = Color(0xFFC98A4B); // bronze
  static const Color rankDebater = Color(0xFFB9C2CC); // silver
  static const Color rankOrator = Color(0xFFF0B94B); // gold
  static const Color rankGrandmaster = Color(0xFFD7ECFA); // ice

  // ──── Legacy aliases ────
  // Kept so existing call sites compile. New code must use `context.colors.*`.
  static const Color brass = gold;
  static const Color brassDeep = goldDeep;
  static const Color brassLight = goldLight;
  static const Color terracotta = ember;
  static const Color primary = gold;
  static const Color primaryLight = goldLight;
  static const Color secondary = sky;
  static const Color success = sage;
  static const Color successAlt = sage;
  static const Color warning = amber;
  static const Color error = ember;
  static const Color errorAlt = ember;
  static const Color background = canvasDark;
  static const Color surface = surfaceDark;
  static const Color surfaceDeep = surfaceRaisedDark;
  static const Color backgroundLight = canvasLight;
  static const Color surfaceDeepLight = insetLight;
  static const Color accentGreen = sage;
  static const Color accentRed = ember;
  static const Color accentAmber = amber;
}

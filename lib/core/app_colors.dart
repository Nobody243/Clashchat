import 'package:flutter/material.dart';

/// Brand and seed constants. See DESIGN.md §2.
///
/// Anything that changes with the theme (text, surfaces, borders, pills) lives
/// in [AppColorsExt] and is read via `context.colors`. Constants here are for
/// values that are the same in both themes (rank colors, brand seeds) and for
/// seeding the dark/light extension values.
abstract final class AppColors {
  // ──── Brand ────
  /// The one accent: a vermilion flame. Used for the 5 %: primary action,
  /// the live/selected state, progress, "Chat" in the wordmark.
  static const Color flame = Color(0xFFFF5A3C);
  /// Flame darkened for text/icons on paper (5.4:1 on white).
  static const Color flameDeep = Color(0xFFC93217);
  /// Ink: the near-black of the system. Light-mode text and buttons.
  static const Color ink = Color(0xFF141317);
  /// Paper: the light canvas and text on ink.
  static const Color paper = Color(0xFFF7F5F0);
  /// Gold is reserved for rank and prestige, never for actions.
  static const Color gold = Color(0xFFD9A441);
  static const Color goldDeep = Color(0xFF8A6A1C);
  static const Color goldLight = Color(0xFFE8BF66);

  // ──── Semantic hues (dark-theme strength) ────
  static const Color sage = Color(0xFF4ED39A); // for / success / easy
  static const Color ember = Color(0xFFFF7B6B); // against / error / hard
  static const Color amber = Color(0xFFE0B35C); // warning / medium
  static const Color sky = Color(0xFF6FB1FF); // info / learning
  /// Ambience only (backdrop light), never for UI chrome.
  static const Color violet = Color(0xFF6FB1FF);

  // ──── Dark neutrals ("Ink": true neutral, slight cool bias) ────
  static const Color canvasDark = Color(0xFF0E0E10);
  static const Color surfaceDark = Color(0xFF161618);
  static const Color surfaceRaisedDark = Color(0xFF1E1E21);
  static const Color insetDark = Color(0xFF09090A);

  // ──── Light neutrals ("Paper") ────
  static const Color canvasLight = Color(0xFFF7F5F0);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color insetLight = Color(0xFFECE9E2);

  // ──── Rank colors (same in both themes) ────
  static const Color rankNewcomer = Color(0xFF9A9794); // stone
  static const Color rankChallenger = Color(0xFFC08552); // bronze
  static const Color rankDebater = Color(0xFFB7BEC7); // silver
  static const Color rankOrator = Color(0xFFD9A441); // gold
  static const Color rankGrandmaster = Color(0xFFDCE9F5); // platinum

  // ──── Legacy aliases ────
  // Kept so existing call sites compile. New code must use `context.colors.*`.
  static const Color brass = gold;
  static const Color brassDeep = goldDeep;
  static const Color brassLight = goldLight;
  static const Color terracotta = ember;
  static const Color primary = flame;
  static const Color primaryLight = ember;
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

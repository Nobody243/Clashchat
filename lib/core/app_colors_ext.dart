import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Theme-aware semantic colors. See DESIGN.md §2.
///
/// Read via `context.colors.textPrimary` etc. Widgets never branch on
/// brightness themselves; the right value is picked once, in the theme.
@immutable
class AppColorsExt extends ThemeExtension<AppColorsExt> {
  const AppColorsExt({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.inset,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.borderStrong,
    required this.shadow,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.ctaBg,
    required this.ctaFg,
    required this.positiveBg,
    required this.positiveText,
    required this.negativeBg,
    required this.negativeText,
    required this.warningBg,
    required this.warningText,
    required this.infoBg,
    required this.infoText,
    required this.rankBg,
    required this.rankText,
  });

  // Surfaces
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color inset;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  // Lines & depth
  final Color border;
  final Color borderStrong;
  final Color shadow;

  // Accent (brass)
  final Color accent;
  final Color onAccent;
  final Color accentSoft;

  // Primary call-to-action fill/foreground (brass in dark, ink in light)
  final Color ctaBg;
  final Color ctaFg;

  // Semantic pairs
  final Color positiveBg;
  final Color positiveText;
  final Color negativeBg;
  final Color negativeText;
  final Color warningBg;
  final Color warningText;
  final Color infoBg;
  final Color infoText;
  final Color rankBg;
  final Color rankText;

  // ── Aliases (kept for existing call sites) ──
  Color get surfaceDeep => surfaceRaised;
  Color get easyBg => positiveBg;
  Color get easyText => positiveText;
  Color get mediumBg => warningBg;
  Color get mediumText => warningText;
  Color get hardBg => negativeBg;
  Color get hardText => negativeText;
  Color get rankedTabBg => rankBg;
  Color get rankedTabText => rankText;
  Color get casualTabBg => positiveBg;
  Color get casualTabText => positiveText;
  Color get learningBg => infoBg;
  Color get learningText => infoText;
  Color get forBg => positiveBg;
  Color get forText => positiveText;
  Color get againstBg => negativeBg;
  Color get againstText => negativeText;

  static const AppColorsExt dark = AppColorsExt(
    background: AppColors.canvasDark,
    surface: AppColors.surfaceDark,
    surfaceRaised: AppColors.surfaceRaisedDark,
    inset: AppColors.insetDark,
    textPrimary: Color(0xFFF5F1EA),
    textSecondary: Color(0xFFB8B1AA),
    textHint: Color(0xFF857E88),
    border: Color(0xFF2C2736),
    borderStrong: Color(0xFF3E3749),
    shadow: Color(0x80000000),
    accent: AppColors.gold,
    onAccent: Color(0xFF1C1406),
    accentSoft: Color(0x29F0B94B),
    ctaBg: AppColors.gold,
    ctaFg: Color(0xFF1C1406),
    positiveBg: Color(0xFF123A2E),
    positiveText: AppColors.sage,
    negativeBg: Color(0xFF432119),
    negativeText: AppColors.ember,
    warningBg: Color(0xFF3F2E10),
    warningText: AppColors.amber,
    infoBg: Color(0xFF172A47),
    infoText: AppColors.sky,
    rankBg: Color(0xFF352A12),
    rankText: Color(0xFFF5CE7A),
  );

  static const AppColorsExt light = AppColorsExt(
    background: AppColors.canvasLight,
    surface: AppColors.surfaceLight,
    surfaceRaised: AppColors.surfaceLight,
    inset: AppColors.insetLight,
    textPrimary: AppColors.ink,
    textSecondary: Color(0xFF5B5566),
    textHint: Color(0xFF7A7484),
    border: Color(0xFFE3DDD2),
    borderStrong: Color(0xFFCFC7BA),
    shadow: Color(0x1A171320),
    accent: AppColors.goldDeep,
    onAccent: Colors.white,
    accentSoft: Color(0x24B47F1E),
    ctaBg: AppColors.ink,
    ctaFg: AppColors.paper,
    positiveBg: Color(0xFFDDF3E8),
    positiveText: Color(0xFF1F7A55),
    negativeBg: Color(0xFFFBE3DD),
    negativeText: Color(0xFFB8442B),
    warningBg: Color(0xFFFBEFD5),
    warningText: Color(0xFF946011),
    infoBg: Color(0xFFE1EAF9),
    infoText: Color(0xFF2F62B5),
    rankBg: Color(0xFFF7EAC9),
    rankText: Color(0xFF7A5A10),
  );

  @override
  AppColorsExt copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? inset,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? border,
    Color? borderStrong,
    Color? shadow,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? ctaBg,
    Color? ctaFg,
    Color? positiveBg,
    Color? positiveText,
    Color? negativeBg,
    Color? negativeText,
    Color? warningBg,
    Color? warningText,
    Color? infoBg,
    Color? infoText,
    Color? rankBg,
    Color? rankText,
  }) {
    return AppColorsExt(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      inset: inset ?? this.inset,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      shadow: shadow ?? this.shadow,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      ctaBg: ctaBg ?? this.ctaBg,
      ctaFg: ctaFg ?? this.ctaFg,
      positiveBg: positiveBg ?? this.positiveBg,
      positiveText: positiveText ?? this.positiveText,
      negativeBg: negativeBg ?? this.negativeBg,
      negativeText: negativeText ?? this.negativeText,
      warningBg: warningBg ?? this.warningBg,
      warningText: warningText ?? this.warningText,
      infoBg: infoBg ?? this.infoBg,
      infoText: infoText ?? this.infoText,
      rankBg: rankBg ?? this.rankBg,
      rankText: rankText ?? this.rankText,
    );
  }

  @override
  AppColorsExt lerp(ThemeExtension<AppColorsExt>? other, double t) {
    if (other is! AppColorsExt) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorsExt(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      inset: l(inset, other.inset),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textHint: l(textHint, other.textHint),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      shadow: l(shadow, other.shadow),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentSoft: l(accentSoft, other.accentSoft),
      ctaBg: l(ctaBg, other.ctaBg),
      ctaFg: l(ctaFg, other.ctaFg),
      positiveBg: l(positiveBg, other.positiveBg),
      positiveText: l(positiveText, other.positiveText),
      negativeBg: l(negativeBg, other.negativeBg),
      negativeText: l(negativeText, other.negativeText),
      warningBg: l(warningBg, other.warningBg),
      warningText: l(warningText, other.warningText),
      infoBg: l(infoBg, other.infoBg),
      infoText: l(infoText, other.infoText),
      rankBg: l(rankBg, other.rankBg),
      rankText: l(rankText, other.rankText),
    );
  }
}

/// Convenience accessors so widgets never branch on `isDark` themselves.
///
/// ```dart
/// Text('Hi', style: context.text.titleMedium?.copyWith(color: context.colors.textSecondary));
/// Text('42', style: context.mono(size: 32));
/// ```
extension AppThemeContext on BuildContext {
  AppColorsExt get colors =>
      Theme.of(this).extension<AppColorsExt>() ?? AppColorsExt.dark;

  TextTheme get text => Theme.of(this).textTheme;

  ColorScheme get scheme => Theme.of(this).colorScheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Whether motion should be minimised (system accessibility setting).
  bool get reduceMotion => MediaQuery.maybeOf(this)?.disableAnimations ?? false;

  /// Monospace numeric style (JetBrains Mono) for timers, scores and points.
  TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
  }) {
    return AppTypography.mono(
      size: size,
      weight: weight,
      color: color ?? colors.textPrimary,
      height: height,
    );
  }
}

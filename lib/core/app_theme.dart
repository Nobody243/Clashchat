import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_colors_ext.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData]. See DESIGN.md.
///
/// Semantic colors live in [AppColorsExt]; the type scale in [AppTypography].
/// Widgets read both through `context.colors` / `context.text` and never
/// branch on brightness themselves.
abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, AppColorsExt.dark);

  static ThemeData light() => _build(Brightness.light, AppColorsExt.light);

  static ThemeData _build(Brightness brightness, AppColorsExt c) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brass,
      brightness: brightness,
    ).copyWith(
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.accent,
      secondary: c.infoText,
      onSecondary: Colors.white,
      tertiary: c.positiveText,
      surface: c.surface,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerHighest: c.surfaceRaised,
      surfaceContainerLow: c.inset,
      error: c.negativeText,
      onError: Colors.white,
      errorContainer: c.negativeBg,
      onErrorContainer: c.negativeText,
      outline: c.border,
      outlineVariant: c.borderStrong,
      shadow: c.shadow,
    );

    final textTheme = AppTypography.textTheme(
      brightness: brightness,
      primary: c.textPrimary,
      secondary: c.textSecondary,
    );

    final RoundedRectangleBorder mdShape =
        RoundedRectangleBorder(borderRadius: AppRadius.mdAll);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[c],
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: c.textPrimary, size: 22),
      dividerColor: c.border,
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      splashFactory: InkSparkle.splashFactory,
      splashColor: c.accentSoft,
      highlightColor: Colors.transparent,
      hoverColor: c.accentSoft,
      focusColor: c.accentSoft,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: c.textPrimary, size: 22),
        titleTextStyle: textTheme.titleMedium,
        toolbarHeight: 60,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: c.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.accentSoft,
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected)
                ? c.textPrimary
                : c.textHint,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? c.accent
                : c.textHint,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? c.surfaceRaised : c.inset,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: textTheme.bodyMedium?.copyWith(color: c.textHint),
        helperStyle: textTheme.labelSmall,
        errorStyle: textTheme.labelSmall?.copyWith(color: c.negativeText),
        prefixIconColor: c.textHint,
        suffixIconColor: c.textHint,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: c.negativeText),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: c.negativeText, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.ctaBg,
          foregroundColor: c.ctaFg,
          disabledBackgroundColor: c.surfaceRaised,
          disabledForegroundColor: c.textHint,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          shape: mdShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.ctaBg,
          foregroundColor: c.ctaFg,
          disabledBackgroundColor: c.surfaceRaised,
          disabledForegroundColor: c.textHint,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          shape: mdShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          backgroundColor: c.surface,
          minimumSize: const Size.fromHeight(52),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: c.borderStrong),
          shape: mdShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: textTheme.labelLarge,
          shape: mdShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: const Size(44, 44),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.ctaBg,
        foregroundColor: c.ctaFg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceRaised,
        selectedColor: c.accentSoft,
        side: BorderSide(color: c.border),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAccent : c.textHint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceRaised,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.borderStrong,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.accent,
        inactiveTrackColor: c.inset,
        thumbColor: c.accent,
        overlayColor: c.accentSoft,
        trackHeight: 4,
        valueIndicatorColor: c.surfaceRaised,
        valueIndicatorTextStyle: textTheme.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.inset,
        circularTrackColor: c.inset,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: c.textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: c.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: c.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? c.surfaceRaised : AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? c.textPrimary : AppColors.paper,
        ),
        actionTextColor: isDark ? c.accent : AppColors.brassLight,
        shape: mdShape,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? c.surfaceRaised : AppColors.ink,
          borderRadius: AppRadius.smAll,
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: isDark ? c.textPrimary : AppColors.paper,
        ),
      ),
    );
  }
}

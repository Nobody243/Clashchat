import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';
import '../core/app_spacing.dart';
import 'pressable.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { regular, small }

/// The app's only button. See DESIGN.md §4.
///
/// * [AppButtonVariant.primary]   CTA fill (brass in dark, ink in light)
/// * [AppButtonVariant.secondary] surface with strong hairline
/// * [AppButtonVariant.ghost]     text only
/// * [AppButtonVariant.danger]    terracotta on terracotta-soft
///
/// Full-width by default; pass `expand: false` to hug content.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.loading = false,
    this.expand = true,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.regular,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.regular,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.regular,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.size = AppButtonSize.regular,
    this.loading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading;
  final bool expand;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = size == AppButtonSize.regular ? 52.0 : 40.0;
    final hPad = size == AppButtonSize.regular ? AppSpacing.xxl : AppSpacing.lg;
    final iconSize = size == AppButtonSize.regular ? 20.0 : 18.0;

    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      AppButtonVariant.primary => (c.ctaBg, c.ctaFg, BorderSide.none),
      AppButtonVariant.secondary => (
          c.surface,
          c.textPrimary,
          BorderSide(color: c.borderStrong)
        ),
      AppButtonVariant.ghost => (Colors.transparent, c.accent, BorderSide.none),
      AppButtonVariant.danger => (c.negativeBg, c.negativeText, BorderSide.none),
    };

    final effectiveBg = _enabled || loading
        ? bg
        : (variant == AppButtonVariant.ghost ? Colors.transparent : c.surfaceRaised);
    final effectiveFg = _enabled || loading ? fg : c.textHint;

    final labelStyle = context.text.labelLarge?.copyWith(color: effectiveFg);

    Widget content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: effectiveFg,
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: effectiveFg),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              label,
              style: labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(trailingIcon, size: iconSize, color: effectiveFg),
          ],
        ],
      ],
    );

    return Pressable(
      onTap: _enabled ? onPressed : null,
      enabled: _enabled,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        height: height,
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: AppRadius.mdAll,
          border: side == BorderSide.none ? null : Border.fromBorderSide(side),
        ),
        child: content,
      ),
    );
  }
}

/// 44 px square icon button with a subtle raised fill.
///
/// `filled: true` always shows the fill; otherwise the fill is transparent and
/// only the icon is visible (use on app bars).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.filled = false,
    this.color,
    this.size = 44,
    this.iconSize = 20,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool filled;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    final fg = color ?? (enabled ? c.textPrimary : c.textHint);

    Widget button = Pressable(
      onTap: onPressed,
      enabled: enabled,
      pressedScale: 0.92,
      semanticLabel: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? c.surfaceRaised : Colors.transparent,
          shape: BoxShape.circle,
          border: filled ? Border.all(color: c.border) : null,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: iconSize, color: fg),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

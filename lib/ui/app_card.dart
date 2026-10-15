import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';
import '../core/app_spacing.dart';
import 'app_icons.dart';
import 'pressable.dart';

enum AppCardLevel { flat, raised }

/// Surface container. See DESIGN.md §4.
///
/// Elevation is expressed by surface step ([AppCardLevel]) and a 1 px
/// hairline. Light mode adds a soft warm shadow. Pass [onTap] to make it
/// interactive: it gets press feedback and haptics on touch, and a gentle
/// lift with a brighter hairline under a mouse.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.level = AppCardLevel.flat,
    this.radius,
    this.color,
    this.borderColor,
    this.showBorder = true,
    this.clip = false,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final AppCardLevel level;
  final BorderRadius? radius;
  final Color? color;
  final Color? borderColor;
  final bool showBorder;
  final bool clip;
  /// Draws the hairline in accent (1.5 px) to mark a chosen option.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = radius ?? AppRadius.lgAll;
    final bg = color ??
        (level == AppCardLevel.raised ? c.surfaceRaised : c.surface);
    final interactive = onTap != null || onLongPress != null;

    Widget buildCard(bool hovered) {
      final border = selected
          ? Border.all(color: c.accent, width: 1.5)
          : showBorder
              ? Border.all(color: hovered ? c.borderStrong : (borderColor ?? c.border))
              : null;
      return AnimatedContainer(
        duration: AppDurations.fast,
        curve: Curves.easeOutCubic,
        margin: margin,
        padding: padding,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        transform: hovered && !context.reduceMotion
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: bg,
          // Top-light: a few percent brighter at the top edge gives the
          // surface a lit, dimensional feel without a visible gradient.
          gradient: context.isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(bg, Colors.white, 0.055)!, bg],
                  stops: const [0.0, 0.55],
                )
              : null,
          borderRadius: r,
          border: border,
          boxShadow: context.isDark
              ? (hovered
                  ? [BoxShadow(color: c.shadow, blurRadius: 24, offset: const Offset(0, 10))]
                  : null)
              : [
                  BoxShadow(
                    color: c.shadow,
                    blurRadius: hovered ? 28 : 20,
                    offset: Offset(0, hovered ? 10 : 6),
                  ),
                ],
        ),
        child: child,
      );
    }

    if (!interactive) return buildCard(false);

    return Pressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: HoverBuilder(builder: (context, hovered) => buildCard(hovered)),
    );
  }
}

/// A group of rows separated by hairlines inside one surface.
///
/// Prefer this over one card per item for lists (DESIGN.md §5).
class AppListGroup extends StatelessWidget {
  const AppListGroup({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.level = AppCardLevel.flat,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final AppCardLevel level;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: padding,
      level: level,
      clip: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, thickness: 1, color: c.border),
          ],
        ],
      ),
    );
  }
}

/// A tappable row for [AppListGroup]: leading tile, title, optional
/// subtitle, trailing widget or chevron. Hover tint on pointer devices,
/// press scale + haptic on touch.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final EdgeInsetsGeometry padding;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget row(bool hovered) => AnimatedContainer(
          duration: AppDurations.fast,
          color: hovered ? c.accent.withValues(alpha: 0.06) : Colors.transparent,
          padding: padding,
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AppSpacing.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.text.titleSmall?.copyWith(color: titleColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(subtitle!, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: AppSpacing.md), trailing!],
              if (trailing == null && showChevron && onTap != null) ...[
                const SizedBox(width: AppSpacing.md),
                Icon(AppIcons.forward, size: 20, color: c.textHint),
              ],
            ],
          ),
        );

    if (onTap == null) return row(false);
    return Pressable(
      onTap: onTap,
      pressedScale: 0.99,
      semanticLabel: title,
      child: HoverBuilder(builder: (context, hovered) => row(hovered)),
    );
  }
}

/// Small square tile that holds an icon, used as a leading element in rows
/// and mode cards.
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    this.color,
    this.background,
    this.size = 44,
    this.iconSize = 22,
    this.radius,
  });

  final IconData icon;
  final Color? color;
  final Color? background;
  final double size;
  final double iconSize;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = color ?? c.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? c.accentSoft,
        borderRadius: radius ?? AppRadius.mdAll,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: fg),
    );
  }
}

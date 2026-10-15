import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';
import '../core/app_spacing.dart';
import 'pressable.dart';

enum AppCardLevel { flat, raised }

/// Surface container. See DESIGN.md §4.
///
/// Elevation is expressed by surface step ([AppCardLevel]) and a 1 px hairline,
/// not by shadow. Light mode adds a soft warm shadow. Pass [onTap] to make it
/// interactive (gets press feedback automatically).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.margin,
    this.onTap,
    this.level = AppCardLevel.flat,
    this.radius,
    this.color,
    this.borderColor,
    this.showBorder = true,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final AppCardLevel level;
  final BorderRadius? radius;
  final Color? color;
  final Color? borderColor;
  final bool showBorder;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = radius ?? AppRadius.lgAll;
    final bg = color ?? (level == AppCardLevel.raised ? c.surfaceRaised : c.surface);

    Widget card = Container(
      margin: margin,
      padding: padding,
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: r,
        border: showBorder ? Border.all(color: borderColor ?? c.border) : null,
        boxShadow: context.isDark
            ? null
            : [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Pressable(onTap: onTap, child: card);
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

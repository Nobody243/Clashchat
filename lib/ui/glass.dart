import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';
import '../core/app_spacing.dart';

/// Frosted surface: blurred backdrop, translucent fill, hairline and a 1 px
/// top highlight. Use sparingly: app bars that float over content, the login
/// card on desktop, overlays. See DESIGN.md §9.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.radius,
    this.blur = 18,
    this.opacity,
    this.border = true,
    this.highlight = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? radius;
  final double blur;
  /// Fill opacity; defaults to 0.72 dark / 0.80 light.
  final double? opacity;
  final bool border;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = radius ?? AppRadius.lgAll;
    final o = opacity ?? (context.isDark ? 0.72 : 0.80);

    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Stack(
          children: [
            Container(
              padding: padding,
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: o),
                borderRadius: r,
                border: border ? Border.all(color: c.border) : null,
              ),
              child: child,
            ),
            if (highlight)
              Positioned(
                left: 12,
                right: 12,
                top: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0),
                          Colors.white.withValues(alpha: context.isDark ? 0.10 : 0.6),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-width glass bar for headers that sit over scrolling content.
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.gutter,
      vertical: AppSpacing.md,
    ),
    this.bottomBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool bottomBorder;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: c.background.withValues(alpha: context.isDark ? 0.72 : 0.82),
            border: bottomBorder
                ? Border(bottom: BorderSide(color: c.border))
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

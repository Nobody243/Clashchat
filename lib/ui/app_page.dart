import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';
import '../core/app_spacing.dart';
import 'app_backdrop.dart';

/// Content width classes. See DESIGN.md §9 (Layout).
enum AppPageWidth {
  /// Forms and single-column flows (login, setup steps): 560.
  form,
  /// Reading content (results, review, chat): 880.
  content,
  /// Dashboards and bento layouts (home, history, profile): 1180.
  wide,
}

extension AppPageWidthValue on AppPageWidth {
  double get maxWidth => switch (this) {
        AppPageWidth.form => 560,
        AppPageWidth.content => 880,
        AppPageWidth.wide => 1180,
      };
}

/// Breakpoints shared by every screen.
abstract final class AppBreakpoints {
  /// Phones.
  static const double compact = 600;
  /// Large phones / small tablets: navigation rail, two columns allowed.
  static const double medium = 900;
  /// Tablets landscape / small laptops: sidebar, bento layouts.
  static const double expanded = 1200;
}

extension AppWidthContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isCompact => screenWidth < AppBreakpoints.compact;
  bool get isMedium =>
      screenWidth >= AppBreakpoints.compact && screenWidth < AppBreakpoints.medium;
  bool get isExpanded =>
      screenWidth >= AppBreakpoints.medium && screenWidth < AppBreakpoints.expanded;
  bool get isLarge => screenWidth >= AppBreakpoints.expanded;
  /// Anything wider than a phone.
  bool get isWide => screenWidth >= AppBreakpoints.compact;

  /// Horizontal gutter that grows with the viewport.
  double get pageGutter => isCompact
      ? AppSpacing.gutter
      : isMedium
          ? AppSpacing.xxl
          : AppSpacing.huge;
}

/// Page scaffold body: atmospheric backdrop, safe area, centered max-width
/// column with responsive gutters. Put it in `Scaffold.body`.
///
/// ```dart
/// Scaffold(body: AppPage(width: AppPageWidth.wide, child: ...))
/// ```
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.width = AppPageWidth.content,
    this.scroll = true,
    this.backdrop = true,
    this.backdropIntensity = 1.0,
    this.lights = true,
    this.padding,
    this.topSafe = true,
    this.bottomSafe = true,
    this.alignment = Alignment.topCenter,
    this.controller,
  });

  final Widget child;
  final AppPageWidth width;
  /// Wrap the content in a vertical scroll view.
  final bool scroll;
  final bool backdrop;
  final double backdropIntensity;
  /// Pass false to keep the grain but freeze/skip the drifting lights.
  final bool lights;
  /// Defaults to responsive gutters and 24 px vertical.
  final EdgeInsets? padding;
  final bool topSafe;
  final bool bottomSafe;
  final Alignment alignment;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final gutter = context.pageGutter;
    final pad = padding ??
        EdgeInsets.fromLTRB(gutter, AppSpacing.xxl, gutter, AppSpacing.xxxl);

    Widget body = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width.maxWidth),
      child: Padding(padding: pad, child: child),
    );

    body = scroll
        ? SingleChildScrollView(
            controller: controller,
            child: Align(alignment: alignment, child: body),
          )
        : Align(alignment: alignment, child: body);

    body = SafeArea(top: topSafe, bottom: bottomSafe, child: body);

    if (!backdrop) {
      return ColoredBox(color: context.colors.background, child: body);
    }
    return AppBackdrop(intensity: backdropIntensity, lights: lights, child: body);
  }
}

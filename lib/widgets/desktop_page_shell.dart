import 'package:flutter/material.dart';

import '../core/responsive_layout.dart';
import '../ui/ui.dart';

/// Centers page content at [maxWidth] with generous padding on wide desktop
/// layouts; on narrower widths it returns [child] untouched so the caller's
/// own gutter applies (DESIGN.md §5).
class DesktopPageShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const DesktopPageShell({
    super.key,
    required this.child,
    this.maxWidth = 1200.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideDesktop =
        screenWidth >= ResponsiveLayout.wideDesktopBreakpoint;

    if (!isWideDesktop) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.huge,
            vertical: AppSpacing.xxxl,
          ),
          child: child,
        ),
      ),
    );
  }
}

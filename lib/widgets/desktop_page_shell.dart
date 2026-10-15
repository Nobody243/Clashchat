import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Centers page content at [maxWidth] with the responsive page gutter on
/// sidebar layouts (expanded and large, ≥ 900); on narrower widths it
/// returns [child] untouched so the caller's own gutter applies
/// (DESIGN.md §5, §9).
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
    if (context.isCompact || context.isMedium) return child;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.pageGutter,
            vertical: AppSpacing.xxxl,
          ),
          child: child,
        ),
      ),
    );
  }
}

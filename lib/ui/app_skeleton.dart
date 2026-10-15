import 'package:flutter/material.dart';

import '../core/app_colors_ext.dart';
import '../core/app_spacing.dart';

/// Shimmering placeholder block that matches the layout it stands in for.
/// See DESIGN.md §4 (Loaders). Honors reduce-motion (static block).
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius,
    this.circle = false,
  });

  const AppSkeleton.line({super.key, this.width, this.height = 14})
      : radius = null,
        circle = false;

  const AppSkeleton.circle({super.key, double size = 44})
      : width = size,
        height = size,
        radius = null,
        circle = true;

  const AppSkeleton.block({super.key, this.width, this.height = 80, this.radius})
      : circle = false;

  final double? width;
  final double height;
  final BorderRadius? radius;
  final bool circle;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = c.surfaceRaised;
    final highlight = c.border;
    final shape = widget.circle
        ? const BorderRadius.all(Radius.circular(999))
        : (widget.radius ?? AppRadius.smAll);

    if (context.reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: base, borderRadius: shape),
      );
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: shape,
            gradient: LinearGradient(
              begin: Alignment(-1.0 - 2 * (1 - t), 0),
              end: Alignment(1.0 + 2 * t, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ),
          ),
        );
      },
    );
  }
}

/// A ready-made skeleton for a list row: circle + two lines.
class AppSkeletonRow extends StatelessWidget {
  const AppSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          const AppSkeleton.circle(size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeleton.line(width: 160, height: 14),
                SizedBox(height: AppSpacing.sm),
                AppSkeleton.line(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

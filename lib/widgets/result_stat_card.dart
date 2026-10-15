import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Compact stat tile for the results grid: icon, mono value (or a custom
/// [child] such as a pill), label beneath.
///
/// [color] and [padding] are kept for source compatibility with existing call
/// sites; the icon colour is now driven by [color] (defaults to accent).
class ResultStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  /// Replaces the mono value (e.g. an [AppPill]).
  final Widget? child;

  const ResultStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.child,
    // ignore: avoid_unused_constructor_parameters
    int padding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color ?? c.textHint),
          const SizedBox(height: AppSpacing.sm),
          if (child != null)
            child!
          else
            Text(
              value,
              style: context.mono(size: 20),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: text.labelSmall?.copyWith(color: c.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

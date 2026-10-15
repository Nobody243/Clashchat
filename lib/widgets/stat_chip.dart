import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Compact stat: a small icon tile and a label on a raised surface.
class StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;

  const StatChip({
    super.key,
    required this.label,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ic = iconColor ?? c.accent;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconTile(
            icon: icon,
            color: ic,
            background: ic.withValues(alpha: 0.12),
            size: 24,
            iconSize: 14,
            radius: AppRadius.smAll,
          ),
          AppSpacing.hSm,
          Text(
            label,
            style: context.text.labelMedium?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

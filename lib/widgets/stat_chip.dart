import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Compact stat: a raised pill with a 24 px icon tile and a label.
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
      height: 36,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs + 2,
        0,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIconTile(
            icon: icon,
            color: ic,
            background: ic.withValues(alpha: 0.14),
            size: 24,
            iconSize: 14,
            radius: AppRadius.pillAll,
          ),
          AppSpacing.hSm,
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelMedium?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

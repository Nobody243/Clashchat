import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Compact stat tile for the results grid: icon, mono value (or a custom
/// [child] such as a pill), label beneath.
///
/// Pass [numericValue] to have the number count up on first appearance
/// ([AnimatedNumber]); [value] is then used only as the semantic fallback.
/// [color] and [padding] are kept for source compatibility with existing call
/// sites; the icon colour is driven by [color] (defaults to hint).
class ResultStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  /// Replaces the mono value (e.g. an [AppPill]).
  final Widget? child;

  /// When set, the value counts up to this number in the mono face.
  final num? numericValue;

  /// Appended to the animated number, e.g. ' min'.
  final String suffix;

  const ResultStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.child,
    this.numericValue,
    this.suffix = '',
    // ignore: avoid_unused_constructor_parameters
    int padding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    final Widget valueWidget;
    if (child != null) {
      valueWidget = child!;
    } else if (numericValue != null) {
      valueWidget = AnimatedNumber(
        value: numericValue!,
        size: 20,
        suffix: suffix,
        textAlign: TextAlign.center,
      );
    } else {
      valueWidget = Text(
        value,
        style: context.mono(size: 20),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconTile(
            icon: icon,
            size: 32,
            iconSize: 16,
            color: color ?? c.textSecondary,
            background: c.surfaceRaised,
            radius: AppRadius.smAll,
          ),
          const SizedBox(height: AppSpacing.md),
          valueWidget,
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

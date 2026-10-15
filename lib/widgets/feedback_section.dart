import 'package:flutter/material.dart';

import '../ui/ui.dart';

/// Section header plus a hairline-divided list of feedback points.
///
/// [color] tints the per-row icon (pass `context.colors.positiveText` /
/// `warningText`). [backgroundColor] is accepted for source compatibility and
/// ignored; rows always sit on the surface. When [points] is empty the section
/// renders a compact [AppEmptyState] if [emptyTitle] is given, otherwise
/// nothing.
class FeedbackSection extends StatelessWidget {
  final String title;
  final List<String> points;
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final String? emptyTitle;
  final String? emptyMessage;

  const FeedbackSection({
    super.key,
    required this.title,
    required this.points,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.emptyTitle,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    if (points.isEmpty && emptyTitle == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionHeader(title: title),
        if (points.isEmpty)
          AppCard(
            padding: EdgeInsets.zero,
            child: AppEmptyState(
              compact: true,
              icon: icon,
              title: emptyTitle!,
              message: emptyMessage,
            ),
          )
        else
          AppListGroup(
            children: [
              for (final p in points)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md + 2,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(icon, size: 18, color: color),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(p, style: text.bodyMedium)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

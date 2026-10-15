import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/debate_record.dart';
import '../ui/ui.dart';

/// One row of the history list. Lives inside an [AppListGroup]; it draws no
/// border or background of its own except the hover tint (pointer devices)
/// and the accent hairline when [selected] in a master–detail layout.
class HistoryDebateCard extends StatelessWidget {
  final DebateRecord record;
  final VoidCallback onTap;

  /// Marks the row shown in the detail pane (accent hairline + soft tint).
  final bool selected;

  /// Retained for source compatibility with existing call sites.
  final String? difficulty;
  final String? summary;
  final int? messageCount;

  const HistoryDebateCard({
    super.key,
    required this.record,
    required this.onTap,
    this.selected = false,
    this.difficulty,
    this.summary,
    this.messageCount,
  });

  /// Score band: 70+ positive, 40–69 warning, below 40 negative.
  static Color scoreColor(BuildContext context, int score) {
    final c = context.colors;
    if (score >= 70) return c.positiveText;
    if (score >= 40) return c.warningText;
    return c.negativeText;
  }

  String _formatDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(record.date.year, record.date.month, record.date.day);

    if (date == today) {
      return 'Today, ${DateFormat.jm().format(record.date)}';
    } else if (date == yesterday) {
      return 'Yesterday';
    }
    return DateFormat('MMM d').format(record.date);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final showPoints = record.isRanked && record.pointsEarned != 0;
    final pointsPositive = record.pointsEarned > 0;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.99,
      semanticLabel: record.topic,
      child: HoverBuilder(
        builder: (context, hovered) {
          final tint = selected
              ? c.accentSoft
              : c.accent.withValues(alpha: hovered ? 0.06 : 0);
          final hairline = c.accent.withValues(alpha: selected ? 1 : 0);
          return AnimatedContainer(
            duration: AppDurations.fast,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: tint,
              border: Border.all(color: hairline),
            ),
            child: Row(
              children: [
                ScoreRing(
                  value: record.score.toDouble(),
                  size: 44,
                  stroke: 4,
                  color: scoreColor(context, record.score),
                  animate: false,
                ),
                AppSpacing.hMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.topic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm - 2),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _formatDate(),
                            style: context.text.labelSmall?.copyWith(
                              color: c.textHint,
                            ),
                          ),
                          AppPill.stance(record.stance, withIcon: false),
                          AppPill.mode(record.mode, withIcon: false),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.hSm,
                if (showPoints) ...[
                  AppPill(
                    mono: true,
                    tone: pointsPositive
                        ? AppPillTone.positive
                        : AppPillTone.negative,
                    label:
                        '${pointsPositive ? '+' : ''}${record.pointsEarned}',
                  ),
                  AppSpacing.hSm,
                ],
                Icon(
                  AppIcons.forward,
                  size: 18,
                  color: selected ? c.accent : c.textHint,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

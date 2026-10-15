import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/debate_record.dart';
import '../ui/ui.dart';

/// One row of the history list. Lives inside an [AppListGroup]; it draws no
/// border or background of its own.
class HistoryDebateCard extends StatelessWidget {
  final DebateRecord record;
  final VoidCallback onTap;

  /// Retained for source compatibility with existing call sites.
  final String? difficulty;
  final String? summary;
  final int? messageCount;

  const HistoryDebateCard({
    super.key,
    required this.record,
    required this.onTap,
    this.difficulty,
    this.summary,
    this.messageCount,
  });

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
      semanticLabel: record.topic,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
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
            Icon(AppIcons.forward, size: 18, color: c.textHint),
          ],
        ),
      ),
    );
  }
}

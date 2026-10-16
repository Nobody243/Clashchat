import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/debate_mode.dart';
import '../models/debate_record.dart';
import '../ui/ui.dart';

/// One row of the history list.
///
/// Wide layouts: lives inside an [AppListGroup]; draws no border or
/// background of its own except the hover tint (pointer devices) and the
/// accent hairline when [selected] in a master–detail layout.
///
/// Phones ([compact] = true, DESIGN.md §10): an [AppPlainRow] led by the mono
/// score coloured by band, "Stance · Mode" underneath, the time on the right.
/// No ring, no pills, no chevron.
class HistoryDebateCard extends StatelessWidget {
  final DebateRecord record;
  final VoidCallback onTap;

  /// Marks the row shown in the detail pane (accent hairline + soft tint).
  final bool selected;

  /// Phone composition: plain hairline row instead of the ring + pills row.
  final bool compact;

  /// Retained for source compatibility with existing call sites.
  final String? difficulty;
  final String? summary;
  final int? messageCount;

  const HistoryDebateCard({
    super.key,
    required this.record,
    required this.onTap,
    this.selected = false,
    this.compact = false,
    this.difficulty,
    this.summary,
    this.messageCount,
  });

  /// Score band colour: 70+ positive, 40–69 warning, below 40 negative.
  static Color scoreColor(BuildContext context, int score) =>
      scoreBand(score).color(context);

  /// Display name of a mode, shared with the history tabs.
  static String modeLabel(DebateMode mode) => switch (mode) {
        DebateMode.ranked => 'Ranked',
        DebateMode.casual => 'Casual',
        DebateMode.learning => 'Learning',
      };

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
    if (compact) return _buildCompact(context);

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

  /// Phone row: mono score · topic / "Stance · Mode (+pts)" · time.
  Widget _buildCompact(BuildContext context) {
    final c = context.colors;
    final points = record.isRanked && record.pointsEarned > 0
        ? '  +${record.pointsEarned}'
        : '';
    return AppPlainRow(
      leading: ScoreNumber(record.score),
      title: record.topic,
      subtitle: '${record.stance} · ${modeLabel(record.mode)}$points',
      trailing: Text(
        DateFormat.jm().format(record.date),
        style: context.mono(size: 11, weight: FontWeight.w500, color: c.textHint),
      ),
      chevron: false,
      onTap: onTap,
    );
  }
}

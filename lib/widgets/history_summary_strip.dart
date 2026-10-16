import 'package:flutter/material.dart';

import '../models/debate_record.dart';
import '../ui/ui.dart';
import 'history_debate_card.dart';

/// Debates / Avg score / Wins. The numbers count up on first appearance; the
/// average takes the score band colour. Hidden when there are no records (the
/// list's empty state takes over).
///
/// Wide layouts: three stat tiles as one [Bento] row. Phones ([compact] =
/// true, DESIGN.md §10): a plain row of three numbers over small-caps
/// captions, no tiles.
class HistorySummaryStrip extends StatelessWidget {
  final List<DebateRecord> records;
  final bool compact;

  const HistorySummaryStrip({
    super.key,
    required this.records,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    final avg =
        (records.map((r) => r.score).reduce((a, b) => a + b) / records.length)
            .round();
    final wins = records.where((r) => r.score >= 70).length;
    final avgColor = HistoryDebateCard.scoreColor(context, avg);

    if (compact) {
      return Row(
        children: [
          Expanded(child: _Stat(label: 'Debates', value: records.length)),
          Expanded(child: _Stat(label: 'Avg score', value: avg, color: avgColor)),
          Expanded(child: _Stat(label: 'Wins', value: wins)),
        ],
      );
    }

    return Bento(
      gap: AppSpacing.md,
      // Three small tiles fit on any phone; only stack on very narrow panes.
      collapseBelow: 340,
      rows: [
        [
          BentoTile(
            child: _StatTile(
              icon: AppIcons.history,
              label: 'Debates',
              value: records.length,
            ),
          ),
          BentoTile(
            child: _StatTile(
              icon: AppIcons.score,
              label: 'Avg score',
              value: avg,
              color: avgColor,
            ),
          ),
          BentoTile(
            child: _StatTile(
              icon: AppIcons.ranked,
              label: 'Wins',
              value: wins,
            ),
          ),
        ],
      ],
    );
  }
}

/// Phone stat: 22 px mono number over a small-caps caption. No container.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedNumber(value: value, size: 22, color: color),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall?.copyWith(
            color: c.textHint,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: c.textHint),
              AppSpacing.hSm,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vSm,
          AnimatedNumber(value: value, size: 24, color: color),
        ],
      ),
    );
  }
}

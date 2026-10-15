import 'package:flutter/material.dart';

import '../models/debate_record.dart';
import '../ui/ui.dart';
import 'history_debate_card.dart';

/// Three stat tiles (Debates / Avg score / Wins) as one [Bento] row. The
/// numbers count up on first appearance; the average takes the score band
/// colour. Hidden when there are no records (the list's empty state takes
/// over).
class HistorySummaryStrip extends StatelessWidget {
  final List<DebateRecord> records;
  const HistorySummaryStrip({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();
    final avg =
        (records.map((r) => r.score).reduce((a, b) => a + b) / records.length)
            .round();
    final wins = records.where((r) => r.score >= 70).length;

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
              color: HistoryDebateCard.scoreColor(context, avg),
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
